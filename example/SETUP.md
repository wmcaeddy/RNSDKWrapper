# Example App Setup Guide

Complete setup instructions from scratch.

## Step-by-Step Setup

### 1. Prerequisites

**Required:**
- Node.js >= 16 (check: `node --version`)
- Yarn or npm
- Git

**For iOS Development:**
- macOS (required for iOS)
- Xcode 14 or later
- Xcode Command Line Tools: `xcode-select --install`
- CocoaPods: `sudo gem install cocoapods`

**For Android Development:**
- JDK 11 or later (check: `java -version`)
- Android Studio (latest stable)
- Android SDK (API 33)
- Android NDK (will be installed by Gradle)

### 2. Install Dependencies

```bash
# Navigate to example directory
cd /home/eddy/github/RNSDKWrapper/example

# Install Node.js dependencies
yarn install
# or
npm install
```

### 3. iOS Setup

```bash
# Install CocoaPods dependencies
cd ios
pod install
cd ..
```

**If pod install fails:**

```bash
# Clean and retry
cd ios
rm -rf Pods Podfile.lock
pod deintegrate
pod install
cd ..
```

**Common iOS Issues:**

1. **Ruby version issues**: Use system Ruby or rbenv
2. **CocoaPods version**: Update with `sudo gem install cocoapods`
3. **Xcode path**: Run `sudo xcode-select -s /Applications/Xcode.app`

### 4. Android Setup

**Configure Android SDK in Android Studio:**

1. Open Android Studio
2. SDK Manager → Install:
   - Android SDK Platform 33
   - Android SDK Build-Tools 33.0.0
   - Android Emulator
   - Android SDK Platform-Tools

**Set environment variables** (add to `~/.bashrc` or `~/.zshrc`):

```bash
export ANDROID_HOME=$HOME/Library/Android/sdk
export PATH=$PATH:$ANDROID_HOME/emulator
export PATH=$PATH:$ANDROID_HOME/platform-tools
```

**Verify setup:**

```bash
# Check ADB
adb version

# List devices
adb devices
```

### 5. Run the App

**iOS:**

```bash
# Start Metro bundler
yarn start

# In another terminal, run iOS
yarn ios
# or specify device
npx react-native run-ios --device="iPhone 14 Pro"
```

**Android:**

```bash
# Start Metro bundler
yarn start

# In another terminal, run Android
yarn android
# or specify device
adb devices  # Find device ID
npx react-native run-android --deviceId=DEVICE_ID
```

### 6. Configure Acuant Credentials

On first launch:

1. Tap "⚙️ Config" button
2. Enter your credentials:
   - Username
   - Password
   - Subscription ID
   - Region (USA/EU/AUS/PREVIEW)
3. Tap "Save"

### 7. Grant Permissions

**iOS:**
- Camera access will be requested on first use
- Settings → Privacy → Camera → Acuant SDK Example → ON

**Android:**
- Camera permission will be requested on first use
- Settings → Apps → Acuant SDK Example → Permissions → Camera → Allow

## Development Workflow

### Hot Reload

1. Make changes to `/home/eddy/github/RNSDKWrapper/src/` (parent SDK code)
2. Changes auto-reload in the example app
3. No rebuild needed (unless native code changed)

### Reset Metro Cache

If you see module resolution errors:

```bash
yarn start --reset-cache
```

### Clean Builds

**iOS:**
```bash
cd ios
xcodebuild clean -workspace AcuantExample.xcworkspace -scheme AcuantExample
cd ..
```

**Android:**
```bash
cd android
./gradlew clean
cd ..
```

## Troubleshooting

### "Unable to resolve module"

```bash
# Clear caches
rm -rf node_modules
yarn install
yarn start --reset-cache
```

### iOS Build Fails

```bash
# Clean everything
cd ios
rm -rf Pods Podfile.lock build DerivedData
pod install
cd ..

# Open Xcode and clean
open ios/AcuantExample.xcworkspace
# Product → Clean Build Folder (Cmd+Shift+K)
```

### Android Build Fails

```bash
# Clean gradle
cd android
./gradlew clean
rm -rf .gradle build app/build
cd ..

# Invalidate caches in Android Studio
# File → Invalidate Caches / Restart
```

### Metro Bundler Issues

```bash
# Kill all node processes
killall node

# Clear watchman
watchman watch-del-all

# Clear metro cache
rm -rf $TMPDIR/metro-*
rm -rf $TMPDIR/haste-*

# Restart
yarn start --reset-cache
```

### Camera Not Working

**iOS:**
- Check Info.plist has `NSCameraUsageDescription`
- Check Settings → Privacy → Camera
- Restart device
- Real device required (simulator has no camera)

**Android:**
- Check AndroidManifest.xml has camera permissions
- Check Settings → Apps → Permissions
- Restart device
- Emulator needs camera passthrough enabled

### SDK Initialization Fails

1. **Check credentials** - Verify username/password/subscription
2. **Check network** - Must have internet connection
3. **Check region** - Try different regions
4. **Check logs** - Look for specific error codes in logs

### Native Module Linking Issues

If you see "AcuantSdk module not found":

**iOS:**
```bash
cd ios
pod install
cd ..
npx react-native run-ios
```

**Android:**
```bash
cd android
./gradlew clean
cd ..
npx react-native run-android
```

## File Structure Reference

```
example/
├── App.tsx                      # Main app (600 lines)
├── index.js                     # Entry point
├── package.json                 # Dependencies
├── metro.config.js              # Metro config (resolves parent lib)
├── tsconfig.json                # TypeScript config
├── babel.config.js              # Babel config
├── app.json                     # App metadata
│
├── ios/
│   ├── Podfile                 # CocoaPods config
│   ├── AcuantExample.xcworkspace/  # Xcode workspace (generated)
│   ├── AcuantExample/
│   │   └── Info.plist          # iOS permissions
│   └── Pods/                   # CocoaPods dependencies (generated)
│
└── android/
    ├── settings.gradle         # Gradle settings
    ├── build.gradle            # Root gradle config
    ├── gradle.properties       # Gradle properties
    ├── gradlew                 # Gradle wrapper (executable)
    ├── gradle/wrapper/         # Gradle wrapper files
    └── app/
        ├── build.gradle        # App gradle config
        └── src/main/
            ├── AndroidManifest.xml  # Android permissions
            ├── java/com/acuantexample/
            │   ├── MainActivity.java
            │   └── MainApplication.java
            └── res/            # Android resources
```

## Next Steps

1. ✅ Setup complete
2. ✅ App running
3. ✅ Credentials configured
4. ✅ Permissions granted
5. 👉 Try the full workflow
6. 📋 Run test scenarios from TESTING.md

## Getting Help

- **Example app issues**: Check this guide
- **SDK wrapper issues**: See [main README](../README.md)
- **Acuant SDK issues**: Acuant documentation
- **React Native issues**: [React Native troubleshooting](https://reactnative.dev/docs/troubleshooting)

## Tips

- Use real devices for camera testing
- Keep Metro bundler running in a separate terminal
- Check logs for detailed error messages
- Test on both iOS and Android
- Clear caches when things break mysteriously
