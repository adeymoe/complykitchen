# ComplyKitchen

Food safety compliance for UK restaurants. Staff log temperature checks and daily safety tasks from their phones, managers see compliance at a glance, and inspectors can be sent a secure, time-limited report link.

Built with **Flutter** and **Supabase**.

---

## Features

- **Multi-tenant accounts.** Anyone can sign up and create their own organisation and first site, with no admin provisioning.
- **Daily checklists.** Task templates (what to check, how often, whether a reading is needed) generate each day's checklist for staff.
- **Units and thresholds.** Add fridges, freezers and hot-hold points, with the correct legal temperature threshold pre-filled for each type.
- **Alerts.** Flagged units, overdue tasks and outstanding inductions in one place.
- **New starter induction.** New team members see the site's real thresholds and key rules, and confirm they've read them before starting.
- **Team management.** View who has access to a site and their induction status, and invite existing users by email.
- **Regulator report sharing.** Generate scoped, time-limited, revocable report links for inspectors.

## Tech Stack

| Layer    | Technology                                   |
| -------- | -------------------------------------------- |
| App      | Flutter (Dart)                               |
| Backend  | Supabase (PostgreSQL, Auth, Row Level Security) |
| Schema   | `supabase/schema.sql`                        |

## Getting Started

### Prerequisites

- Flutter SDK
- A free [Supabase](https://supabase.com) project

### Setup

1. **Clone the repo**

   ```bash
   git clone https://github.com/adeymoe/complykitchen.git
   cd complykitchen
   ```

2. **Create the database.** In your Supabase dashboard, open the SQL Editor, paste the full contents of `supabase/schema.sql` and run it. This creates the tables, RLS policies and the trigger that creates a profile on signup.

3. **Add your keys.** From **Settings > API**, copy the Project URL and the `anon` public key into `lib/config/supabase_config.dart`.

   > Never use the `service_role` key in the app.

4. **(Optional) Disable email confirmation for testing.** Go to **Authentication > Providers > Email** and turn off "Confirm email".

5. **Run the app**

   ```bash
   flutter pub get
   flutter run
   ```

### Quick Walkthrough

1. Sign up. This account becomes the owner.
2. Set up your restaurant to create your organisation and first site.
3. Add a unit (such as a fridge) from the Today screen or **Dashboard > Manage > Units**.
4. Add a task template linked to that unit, with "requires a reading" turned on.
5. Log a reading from Today or Tasks, and see it appear on Dashboard and Alerts.
6. To test team invites, sign up a second account, invite its email from **Manage > Team**, then sign in as the second account to see the induction flow.

## Roadmap

- [ ] Public viewer page for regulator report links (Supabase Edge Function)
- [ ] Invite users who don't have an account yet
- [ ] Edit and deactivate units and task templates
- [ ] Scheduled overnight task generation (Edge Function + `pg_cron`)
- [ ] Offline logging with sync when back online
- [ ] Nation-specific rules, such as Scotland's 82°C reheat requirement

## License

Proprietary. Copyright © 2026 Adedamola Araoye. All rights reserved.