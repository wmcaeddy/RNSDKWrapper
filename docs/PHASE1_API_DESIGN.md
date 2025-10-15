# Phase 1 API Design - React Native Acuant SDK Wrapper

## Overview

Phase 1 focuses on **Face Recognition** and **Identity Verification** features:
- SDK Initialization
- Face Capture
- Passive Liveness Detection
- Face Matching

## Design Philosophy (Linus Torvalds Principles)

### 1. Good Taste - Simple Data Flow
```
User Space (JavaScript)
    ↓
React Native Bridge
    ↓
Native Module (Kotlin/Swift)
    ↓
Acuant SDK (Read-Only Submodule)
```

**No special cases.** Both iOS and Android expose identical APIs.

### 2. Never Break Userspace
- All methods return Promises
- Errors are explicit (code + message)
- API designed for Phase 2 extension without breaking changes

### 3. Pragmatism
- Solve real problems: Face capture, liveness detection, identity verification
- No theoretical abstractions
- Direct mapping to Acuant SDK functionality

### 4. Simplicity
- 4 core methods, each does ONE thing
- No nested callbacks
- No platform-specific APIs in JS layer

---

## Core API

### 1. Initialization

```typescript
async function initialize(
  options: AcuantInitializationOptions
): Promise<void>
```

**Purpose:** Initialize Acuant SDK with credentials or token

**Options:**
```typescript
interface AcuantInitializationOptions {
  credentials?: {
    username: string;
    password: string;
    subscription: string;
  };
  token?: string;
  endpoints?: {
    frmEndpoint?: string;
    passiveLivenessEndpoint?: string;
    // ... other endpoints
  };
  region?: 'USA' | 'EU' | 'AUS' | 'PREVIEW';
}
```

**Native SDK Mapping:**
- iOS: `AcuantInitializer.initialize()`
- Android: `AcuantInitializer.initialize()`

**Error Cases:**
- Invalid credentials
- Network failure
- Invalid endpoints

---

### 2. Face Capture

```typescript
async function captureFace(
  options?: FaceCaptureOptions
): Promise<FaceCaptureResult>
```

**Purpose:** Launch native UI to capture face image optimized for liveness

**Options:**
```typescript
interface FaceCaptureOptions {
  totalCaptureTime?: number;  // Default: 2 seconds
  showOval?: boolean;         // Default: false
}
```

**Result:**
```typescript
interface FaceCaptureResult {
  jpegData: string;  // Base64 encoded JPEG
  imageUri?: string; // Platform-specific file URI (optional)
}
```

**Native SDK Mapping:**
- iOS: `FaceCaptureController`
- Android: `AcuantFaceCameraActivity`

**Error Cases:**
- User canceled
- Camera permission denied
- Capture timeout

---

### 3. Passive Liveness Detection

```typescript
async function processPassiveLiveness(
  request: PassiveLivenessRequest
): Promise<PassiveLivenessResult>
```

**Purpose:** Determine if face image is from live person

**Request:**
```typescript
interface PassiveLivenessRequest {
  jpegData: string; // Base64 encoded JPEG from captureFace
}
```

**Result:**
```typescript
interface PassiveLivenessResult {
  score: number;
  assessment: 'Live' | 'NotLive' | 'PoorQuality' | 'Error';
  transactionId?: string;
}
```

**Native SDK Mapping:**
- iOS: `PassiveLiveness.postLiveness()`
- Android: `AcuantPassiveLiveness.processFaceLiveness()`

**Important:** Use `assessment`, NOT `score`, for decision making.

**Error Cases:**
- Network failure
- Invalid image format
- Face not found
- Face too small/close/angled

---

### 4. Face Match

```typescript
async function processFaceMatch(
  request: FaceMatchRequest
): Promise<FaceMatchResult>
```

**Purpose:** Compare two face images (ID photo vs selfie)

**Request:**
```typescript
interface FaceMatchRequest {
  faceOneData: string; // Base64 JPEG - from ID document
  faceTwoData: string; // Base64 JPEG - from selfie
}
```

**Result:**
```typescript
interface FaceMatchResult {
  isMatch: boolean;
  score: number;
}
```

**Native SDK Mapping:**
- iOS: `AcuantFaceMatch.processFacialMatch()`
- Android: `AcuantFaceMatch.processFacialMatch()`

**Error Cases:**
- Network failure
- Invalid image format
- Face not found in either image

---

## Error Handling

All errors follow consistent structure:

```typescript
interface AcuantError {
  code: AcuantErrorCode;
  message: string;
}

enum AcuantErrorCode {
  InvalidCredentials = -1,
  InvalidEndpoint = -3,
  InitializationNotFinished = -4,
  Network = -5,
  // ... etc
}
```

**Promise rejection pattern:**
```javascript
try {
  await initialize(options);
} catch (error) {
  console.error(error.code, error.message);
}
```

---

## Typical Workflow

```typescript
// 1. Initialize SDK
await AcuantSdk.initialize({
  credentials: {
    username: 'xxx',
    password: 'xxx',
    subscription: 'xxx'
  },
  region: 'USA'
});

// 2. Capture face
const faceResult = await AcuantSdk.captureFace({
  totalCaptureTime: 2,
  showOval: false
});

// 3. Check liveness
const livenessResult = await AcuantSdk.processPassiveLiveness({
  jpegData: faceResult.jpegData
});

if (livenessResult.assessment === 'Live') {
  // 4. (Optional) Match with ID photo
  const matchResult = await AcuantSdk.processFaceMatch({
    faceOneData: idPhotoBase64,
    faceTwoData: faceResult.jpegData
  });

  if (matchResult.isMatch) {
    console.log('Identity verified!');
  }
}
```

---

## Data Structure Analysis (Linus Layer 1)

### Core Data: Face Image
- **Ownership:** User's device camera → Native module → Acuant SDK
- **Format:** JPEG (Base64 encoded for JS bridge)
- **Flow:** Unidirectional (camera → processing → result)
- **No copying:** Direct pass-through to Acuant SDK

### Why Base64?
- React Native bridge limitation (cannot pass binary data directly)
- Alternative (File URI) provided but base64 is primary
- **Trade-off:** Simplicity > Performance for initialization phase

---

## Edge Cases Eliminated (Linus Layer 2)

### No Platform-Specific Branches in JS
```typescript
// ❌ BAD - Platform-specific API
if (Platform.OS === 'ios') {
  await initializeIOS();
} else {
  await initializeAndroid();
}

// ✅ GOOD - Same API for all platforms
await initialize(options);
```

### No State Management
- SDK is stateless at JS layer
- Each call is independent
- No initialization state tracking in JS

### No Callback Hell
- All async operations return Promises
- No nested callbacks
- No event emitters unless absolutely necessary

---

## Complexity Review (Linus Layer 3)

### What is the essence?
> "Capture a face, verify it's live, match it with an ID photo"

### How many concepts?
- 4 methods
- 3 data types (image, result, error)
- 1 initialization step

### Can we simplify?
- **No.** Each method serves distinct purpose
- Already minimal viable API
- No unnecessary abstractions

---

## Backward Compatibility (Linus Layer 4)

### Phase 2 Extension Plan
Future additions will NOT break Phase 1:

```typescript
// Phase 2: Document Processing (additive, not breaking)
async function captureDocument(options): Promise<DocumentResult>
async function processDocument(request): Promise<DocumentData>
```

### Versioning Strategy
- Semantic versioning: 0.x.y for pre-1.0
- Major version bump for breaking changes
- Deprecation warnings before removal

---

## Risks and Mitigations

### Risk 1: Acuant SDK API Changes
**Impact:** High
**Mitigation:** Submodules pinned to specific versions (11.6.3 Android, 11.6.5 iOS)

### Risk 2: Base64 Performance
**Impact:** Medium (large images)
**Mitigation:** Consider native file passing in future optimization

### Risk 3: Platform API Divergence
**Impact:** Medium
**Mitigation:** Skeleton implementation enforces identical APIs

### Risk 4: Initialization Complexity
**Impact:** Low
**Mitigation:** Simple credential or token-based init only

---

## Implementation Status

This is a **DESIGN DOCUMENT**.

All native modules contain **SKELETON CODE** only:
- Structure is defined
- Method signatures are correct
- Implementation returns `NOT_IMPLEMENTED` errors

**Next Phase:** Implement actual Acuant SDK integration after this design is approved.

---

## File Structure

```
RNSDKWrapper/
├── src/
│   ├── index.ts              # Public API exports
│   └── types.ts              # TypeScript type definitions
├── ios/
│   ├── AcuantSdk.h           # Objective-C bridge header
│   ├── AcuantSdk.m           # Objective-C bridge
│   └── AcuantSdkImpl.swift   # Swift implementation (skeleton)
├── android/
│   └── src/main/java/com/acuantsdk/
│       ├── AcuantSdkPackage.kt
│       └── AcuantSdkModule.kt  # Kotlin implementation (skeleton)
├── ios-sdk/                  # Acuant iOS SDK (submodule, read-only)
├── android-sdk/              # Acuant Android SDK (submodule, read-only)
└── package.json
```

---

## Conclusion

This API design follows Linus Torvalds' principles:

1. **Good Taste:** Simple, direct data flow. No special cases.
2. **Never Break Userspace:** Promise-based, extensible for Phase 2.
3. **Pragmatism:** Solves real problem with minimal abstraction.
4. **Simplicity:** 4 methods, clear purpose, no complexity.

The design is ready for implementation.
