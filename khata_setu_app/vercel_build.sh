#!/bin/bash

echo "Cloning Flutter stable channel..."
git clone https://github.com/flutter/flutter.git -b stable --depth 1

echo "Adding Flutter to PATH..."
export PATH="$PATH:`pwd`/flutter/bin"

echo "Resolving dependencies..."
flutter pub get

echo "Building Flutter Web App..."
flutter config --enable-web
flutter build web --release --dart-define=ENV=prod --no-pub -v

echo "Build complete!"
