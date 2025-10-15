# Phase 2 API Design: Document Scanning and OCR

**Author:** Linus Torvalds Principle Enforcer
**Date:** 2025-10-15
**Status:** Implemented

---

## Design Philosophy

Following Linus Torvalds principles:

### 1. **"Good Taste" - Simplicity First**
> "Sometimes you can see a problem from a different angle, rewrite it, and the special cases disappear."

**Problem:** Acuant SDK's document workflow is complex (6 steps: createInstance → uploadFrontImage → getClassification → uploadBackImage → getData → deleteInstance).

**Solution:** Combine into **ONE method** `captureAndProcessDocument()` that handles all complexity internally.

**Why?** Users don't care about internal steps. They want: "capture document → get OCR data". Done.

### 2. **"Never Break Userspace"**
> "We do not break userspace!"

- Phase 1 API remains **100% unchanged**
- Phase 2 adds new functionality without modifying existing methods
- Same error handling pattern as Phase 1
- Same Promise-based async model
- Same Base64 data transport

### 3. **Pragmatism Over Perfection**
> "Solve real problems, not imaginary threats."

- No document type enum the user must select (SDK auto-detects)
- No separate front/back capture methods (user prompted after front capture)
- No complex classification options (SDK defaults are good enough)
- Flat data structure (no nested `{ personal: { name: { first: "", last: "" } } }` garbage)

### 4. **Obsession with Simplicity**
> "If you need more than 3 levels of indentation, you're screwed."

- One public method: `captureAndProcessDocument()`
- Flat result object with optional fields
- No special cases - works for ID cards, passports, driver licenses with same API

---

## API Specification

### Method

```typescript
captureAndProcessDocument(options?: DocumentCaptureOptions): Promise<DocumentResult>
```

**What it does:**
1. Launches camera UI
2. Captures front image (auto or manual)
3. Prompts user: "Capture back side?"
4. If yes, captures back image
5. Evaluates image quality (sharpness, glare)
6. Uploads to Acuant servers
7. Returns OCR extracted data + images

**All in ONE call.** No state management needed.

### Types

```typescript
interface DocumentCaptureOptions {
  documentType?: 'Auto' | 'ID' | 'Passport' | 'DriverLicense';  // Default: Auto
}

interface DocumentResult {
  // Captured images (Base64 encoded)
  frontImage: string;
  backImage?: string;  // Optional for passport

  // OCR extracted data (FLAT structure)
  fullName?: string;
  firstName?: string;
  lastName?: string;
  dateOfBirth?: string;
  documentNumber?: string;
  expirationDate?: string;
  issueDate?: string;
  address?: string;
  country?: string;
  nationality?: string;
  sex?: string;

  // Metadata
  documentType: string;        // Actual type detected by SDK
  isProcessed: boolean;         // true if OCR succeeded
  classificationDetails?: string;
}
```

**Key Design Decisions:**

1. **Flat Structure:** No nesting. Every field is top-level optional.
2. **Optional Fields:** SDK might not extract all fields. Everything is `?` except metadata.
3. **Images Included:** Front/back images returned in same result (no separate API call needed).
4. **Boolean Flag:** `isProcessed` tells you if OCR worked (don't rely on presence of fields).

---

## Error Handling

Same pattern as Phase 1:

```typescript
try {
  const result = await captureAndProcessDocument();
  // Success
} catch (error) {
  // Error codes:
  // - "USER_CANCELED" - User cancelled
  // - "IMAGE_TOO_BLURRY" - Image quality too low
  // - "IMAGE_HAS_GLARE" - Too much glare
  // - "NO_ACTIVITY" - Android: Activity not found
  // - "GET_DATA_FAILED" - OCR processing failed
}
```

**No special cases.** All errors throw with descriptive messages.

---

## Implementation Details

### iOS (Swift)

**Key Components:**
- `DocumentCameraViewController` - Native camera UI
- `ImagePreparation.evaluateImage()` - Quality check (sharpness, glare)
- `DocumentProcessing.createInstance()` - Create processing instance
- `instance.uploadFront()` / `instance.uploadBack()` - Upload images
- `instance.getData()` - Get OCR results

**Flow:**
1. Launch camera → capture front
2. Dismiss → prompt "Capture back?"
3. If yes, launch camera → capture back
4. Evaluate image quality
5. Create instance → upload → get data → delete instance
6. Return result

**Lines of code:** ~250 (including delegate methods)

### Android (Kotlin)

**Key Components:**
- `AcuantCameraActivity` - Native camera UI with auto-capture
- `AcuantImagePreparation.evaluateImage()` - Quality check
- `AcuantDocumentProcessing.createInstance()` - Create processing instance
- `instance.uploadFrontImage()` / `instance.uploadBackImage()` - Upload
- `instance.getData()` - Get OCR results

**Flow:**
1. Launch camera → capture front
2. Handle result → prompt "Capture back?"
3. If yes, launch camera → capture back
4. Evaluate image quality
5. Create instance → upload → get data → delete instance
6. Return result

**Lines of code:** ~200 (including activity result handler)

---

## Quality Thresholds

Based on Acuant SDK documentation:

- **Sharpness:** Must be > 50 (0-100 scale, higher is sharper)
- **Glare:** Must be > 50 (0-100 scale, 100 = no glare)
- **DPI:** Automatically handled by SDK (300+ for data capture, 600+ for authentication)

**Pragmatic decision:** Reject images below threshold immediately with clear error message. Forces user to retake. Better than processing bad image and getting poor OCR results.

---

## Testing Recommendations

### Unit Tests (Not Implemented - Out of Scope)

Would test:
- Promise resolution/rejection
- Error message formatting
- Data structure validation

### Integration Tests (Manual)

Test cases in example app:

1. **Basic Flow:**
   - Initialize SDK
   - Capture document (front only)
   - Verify OCR data extracted
   - Verify images returned

2. **Front + Back:**
   - Initialize SDK
   - Capture front → capture back
   - Verify both images returned
   - Verify OCR data from both sides

3. **Quality Rejection:**
   - Capture blurry image → expect "IMAGE_TOO_BLURRY"
   - Capture image with glare → expect "IMAGE_HAS_GLARE"

4. **User Cancellation:**
   - Start capture → cancel → expect "USER_CANCELED"
   - Capture front → cancel back prompt → expect "USER_CANCELED"

5. **Different Document Types:**
   - Test with ID card (front+back)
   - Test with passport (front only)
   - Test with driver license (front+back)

---

## Limitations

1. **No Barcode-Only Capture:** Barcode is read during document capture, but there's no separate "capture barcode only" method. This is intentional - keeps API simple.

2. **No Manual Crop:** SDK handles crop automatically. User cannot adjust crop. This is pragmatic - auto-crop works well 99% of the time.

3. **No Classification Feedback Loop:** If SDK misclassifies document (e.g., detects ID as passport), user cannot override. They must retake. This is a limitation of the simplified API.

4. **No Batch Processing:** One document at a time. For multiple documents, call method multiple times. This is intentional - keeps state management simple.

5. **No Offline Mode:** OCR requires network call to Acuant servers. Cannot process offline. This is an Acuant SDK limitation, not our choice.

---

## Comparison with Phase 1

| Aspect | Phase 1 (Face) | Phase 2 (Document) |
|--------|----------------|-------------------|
| Methods | 3 (capture, liveness, match) | 1 (captureAndProcess) |
| Steps | User calls 3 methods | SDK handles all steps |
| UI | Modal camera | Modal camera + prompt |
| Processing | Synchronous (local) | Async (server call) |
| Data Size | ~50KB per image | ~100KB per document (2 images) |
| Error Cases | 5 main errors | 7 main errors |
| Lines (iOS) | ~200 | ~250 |
| Lines (Android) | ~200 | ~200 |

**Insight:** Phase 2 is actually SIMPLER from user perspective (1 method vs 3), but MORE COMPLEX internally (multi-step workflow). This is good design - hide complexity from user.

---

## Future Enhancements (Not Implemented)

### Potential Phase 3 Features:

1. **Batch Mode:** Capture multiple documents in one session
2. **Manual Crop:** Allow user to adjust crop before processing
3. **Classification Override:** Let user specify document type if SDK wrong
4. **Offline OCR:** Use local OCR library for basic extraction
5. **Partial Results:** Return images immediately, OCR data later

**Linus Says:** Don't implement these unless users demand them. Solve real problems, not imaginary ones.

---

## Conclusion

Phase 2 delivers document scanning with **ONE simple method**. User calls `captureAndProcessDocument()`, gets back images + OCR data. Done.

No special cases. No nested data. No multi-step state management. Just works.

This is "good taste" software design.

---

**Signed:** A disciple of Linus Torvalds
**Motto:** "Talk is cheap. Show me the code."
