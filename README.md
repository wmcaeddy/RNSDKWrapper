# RNSDKWrapper

React Native wrapper for Acuant SDK (iOS & Android)

## Overview

This repository provides a unified React Native wrapper for the Acuant identity verification SDKs, supporting both iOS and Android platforms.

## Project Structure

```
RNSDKWrapper/
├── ios-sdk/           # Acuant iOS SDK (submodule)
├── android-sdk/       # Acuant Android SDK (submodule)
├── src/               # React Native wrapper implementation
├── examples/          # Example applications
├── docs/              # Documentation
└── README.md
```

## Getting Started

### Clone with Submodules

```bash
git clone --recursive https://github.com/wmcaeddy/RNSDKWrapper.git
```

If you already cloned without `--recursive`:

```bash
git submodule update --init --recursive
```

### Update SDK Submodules

To update to the latest versions of the Acuant SDKs:

```bash
# Update both SDKs
git submodule update --remote

# Or update individually
git submodule update --remote ios-sdk
git submodule update --remote android-sdk

# Commit the updates
git add ios-sdk android-sdk
git commit -m "Update Acuant SDKs to latest versions"
```

## Development

Coming soon...

## License

Please refer to the individual SDK licenses:
- [iOS SDK](./ios-sdk)
- [Android SDK](./android-sdk)
