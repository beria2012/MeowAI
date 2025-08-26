#!/bin/bash

echo "🔧 Force Mock Model Rebuild Script"
echo "This script will aggressively rebuild the entire project to ensure the mock model is properly packaged"
echo ""

# Navigate to project directory
cd /Users/oleksandr/Projects/MeowAI/MeowAI

echo "1. 🧹 Aggressive cleanup of all caches..."
rm -rf build/
rm -rf .dart_tool/
rm -rf android/build/
rm -rf android/app/build/
rm -rf android/.gradle/
rm -rf ~/.gradle/caches/
flutter clean

echo "2. 🔄 Creating fresh mock model..."
source cat_photos_env/bin/activate
cd tools
python3 create_mock_compatible_model.py
cd ..

echo "3. 📄 Verifying mock model is in place..."
ls -la assets/models/
echo "Model size: $(wc -c < assets/models/model.tflite) bytes"

echo "4. 🔄 Rebuilding Flutter dependencies..."
flutter pub get

echo "5. 🔄 Force refresh Flutter assets..."
flutter packages get
rm -f pubspec.lock
flutter pub get

echo "6. 🏗️ Building fresh APK..."
flutter build apk --debug --verbose

echo "7. 📱 Installing fresh APK..."
flutter install --debug

echo ""
echo "✅ Complete rebuild finished!"
echo "🔍 Check the logs for the model size - should show ~548KB instead of 16MB"
echo "🎯 The mock model should now resolve the FULLY_CONNECTED opcode compatibility issue"