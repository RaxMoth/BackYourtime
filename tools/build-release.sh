#!/usr/bin/env bash
# Build a signed .ipa for App Store submission.
#
# Prerequisites (one-time):
#   1) Run tools/setup-ios-toolchain.sh
#   2) In Apple Developer Portal, ensure App IDs + Distribution provisioning
#      profiles exist for all five bundle IDs:
#        com.maxroth.backyourtime
#        com.maxroth.backyourtime.FocusMonitor
#        com.maxroth.backyourtime.AppBlocker
#        com.maxroth.backyourtime.ShieldConfigurationExtension
#      (RunnerTests doesn't need a profile)
#   3) Install your Apple Distribution certificate in Keychain
#
# Output: build/ios/ipa/*.ipa, ready to upload via Transporter or `xcrun altool`.

set -euo pipefail
cd "$(dirname "$0")/.."

echo "==> Pre-flight checks"
flutter --version | head -1

echo
echo "==> Static analysis"
flutter analyze

echo
echo "==> Tests"
flutter test

echo
echo "==> Clean previous build artifacts"
flutter clean

echo
echo "==> Resolve Dart deps"
flutter pub get

echo
echo "==> Install Pods (uses bundle exec if a Gemfile is present)"
# CocoaPods needs UTF-8 locale or String#unicode_normalize blows up
# on ASCII-8BIT path bytes (Encoding::CompatibilityError).
export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8
if [ -f "ios/Gemfile" ] && command -v bundle >/dev/null 2>&1; then
  (cd ios && bundle exec pod install)
else
  (cd ios && pod install)
fi

echo
echo "==> Build IPA for App Store"
flutter build ipa --release \
  --export-options-plist=ios/ExportOptions.plist

IPA_PATH="$(ls -t build/ios/ipa/*.ipa 2>/dev/null | head -1 || true)"

echo
if [ -n "$IPA_PATH" ]; then
  echo "==> Build complete: $IPA_PATH"
  echo
  echo "Next steps:"
  echo "  1) Validate locally:"
  echo "       xcrun altool --validate-app -f \"$IPA_PATH\" -t ios --apiKey KEY --apiIssuer ISSUER"
  echo "  2) Upload to App Store Connect:"
  echo "       xcrun altool --upload-app -f \"$IPA_PATH\" -t ios --apiKey KEY --apiIssuer ISSUER"
  echo "     (or open Transporter.app and drag the .ipa)"
else
  echo "==> Build finished but no .ipa was produced — check Flutter output above."
  exit 1
fi
