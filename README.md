# React Native Acuant SDK Wrapper

A pragmatic React Native wrapper for Acuant SDK, supporting iOS and Android.

**Current Phase:** 1 - Face Recognition & Identity Verification
**Status:** Structure Complete, Implementation Ready
**SDK Versions:** iOS 11.6.5 | Android 11.6.3

---

## Overview

This library provides a clean, simple interface to Acuant's identity verification SDKs from React Native applications.

**Phase 1 Features:**
- SDK Initialization (credentials or token-based)
- Face Capture with native UI
- Passive Liveness Detection
- Face Matching (ID photo vs selfie)

**Phase 2 (Future):**
- Document Capture
- Document Processing
- Barcode Reading
- MRZ Reading

---

## Design Philosophy

This wrapper follows Linus Torvalds' principles:

1. **Simplicity:** 4 core methods, each doing one thing well
2. **No Special Cases:** Same API for iOS and Android
3. **Pragmatism:** Direct mapping to Acuant SDK, no unnecessary abstraction
4. **Backward Compatibility:** Phase 2 will extend, not break, Phase 1

---

## Installation

```bash
npm install react-native-acuant-sdk
# or
yarn add react-native-acuant-sdk
```

### iOS Setup

```bash
cd ios && pod install
```

Add `AcuantConfig.plist` to your iOS project with Acuant credentials.

### Android Setup

Add Acuant configuration XML to `android/app/src/main/assets/`.

Ensure permissions in `AndroidManifest.xml`:
```xml
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.CAMERA" />
```

---

## Quick Start

```typescript
import AcuantSdk from 'react-native-acuant-sdk';

// 1. Initialize
await AcuantSdk.initialize({
  credentials: {
    username: 'your-username',
    password: 'your-password',
    subscription: 'your-subscription-id'
  },
  region: 'USA'
});

// 2. Capture face
const faceResult = await AcuantSdk.captureFace();

// 3. Check liveness
const livenessResult = await AcuantSdk.processPassiveLiveness({
  jpegData: faceResult.jpegData
});

if (livenessResult.assessment === 'Live') {
  // 4. Match with ID photo
  const matchResult = await AcuantSdk.processFaceMatch({
    faceOneData: idPhotoBase64,
    faceTwoData: faceResult.jpegData
  });

  console.log('Match:', matchResult.isMatch, matchResult.score);
}
```

---

## API Reference

See [docs/PHASE1_API_DESIGN.md](docs/PHASE1_API_DESIGN.md) for complete API documentation.

### Core Methods

```typescript
// Initialize SDK
async function initialize(options: AcuantInitializationOptions): Promise<void>

// Capture face with native UI
async function captureFace(options?: FaceCaptureOptions): Promise<FaceCaptureResult>

// Process passive liveness
async function processPassiveLiveness(request: PassiveLivenessRequest): Promise<PassiveLivenessResult>

// Match two face images
async function processFaceMatch(request: FaceMatchRequest): Promise<FaceMatchResult>
```

---

## Project Structure

```
RNSDKWrapper/
├── src/                      # TypeScript source
│   ├── index.ts             # Public API
│   └── types.ts             # Type definitions
├── ios/                      # iOS native module
│   ├── AcuantSdk.h
│   ├── AcuantSdk.m
│   └── AcuantSdkImpl.swift
├── android/                  # Android native module
│   └── src/main/java/com/acuantsdk/
│       ├── AcuantSdkPackage.kt
│       └── AcuantSdkModule.kt
├── ios-sdk/                  # Acuant iOS SDK (submodule, read-only)
├── android-sdk/              # Acuant Android SDK (submodule, read-only)
├── docs/                     # Documentation
├── examples/                 # Example applications
└── package.json
```

---

## Native SDK Submodules

This wrapper uses git submodules to reference Acuant's official SDKs:

```bash
# Clone with submodules
git clone --recursive https://github.com/wmcaeddy/RNSDKWrapper.git

# Or initialize submodules after cloning
git submodule update --init --recursive

# Update to latest SDK versions
git submodule update --remote
git add ios-sdk android-sdk
git commit -m "Update Acuant SDKs to latest versions"
```

**Important:** Native SDKs are read-only. Never modify files in `ios-sdk/` or `android-sdk/`.

---

## Documentation

- [Phase 1 API Design](docs/PHASE1_API_DESIGN.md) - Complete API reference
- [Initialization Report](docs/INITIALIZATION_REPORT.md) - Technical implementation details
- [Acuant iOS SDK](ios-sdk/README.md) - Official iOS SDK documentation
- [Acuant Android SDK](android-sdk/README.md) - Official Android SDK documentation

---

## Development Status

**Phase 1: Structure Complete**

- ✅ TypeScript API defined
- ✅ iOS native module skeleton
- ✅ Android native module skeleton
- ✅ Build configuration
- ⏳ Implementation in progress

All native methods currently return `NOT_IMPLEMENTED` errors. Implementation follows skeleton structure.

---

## Requirements

**iOS:**
- iOS 11.0+
- Xcode 15+
- CocoaPods

**Android:**
- minSdkVersion 21
- compileSdkVersion 33
- Kotlin support

**React Native:**
- React Native 0.60+
- TypeScript support recommended

---

## License

This wrapper is MIT licensed.

Acuant SDK licenses:
- [iOS SDK License](./ios-sdk/EULA.pdf)
- [Android SDK License](./android-sdk/EULA.pdf)

---

## Contributing

Contributions welcome! Please follow these principles:

1. Keep it simple (Linus's law: "Good taste eliminates special cases")
2. No breaking changes to Phase 1 API
3. Write tests for new features
4. Update documentation

---

## Support

- [Acuant Official Support](https://support.acuant.com)
- [GitHub Issues](https://github.com/wmcaeddy/RNSDKWrapper/issues)

---

**Designed with Linus Torvalds' principles in mind:**
> "Bad programmers worry about the code. Good programmers worry about data structures and their relationships."
