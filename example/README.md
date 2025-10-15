# Acuant SDK Example App

Simple single-screen test application for the Acuant SDK React Native wrapper.

## What This App Does

This is a minimal test app that demonstrates the complete Acuant SDK workflow:

1. **Initialize SDK** - Configure with your credentials
2. **Capture Face** - Use the native camera to capture a selfie
3. **Process Liveness** - Check if the face is from a live person
4. **Face Match** - Compare two face images (demo: compares with itself)

All functionality is on one screen. No fancy UI, no navigation, just the SDK calls.

## Prerequisites

- Node.js >= 16
- React Native development environment set up
- For iOS: macOS with Xcode 14+, CocoaPods
- For Android: Android Studio, JDK 11+
- Acuant SDK credentials (username, password, subscription ID)

## Quick Start

### 1. Install Dependencies

```bash
# From the example directory
cd example
yarn install

# For iOS, install pods
cd ios && pod install && cd ..
```

### 2. Configure Credentials

The app uses an in-app configuration modal. On first launch:

1. Tap the "⚙️ Config" button in the top right
2. Enter your Acuant credentials:
   - Username
   - Password
   - Subscription ID
   - Region (USA, EU, AUS, or PREVIEW)
3. Tap "Save"

Alternatively, you can hardcode credentials in `App.tsx` for testing (not recommended for production):

```typescript
const [state, setState] = useState<AppState>({
  config: {
    username: 'your_username',
    password: 'your_password',
    subscription: 'your_subscription_id',
    region: AcuantRegion.USA,
  },
  // ... rest of state
});
```

### 3. Run the App

**iOS:**
```bash
yarn ios
# or
npx react-native run-ios
```

**Android:**
```bash
yarn android
# or
npx react-native run-android
```

## How to Use the App

### Individual Steps

1. **Configure** - Tap "⚙️ Config" to enter your credentials
2. **Initialize SDK** - Tap "Initialize SDK" button
3. **Capture Face** - Tap "Capture Face" button (grants camera permission if needed)
4. **Process Liveness** - Tap "Process Liveness" button
5. **Face Match** - Tap "Face Match" button

### Full Workflow

Tap the "▶️ Run Full Workflow" button to execute all steps automatically.

### Reset

Tap the "🔄 Reset" button to clear all state and start over.

## UI Features

- **Status Indicators** - Visual dots showing workflow progress
- **Image Preview** - Shows the captured face image
- **Results Display** - Shows liveness assessment and match results
- **Logs** - Collapsible log section with timestamp, copy, and clear buttons
- **Button States** - Buttons are automatically enabled/disabled based on workflow state

## Project Structure

```
example/
├── App.tsx                 # Main app (all logic in one file)
├── index.js                # Entry point
├── package.json            # Dependencies
├── metro.config.js         # Metro bundler config (resolves parent library)
├── tsconfig.json           # TypeScript config
├── babel.config.js         # Babel config
├── app.json                # App metadata
├── ios/
│   ├── Podfile            # Links to parent library iOS module
│   └── AcuantExample/
│       └── Info.plist     # Camera permissions
└── android/
    ├── settings.gradle    # Includes parent library Android module
    ├── build.gradle       # Root gradle config
    └── app/
        ├── build.gradle   # App gradle config
        └── src/main/
            └── AndroidManifest.xml  # Permissions

```

## Metro Configuration

The `metro.config.js` is configured to resolve the parent library during development:

```javascript
module.exports = {
  projectRoot: __dirname,
  watchFolders: [root], // Watches parent directory
  resolver: {
    extraNodeModules: {
      // Resolves parent library modules
    },
  },
};
```

This allows you to:
- Edit the SDK code in the parent directory
- See changes immediately in the example app (with hot reload)
- Test the SDK without publishing to npm

## Permissions

### iOS (Info.plist)
- `NSCameraUsageDescription` - Camera access for face capture
- `NSPhotoLibraryUsageDescription` - Photo library access (optional)

### Android (AndroidManifest.xml)
- `CAMERA` - Camera access for face capture
- `READ_EXTERNAL_STORAGE` - Read images
- `WRITE_EXTERNAL_STORAGE` - Save images
- `INTERNET` - API calls

## Troubleshooting

### Metro Bundler Issues

If you see "Unable to resolve module" errors:

```bash
# Clear Metro cache
yarn start --reset-cache

# Or manually
rm -rf node_modules
yarn install
```

### iOS Build Issues

```bash
# Clean and rebuild
cd ios
rm -rf Pods Podfile.lock
pod install
cd ..

# If still failing, clean Xcode build
xcodebuild clean -workspace ios/AcuantExample.xcworkspace -scheme AcuantExample
```

### Android Build Issues

```bash
# Clean gradle
cd android
./gradlew clean
cd ..

# Clear gradle cache
rm -rf android/.gradle
rm -rf android/app/build
```

### Camera Permission Denied

- **iOS**: Check Settings → Acuant SDK Example → Camera
- **Android**: Check Settings → Apps → Acuant SDK Example → Permissions → Camera

### SDK Initialization Fails

- Verify your credentials are correct
- Check your network connection
- Try a different region
- Check the logs for detailed error messages

### Module Not Found Errors

Make sure you've installed dependencies in the parent directory:

```bash
# From project root
cd ..
yarn install
```

## Testing Different Scenarios

See [TESTING.md](./TESTING.md) for a comprehensive test scenario checklist.

## Code Philosophy

This example app follows Linus Torvalds' principles:

1. **Simple and Direct** - All logic in one file, no unnecessary abstraction
2. **No Special Cases** - Linear workflow, minimal state transitions
3. **Pragmatic** - Solves the real problem (testing the SDK) without over-engineering
4. **Readable** - Clear variable names, obvious logic flow

The entire app is ~600 lines including UI, state management, and SDK calls. That's all you need.

## Debug Logging

All SDK operations are logged to:
- Console (via `console.log`)
- In-app logs section (tap to expand)

To view console logs:

```bash
# iOS
npx react-native log-ios

# Android
npx react-native log-android
```

## Development Workflow

1. Make changes to the SDK code in `/home/eddy/github/RNSDKWrapper/src/`
2. Metro will automatically reload
3. Test the changes in the example app
4. Check the logs for any errors

No need to rebuild or reinstall unless you change native code.

## Known Limitations

- Face Match demo compares the face with itself (for testing purposes)
- No persistent credential storage (enter each time)
- No advanced error recovery (intentionally kept simple)
- Single screen only (no navigation)

These are intentional design decisions to keep the example app simple and focused on testing SDK functionality.

## Support

For issues with:
- **The SDK wrapper**: Check [main README](../README.md)
- **Acuant SDK itself**: Refer to official Acuant documentation
- **React Native**: See [React Native docs](https://reactnative.dev)

## License

Same as parent project (MIT).
