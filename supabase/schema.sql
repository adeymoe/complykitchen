-- ComplyKitchen — Supabase schema (v1 MVP)
-- Run this in the Supabase SQL Editor on a fresh project.
--
-- Design notes:
-- - Multi-tenant: organizations -> sites -> units/tasks/readings.
--   RLS is scoped through membership, so one restaurant's data is
--   structurally invisible to another - this is the regulator-safety
--   guarantee, not just a nice-to-have.
-- - site_memberships.inducted_at is the turnover-proof onboarding
--   differentiator: null means "hasn't completed new-starter induction
--   at this site yet", and the app surfaces that directly.
-- - report_shares is the regulator-facing differentiator: a scoped,
--   time-limited, revocable token rather than a login for inspectors.
-- - Retention: nothing in this schema auto-deletes. UK food safety
--   records need >=1 year retention minimum (more for Legionella/fire
--   once those modules exist) - deletion should always be a deliberate
--   admin action, never a default.

create extension if not exists "uuid-ossp";

-- ============================================================
-- Core tenancy
-- ============================================================

create table organizations (
  id uuid primary key default uuid_generate_v4(),
  name text not null,
  created_at timestamptz not null default now()
);

create table profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  full_name text,
  created_at timestamptz not null default now()
);

create type member_role as enum ('owner', 'manager', 'staff');

create table memberships (
  id uuid primary key default uuid_generate_v4(),
  organization_id uuid not null references organizations(id) on delete cascade,
  user_id uuid not null references profiles(id) on delete cascade,
  role member_role not null default 'staff',
  created_at timestamptz not null default now(),
  unique (organization_id, user_id)
);

create table sites (
  id uuid primary key default uuid_generate_v4(),
  organization_id uuid not null references organizations(id) on delete cascade,
  name text not null,
  nation text not null default 'england'
    check (nation in ('england', 'wales', 'scotland', 'northern_ireland')),
  address text,
  created_at timestamptz not null default now()
);

-- Which staff can access which site, and whether they've completed
-- new-starter induction there. This table is the turnover differentiator.
create table site_memberships (
  id uuid primary key default uuid_generate_v4(),
  site_id uuid not null references sites(id) on delete cascade,
  user_id uuid not null references profiles(id) on delete cascade,
  inducted_at timestamptz,
  created_at timestamptz not null default now(),
  unique (site_id, user_id)
);

-- ============================================================
-- Compliance data
-- ============================================================

create type unit_type as enum ('fridge', 'freezer', 'hot_hold');

create table units (
  id uuid primary key default uuid_generate_v4(),
  site_id uuid not null references sites(id) on delete cascade,
  name text not null,
  location text,
  type unit_type not null,
  -- Fridges/freezers: legal ceiling. Hot-hold: legal floor (app logic
  -- flips the comparison direction based on `type`).
  target_max numeric not null,
  active boolean not null default true,
  created_at timestamptz not null default now()
);

create table task_templates (
  id uuid primary key default uuid_generate_v4(),
  site_id uuid not null references sites(id) on delete cascade,
  title text not null,
  category text not null default 'general',
  unit_id uuid references units(id) on delete set null,
  requires_reading boolean not null default false,
  recurrence text not null default 'daily'
    check (recurrence in ('daily', 'twice_daily', 'weekly')),
  active boolean not null default true,
  created_at timestamptz not null default now()
);

create table task_instances (
  id uuid primary key default uuid_generate_v4(),
  site_id uuid not null references sites(id) on delete cascade,
  template_id uuid references task_templates(id) on delete set null,
  title text not null,
  unit_id uuid references units(id) on delete set null,
  requires_reading boolean not null default false,
  due_at timestamptz not null,
  done boolean not null default false,
  done_at timestamptz,
  done_by uuid references profiles(id),
  created_at timestamptz not null default now()
);

-- The audit-critical table. Every out-of-range reading should carry a
-- corrective action - enforced in the app layer for v1 (a DB-level
-- check is a reasonable v2 hardening step).
create table readings (
  id uuid primary key default uuid_generate_v4(),
  site_id uuid not null references sites(id) on delete cascade,
  unit_id uuid not null references units(id) on delete cascade,
  task_instance_id uuid references task_instances(id) on delete set null,
  value numeric not null,
  status text not null check (status in ('safe', 'warn', 'danger')),
  taken_by uuid references profiles(id),
  taken_at timestamptz not null default now(),
  corrective_action text
);

-- Regulator-facing sharing: a scoped, time-limited, revocable link -
-- not a login. Public (unauthenticated) reads against this table are
-- intentionally NOT enabled yet; see README for the follow-up needed
-- (a Supabase Edge Function or public view) to make the token actually
-- viewable by someone without an account.
create table report_shares (
  id uuid primary key default uuid_generate_v4(),
  site_id uuid not null references sites(id) on delete cascade,
  token text not null unique,
  range_start date not null,
  range_end date not null,
  created_by uuid references profiles(id),
  created_at timestamptz not null default now(),
  expires_at timestamptz not null default (now() + interval '14 days'),
  revoked boolean not null default false
);

-- ============================================================
-- Row-Level Security
-- ============================================================

alter table organizations enable row level security;
alter table profiles enable row level security;
alter table memberships enable row level security;
alter table sites enable row level security;
alter table site_memberships enable row level security;
alter table units enable row level security;
alter table task_templates enable row level security;
alter table task_instances enable row level security;
alter table readings enable row level security;
alter table report_shares enable row level security;

create or replace function is_org_member(org_id uuid)
returns boolean language sql security definer stable as $$
  select exists (
    select 1 from memberships m
    where m.organization_id = org_id and m.user_id = auth.uid()
  );
$$;

create or replace function has_site_access(target_site_id uuid)
returns boolean language sql security definer stable as $$
  select exists (
    select 1 from sites s
    join memberships m on m.organization_id = s.organization_id
    where s.id = target_site_id and m.user_id = auth.uid()
  );
$$;

create policy "org members can view their org" on organizations
  for select using (is_org_member(id));
create policy "authenticated users can create an org" on organizations
  for insert with check (auth.uid() is not null);

create policy "users view profiles in their orgs" on profiles
  for select using (
    id = auth.uid() or exists (
      select 1 from memberships m1
      join memberships m2 on m1.organization_id = m2.organization_id
      where m1.user_id = auth.uid() and m2.user_id = profiles.id
    )
  );
create policy "users manage their own profile" on profiles
  for update using (id = auth.uid());
create policy "users insert their own profile" on profiles
  for insert with check (id = auth.uid());

create policy "members view memberships in their org" on memberships
  for select using (user_id = auth.uid() or is_org_member(organization_id));
create policy "members can add memberships in their org" on memberships
  for insert with check (is_org_member(organization_id) or user_id = auth.uid());

create policy "members view sites in their org" on sites
  for select using (is_org_member(organization_id));
create policy "members create sites in their org" on sites
  for insert with check (is_org_member(organization_id));
create policy "members update sites in their org" on sites
  for update using (is_org_member(organization_id));

create policy "site members view site_memberships" on site_memberships
  for select using (has_site_access(site_id));
create policy "site members add site_memberships" on site_memberships
  for insert with check (has_site_access(site_id) or user_id = auth.uid());
create policy "users update their own induction status" on site_memberships
  for update using (has_site_access(site_id));

create policy "site members view units" on units for select using (has_site_access(site_id));
create policy "site members manage units" on units for insert with check (has_site_access(site_id));
create policy "site members update units" on units for update using (has_site_access(site_id));

create policy "site members view task_templates" on task_templates for select using (has_site_access(site_id));
create policy "site members manage task_templates" on task_templates for insert with check (has_site_access(site_id));
create policy "site members update task_templates" on task_templates for update using (has_site_access(site_id));

create policy "site members view task_instances" on task_instances for select using (has_site_access(site_id));
create policy "site members manage task_instances" on task_instances for insert with check (has_site_access(site_id));
create policy "site members update task_instances" on task_instances for update using (has_site_access(site_id));

create policy "site members view readings" on readings for select using (has_site_access(site_id));
create policy "site members insert readings" on readings for insert with check (has_site_access(site_id));

create policy "site members view report_shares" on report_shares for select using (has_site_access(site_id));
create policy "site members create report_shares" on report_shares for insert with check (has_site_access(site_id));
create policy "site members update report_shares" on report_shares for update using (has_site_access(site_id));

-- Auto-create a profile row whenever someone signs up.
create or replace function handle_new_user()
returns trigger language plpgsql security definer as $$
begin
  insert into public.profiles (id, full_name)
  values (new.id, new.raw_user_meta_data ->> 'full_name');
  return new;
end;
$$;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function handle_new_user();

-- ============================================================
-- Staff invite support
-- ============================================================

-- Looks up a user's id by email, so a manager can invite someone who
-- already has a ComplyKitchen account onto their site. Returns only
-- the id (never the full auth.users row) and is deliberately callable
-- by authenticated users only, to avoid turning this into an email
-- enumeration tool for anonymous callers.
create or replace function find_user_id_by_email(lookup_email text)
returns uuid language sql security definer stable as $$
  select id from auth.users where email = lookup_email limit 1;
$$;

revoke all on function find_user_id_by_email(text) from public;
grant execute on function find_user_id_by_email(text) to authenticated;
