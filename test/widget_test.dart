// Basic smoke test for Unspend.

import 'package:flutter_test/flutter_test.dart';
import 'package:unspend/core/constants/strings.dart';

void main() {
  test('S.init() completes without error', () async {
    // Verify that the localization system initialises.
    await S.init();
    expect(S.current.appName, 'Unspend');
  });
}
