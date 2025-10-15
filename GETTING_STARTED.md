# Getting Started with ID Verification Testing

A quick guide to prepare for testing the Acuant ID verification SDK.

---

## Prerequisites

### 1. Get Acuant Credentials

Contact Acuant to obtain:
- **Username**
- **Password**
- **Subscription ID**

*These credentials are required to initialize the SDK.*

### 2. Development Environment

**For iOS:**
- macOS computer
- Xcode 12.0+
- CocoaPods installed (`sudo gem install cocoapods`)
- iOS device or simulator (iOS 11.0+)

**For Android:**
- Android Studio
- Android SDK (API level 21+)
- Android device or emulator
- Java JDK 11+

**Both platforms:**
- Node.js 14+
- npm or yarn
- React Native CLI (`npm install -g react-native-cli`)

### 3. Hardware Requirements

**Required:**
- **Camera access** - For capturing face and documents
- **Internet connection** - For OCR processing and liveness detection

**Recommended:**
- Physical device (not emulator) for best camera quality
- Good lighting environment
- Clean camera lens

---

## Quick Setup (5 minutes)

### Step 1: Clone and Install

```bash
cd /home/eddy/github/RNSDKWrapper/example
./setup.sh
```

### Step 2: Configure Credentials

Open the app and tap **⚙️ Configure**:
- Enter your Acuant username
- Enter your Acuant password
- Enter your subscription ID
- Select region (usually **USA**)

### Step 3: Run the App

**iOS:**
```bash
yarn ios
```

**Android:**
```bash
yarn android
```

---

## What You'll Test

### Phase 1: Face Verification
1. **Initialize SDK** - Connects to Acuant servers
2. **Capture Face** - Takes a selfie using native camera
3. **Liveness Detection** - Verifies the person is live (not a photo)
4. **Face Match** - Compares two face images

### Phase 2: Document Verification
5. **Capture Document** - Scans ID card, passport, or driver license
   - Automatically captures front side
   - Prompts for back side if needed (IDs, not passports)
   - Validates image quality (sharpness, glare)
   - Extracts data via OCR (name, DOB, document number, etc.)

---

## Test Documents Needed

**Acceptable documents:**
- Government-issued ID card (front + back)
- Passport (front page only)
- Driver's license (front + back)

**Tips for best results:**
- Use original documents (not photocopies)
- Ensure good lighting (no shadows or glare)
- Hold document flat and steady
- Fill entire camera frame

---

## Expected Results

### Successful Flow
1. SDK initializes (2-5 seconds)
2. Face capture completes
3. Liveness returns "Live" with score >80
4. Document capture completes
5. OCR extracts correct data (name, DOB, etc.)
6. Total time: ~30-60 seconds

### Common Issues

| Issue | Solution |
|-------|----------|
| "IMAGE_TOO_BLURRY" | Retake with better focus |
| "IMAGE_HAS_GLARE" | Adjust lighting/angle |
| "NOT_LIVE" assessment | Ensure person is moving naturally |
| Initialization fails | Check credentials and internet |
| OCR data incorrect | Retake with better image quality |

---

## Support

**Example App Issues:**
- Check logs in the app (tap "Copy Logs")
- See `example/TESTING.md` for detailed test cases

**SDK Issues:**
- Contact Acuant support with your subscription ID
- Provide error codes from app logs

**General Questions:**
- See `README.md` for API documentation
- See `example/QUICKSTART.md` for setup help

---

## Next Steps

After successful testing:
1. Review extracted OCR data accuracy
2. Test with different document types
3. Test edge cases (poor lighting, worn documents)
4. Integrate into your production app

**Integration:**
```bash
npm install react-native-acuant-sdk
```

See `README.md` for full API reference.
