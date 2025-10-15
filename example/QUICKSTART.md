# Quick Start - TL;DR

Get the example app running in 5 minutes.

## Prerequisites Check

```bash
node --version   # Should be >= 16
java -version    # Should be 11+
```

## Setup (One Time)

```bash
cd /home/eddy/github/RNSDKWrapper/example

# Run automated setup
./setup.sh

# Or manual setup:
yarn install
cd ios && pod install && cd ..  # macOS only
```

## Run

**iOS:**
```bash
yarn ios
```

**Android:**
```bash
yarn android
```

## First Use

1. Tap **⚙️ Config** button
2. Enter credentials:
   - Username: `your_username`
   - Password: `your_password`
   - Subscription: `your_subscription_id`
   - Region: `USA` (or EU/AUS/PREVIEW)
3. Tap **Save**
4. Tap **▶️ Run Full Workflow**
5. Done!

## Commands

| Command | Description |
|---------|-------------|
| `yarn start` | Start Metro bundler |
| `yarn ios` | Run on iOS |
| `yarn android` | Run on Android |
| `yarn lint` | Lint code |
| `./setup.sh` | Automated setup |

## Troubleshooting

| Problem | Solution |
|---------|----------|
| Module not found | `yarn start --reset-cache` |
| iOS build fails | `cd ios && pod install` |
| Android build fails | `cd android && ./gradlew clean` |
| Camera not working | Grant permissions in Settings |
| SDK init fails | Check credentials & network |

## File Locations

- **Main App**: `/home/eddy/github/RNSDKWrapper/example/App.tsx`
- **iOS Config**: `/home/eddy/github/RNSDKWrapper/example/ios/Podfile`
- **Android Config**: `/home/eddy/github/RNSDKWrapper/example/android/settings.gradle`
- **SDK Source**: `/home/eddy/github/RNSDKWrapper/src/`

## Hot Reload

Edit SDK source files → Changes auto-reload in app. No rebuild needed.

## Need More Help?

- Full setup: [SETUP.md](./SETUP.md)
- Usage guide: [README.md](./README.md)
- Test scenarios: [TESTING.md](./TESTING.md)

---

**That's it. Simple.**
