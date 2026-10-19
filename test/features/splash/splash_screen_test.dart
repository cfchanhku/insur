import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'Splash navigates to /setup when KeyManager is uninitialized',
    () {},
    skip: 'Deferred to the follow-up UI prompt for mock providers.',
  );
  test(
    'Splash navigates to /login when KeyManager is locked',
    () {},
    skip: 'Deferred to the follow-up UI prompt for mock providers.',
  );
  test(
    'Splash navigates to /home when KeyManager is unlocked',
    () {},
    skip: 'Deferred to the follow-up UI prompt for mock providers.',
  );
}
