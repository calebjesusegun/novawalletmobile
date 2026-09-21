#!/usr/bin/env bash
set -e

# NovaWallet Development Runner Script
# Usage:
#   ./scripts/dev.sh ios           Run app on iOS simulator
#   ./scripts/dev.sh android       Run app on Android emulator
#   ./scripts/dev.sh test          Run unit and widget tests
#   ./scripts/dev.sh integration   Run integration tests
#   ./scripts/dev.sh goldens       Run tests and update golden files
#   ./scripts/dev.sh check         Run format, analyze, and tests

COMMAND="${1:-help}"

case "$COMMAND" in
  ios)
    echo "==> Starting iOS Simulator and launching Nova Wallet..."
    open -a Simulator || true
    xcrun simctl boot 4BCC3B57-AD2A-496E-8221-8268438D9327 2>/dev/null || true
    flutter run -d "iPhone 17"
    ;;

  android)
    echo "==> Checking Android Emulator and launching Nova Wallet..."
    pgrep -f "Pixel_10_Pro_XL" >/dev/null || flutter emulators --launch Pixel_10_Pro_XL || true
    flutter run -d android
    ;;

  test)
    echo "==> Running unit and widget tests..."
    flutter test
    ;;

  integration)
    echo "==> Running integration tests..."
    if [ ! -d "integration_test" ]; then
      echo "Note: integration_test/ directory does not exist yet. Running flutter test..."
      flutter test
    else
      flutter test integration_test
    fi
    ;;

  goldens)
    echo "==> Updating golden test fixtures..."
    flutter test --update-goldens
    ;;

  check)
    echo "==> Checking code format..."
    dart format --output=none --set-exit-if-changed .
    echo "==> Running static analysis..."
    flutter analyze
    echo "==> Running test suite..."
    flutter test
    echo "==> All checks passed!"
    ;;

  *)
    echo "NovaWallet Dev Helper"
    echo ""
    echo "Usage: ./scripts/dev.sh [command]"
    echo ""
    echo "Commands:"
    echo "  ios          Launch iOS Simulator & run app"
    echo "  android      Launch Android Emulator (Pixel 10 Pro XL) & run app"
    echo "  test         Run unit & widget tests"
    echo "  integration  Run integration tests"
    echo "  goldens      Run tests and update golden files"
    echo "  check        Run format, analyzer, and test suite"
    ;;
esac
