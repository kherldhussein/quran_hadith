#!/bin/bash

# Quran & Hadith Desktop App - Setup Script
# This script helps you get the app up and running quickly

set -e

echo "=========================================="
echo "Qur'an & Hadith Desktop App Setup"
echo "=========================================="
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check if Flutter is installed
echo "📋 Checking Flutter installation..."
if ! command -v flutter &> /dev/null; then
    echo -e "${RED}❌ Flutter is not installed${NC}"
    echo "Please install Flutter from: https://flutter.dev/docs/get-started/install"
    exit 1
fi

echo -e "${GREEN}✅ Flutter is installed${NC}"
flutter --version
echo ""

# Check Flutter doctor
echo "🔍 Running Flutter doctor..."
flutter doctor
echo ""

# Clean previous builds
echo "🧹 Cleaning previous builds..."
flutter clean
echo -e "${GREEN}✅ Clean complete${NC}"
echo ""

# Get dependencies
echo "📦 Installing dependencies..."
flutter pub get
if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ Dependencies installed${NC}"
else
    echo -e "${RED}❌ Failed to install dependencies${NC}"
    exit 1
fi
echo ""

# Generate Hive adapters
echo "🔨 Generating Hive adapters..."
echo "This may take a few minutes..."
flutter packages pub run build_runner build --delete-conflicting-outputs
if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ Hive adapters generated${NC}"
else
    echo -e "${YELLOW}⚠️  Hive adapter generation failed${NC}"
    echo "You may need to manually run: flutter packages pub run build_runner build"
fi
echo ""

# Detect platform
echo "🖥️  Detecting platform..."
if [[ "$OSTYPE" == "linux-gnu"* ]]; then
    PLATFORM="linux"
elif [[ "$OSTYPE" == "darwin"* ]]; then
    PLATFORM="macos"
elif [[ "$OSTYPE" == "msys" || "$OSTYPE" == "win32" ]]; then
    PLATFORM="windows"
else
    PLATFORM="linux"
fi
echo -e "${GREEN}✅ Detected platform: $PLATFORM${NC}"
echo ""

# Ask if user wants to run the app
echo "=========================================="
echo "Setup complete! 🎉"
echo "=========================================="
echo ""
read -p "Would you like to run the app now? (y/n): " -n 1 -r
echo ""
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "🚀 Starting the app..."
    flutter run -d $PLATFORM
fi

echo ""
echo "=========================================="
echo "Next Steps:"
echo "=========================================="
echo "1. Run the app: flutter run -d $PLATFORM"
echo "2. Build for production: flutter build $PLATFORM --release"
echo "3. Read the documentation: IMPLEMENTATION_GUIDE.md"
echo ""
echo "For issues, check: https://github.com/kherld-hussein/quran_hadith/issues"
echo ""
echo "Enjoy your enhanced Quran & Hadith app! 📖✨"
