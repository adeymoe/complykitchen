import 'package:complykitchen/config/supabase_config.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('placeholder Supabase config enables demo mode', () {
    expect(SupabaseConfig.isDemoMode, isTrue);
  });
}
