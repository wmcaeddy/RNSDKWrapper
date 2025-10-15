#!/bin/bash

# Acuant SDK Example App - Setup Script
# This script automates the initial setup process

set -e

echo "=========================================="
echo "Acuant SDK Example App - Setup"
echo "=========================================="
echo ""

# Color codes
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check Node.js
echo "Checking Node.js..."
if ! command -v node &> /dev/null; then
    echo -e "${RED}❌ Node.js not found. Please install Node.js >= 16${NC}"
    exit 1
fi
NODE_VERSION=$(node -v)
echo -e "${GREEN}✓ Node.js $NODE_VERSION${NC}"

# Check Yarn or npm
echo "Checking package manager..."
if command -v yarn &> /dev/null; then
    PKG_MANAGER="yarn"
    echo -e "${GREEN}✓ Using Yarn${NC}"
elif command -v npm &> /dev/null; then
    PKG_MANAGER="npm"
    echo -e "${GREEN}✓ Using npm${NC}"
else
    echo -e "${RED}❌ Neither yarn nor npm found${NC}"
    exit 1
fi

# Install dependencies
echo ""
echo "Installing JavaScript dependencies..."
if [ "$PKG_MANAGER" = "yarn" ]; then
    yarn install
else
    npm install
fi
echo -e "${GREEN}✓ JavaScript dependencies installed${NC}"

# iOS setup (only on macOS)
if [[ "$OSTYPE" == "darwin"* ]]; then
    echo ""
    echo "Detected macOS - Setting up iOS..."

    # Check for CocoaPods
    if ! command -v pod &> /dev/null; then
        echo -e "${YELLOW}⚠ CocoaPods not found. Install with: sudo gem install cocoapods${NC}"
    else
        echo "Installing CocoaPods dependencies..."
        cd ios
        pod install
        cd ..
        echo -e "${GREEN}✓ iOS setup complete${NC}"
    fi
else
    echo -e "${YELLOW}⚠ Skipping iOS setup (not on macOS)${NC}"
fi

# Android setup
echo ""
echo "Checking Android setup..."
if [ -z "$ANDROID_HOME" ]; then
    echo -e "${YELLOW}⚠ ANDROID_HOME not set. Please configure Android SDK${NC}"
    echo "See SETUP.md for instructions"
else
    echo -e "${GREEN}✓ ANDROID_HOME: $ANDROID_HOME${NC}"
fi

# Create .env file if doesn't exist
echo ""
if [ ! -f .env ]; then
    echo "Creating .env file from template..."
    cp .env.example .env
    echo -e "${YELLOW}⚠ Please edit .env with your Acuant credentials${NC}"
else
    echo -e "${GREEN}✓ .env file exists${NC}"
fi

# Summary
echo ""
echo "=========================================="
echo "Setup Complete!"
echo "=========================================="
echo ""
echo "Next steps:"
echo ""
echo "1. Configure credentials in the app:"
echo "   - Launch app and tap '⚙️ Config'"
echo "   - Enter your Acuant credentials"
echo ""
echo "2. Run the app:"
echo "   iOS:     $PKG_MANAGER ios"
echo "   Android: $PKG_MANAGER android"
echo ""
echo "3. Start Metro bundler (if not auto-started):"
echo "   $PKG_MANAGER start"
echo ""
echo "For detailed setup instructions, see SETUP.md"
echo "For testing guide, see TESTING.md"
echo ""
