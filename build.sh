#!/bin/bash
if [[ "$1" == "--clean" ]]; then
    flutter clean
    flutter pub cache clean --force
    flutter pub get
fi

if [[ "$1" == "--all" ]]; then
    flutter build apk --release --split-per-abi --target-platform=android-arm,android-arm64 --split-debug-info=build/app/outputs/symbols
else
    flutter build apk --release --split-per-abi --target-platform=android-arm64 --split-debug-info=build/app/outputs/symbols
fi