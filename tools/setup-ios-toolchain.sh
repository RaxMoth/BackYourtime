#!/usr/bin/env bash
# One-time setup so `pod install` works against Xcode 26's project format.
#
# Background: macOS ships with Ruby 2.6, which is too old for modern
# CocoaPods. We install Homebrew Ruby + Bundler, then use the project
# Gemfile (ios/Gemfile) to pin compatible cocoapods/xcodeproj versions.
#
# Run once after cloning. Afterwards always use `bundle exec pod install`
# from the ios/ directory.

set -euo pipefail

cd "$(dirname "$0")/.."
PROJECT_ROOT="$PWD"

echo "==> Checking Homebrew…"
if ! command -v brew >/dev/null 2>&1; then
  echo "    Homebrew not found. Install from https://brew.sh first."
  exit 1
fi

echo "==> Installing Homebrew Ruby (if missing)…"
if ! brew list ruby >/dev/null 2>&1; then
  brew install ruby
fi

# Determine the brew Ruby bin dir (Apple Silicon vs Intel)
BREW_PREFIX="$(brew --prefix)"
RUBY_BIN="$BREW_PREFIX/opt/ruby/bin"

if [ ! -x "$RUBY_BIN/ruby" ]; then
  echo "    Could not find Homebrew Ruby at $RUBY_BIN"
  exit 1
fi

echo "==> Homebrew Ruby: $($RUBY_BIN/ruby --version)"

echo "==> Make sure your shell PATH prefers Homebrew Ruby."
echo "    Add this line to ~/.zshrc (or ~/.bashrc) if not already there:"
echo
echo "      export PATH=\"$RUBY_BIN:\$PATH\""
echo

echo "==> Installing Bundler under Homebrew Ruby…"
"$RUBY_BIN/gem" install bundler --no-document

echo "==> Installing project gems (cocoapods, xcodeproj) via Bundler…"
cd "$PROJECT_ROOT/ios"
PATH="$RUBY_BIN:$PATH" bundle install

echo
echo "==> Done."
echo
echo "From now on, run pod install from ios/ as:"
echo "    LANG=en_US.UTF-8 bundle exec pod install"
echo
echo "Or if your PATH and locale are set up correctly, just:"
echo "    pod install"
echo
echo "Note: CocoaPods (config.rb) calls String#unicode_normalize, which"
echo "throws Encoding::CompatibilityError when LANG is unset or non-UTF-8."
echo "tools/build-release.sh already exports LANG for you."
