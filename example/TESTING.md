# Testing Checklist

Comprehensive test scenarios for the Acuant SDK Example App.

## Prerequisites Checklist

- [ ] Valid Acuant credentials obtained
- [ ] iOS device or simulator with camera access
- [ ] Android device or emulator with camera access
- [ ] Network connectivity
- [ ] Permissions granted (camera, storage)

---

## Configuration Tests

### TC-001: Initial Configuration
- [ ] Launch app for the first time
- [ ] Verify no crash on launch
- [ ] Tap "⚙️ Config" button
- [ ] Configuration modal opens
- [ ] All fields are empty by default
- [ ] Can type in all input fields
- [ ] Region selector shows all options (USA, EU, AUS, PREVIEW)

### TC-002: Valid Configuration Save
- [ ] Open configuration modal
- [ ] Enter valid username
- [ ] Enter valid password
- [ ] Enter valid subscription ID
- [ ] Select a region
- [ ] Tap "Save"
- [ ] Modal closes
- [ ] Log entry appears: "Configuration saved"

### TC-003: Configuration Persistence (Session)
- [ ] Configure credentials
- [ ] Tap "Save"
- [ ] Reset the app state (🔄 Reset button)
- [ ] Verify configuration is retained during session
- [ ] Note: Config is NOT persisted across app restarts (by design)

### TC-004: Configuration Modal Cancel
- [ ] Open configuration modal
- [ ] Enter some values
- [ ] Tap "Cancel"
- [ ] Modal closes
- [ ] Values are not saved

---

## SDK Initialization Tests

### TC-101: Initialize with Valid Credentials
- [ ] Configure valid credentials
- [ ] Tap "Initialize SDK"
- [ ] Button shows "⏳ Loading..."
- [ ] Success log appears
- [ ] "Initialized" status indicator turns green
- [ ] "Initialize SDK" button becomes disabled
- [ ] "Capture Face" button becomes enabled

### TC-102: Initialize without Configuration
- [ ] Launch fresh app (no config)
- [ ] Tap "Initialize SDK"
- [ ] Alert appears: "Configuration Required"
- [ ] Configuration modal opens automatically

### TC-103: Initialize with Invalid Credentials
- [ ] Configure with invalid username/password
- [ ] Tap "Initialize SDK"
- [ ] Error log appears with details
- [ ] Alert shows error message
- [ ] "Initialized" status remains gray
- [ ] Can retry initialization

### TC-104: Initialize with Wrong Region
- [ ] Configure with valid credentials
- [ ] Select wrong region
- [ ] Tap "Initialize SDK"
- [ ] Should fail with region/endpoint error
- [ ] Error is logged clearly

### TC-105: Double Initialize
- [ ] Initialize SDK successfully
- [ ] "Initialize SDK" button should be disabled
- [ ] Cannot initialize twice

---

## Face Capture Tests

### TC-201: Capture Face Success
- [ ] Initialize SDK
- [ ] Tap "Capture Face"
- [ ] Camera UI launches
- [ ] Oval guide is visible
- [ ] Capture completes (or auto-captures after 2 seconds)
- [ ] Camera UI closes
- [ ] Face image appears in preview
- [ ] "Face Captured" status indicator turns green
- [ ] Log shows image size in KB
- [ ] "Process Liveness" button becomes enabled
- [ ] "Face Match" button becomes enabled

### TC-202: Capture Face without Initialization
- [ ] Launch app (SDK not initialized)
- [ ] "Capture Face" button should be disabled
- [ ] Cannot tap button

### TC-203: Capture Face User Cancel
- [ ] Initialize SDK
- [ ] Tap "Capture Face"
- [ ] Camera UI launches
- [ ] Cancel/dismiss the camera
- [ ] Log shows: "Face capture cancelled by user"
- [ ] No error alert shown
- [ ] Can retry capture

### TC-204: Capture Face Permission Denied (iOS)
- [ ] iOS Settings → Acuant SDK Example → Camera → OFF
- [ ] Initialize SDK
- [ ] Tap "Capture Face"
- [ ] System permission alert should appear
- [ ] Deny permission
- [ ] Error is logged
- [ ] Alert shows permission error

### TC-205: Capture Face Permission Denied (Android)
- [ ] Android Settings → Apps → Acuant SDK Example → Permissions → Camera → Deny
- [ ] Initialize SDK
- [ ] Tap "Capture Face"
- [ ] Permission request dialog appears
- [ ] Deny permission
- [ ] Error is logged
- [ ] Alert shows permission error

### TC-206: Capture Face in Low Light
- [ ] Initialize SDK
- [ ] Cover camera or use very dark environment
- [ ] Tap "Capture Face"
- [ ] Camera UI should still work
- [ ] Capture may succeed but quality may affect liveness
- [ ] Note behavior in logs

### TC-207: Multiple Face Captures
- [ ] Capture first face
- [ ] Capture second face (overwrites first)
- [ ] Preview shows latest face
- [ ] Previous capture is replaced

---

## Passive Liveness Tests

### TC-301: Process Liveness with Good Face
- [ ] Capture a clear, well-lit face image
- [ ] Tap "Process Liveness"
- [ ] Button shows "⏳ Loading..."
- [ ] Processing completes
- [ ] Result shows: Assessment = "Live"
- [ ] Score is displayed (e.g., 0.9xx)
- [ ] "Liveness" status indicator turns green
- [ ] Log shows success with score

### TC-302: Process Liveness without Face Capture
- [ ] Initialize SDK (don't capture face)
- [ ] "Process Liveness" button should be disabled
- [ ] Cannot process without face

### TC-303: Process Liveness with Poor Quality
- [ ] Capture a blurry or dark image
- [ ] Tap "Process Liveness"
- [ ] May return "PoorQuality" assessment
- [ ] Or may return "NotLive"
- [ ] Result is logged clearly

### TC-304: Process Liveness with No Face
- [ ] Capture image with no face (e.g., wall, object)
- [ ] Tap "Process Liveness"
- [ ] Should return error or "NotLive"
- [ ] Error details in logs

### TC-305: Process Liveness Error Handling
- [ ] Disconnect network
- [ ] Capture face
- [ ] Tap "Process Liveness"
- [ ] Network error should be caught
- [ ] Error logged clearly
- [ ] Alert shows error
- [ ] Can retry after network restored

### TC-306: Liveness with Multiple Faces
- [ ] Capture image with multiple faces
- [ ] Tap "Process Liveness"
- [ ] Observe behavior (may error or process one face)
- [ ] Log error details

---

## Face Match Tests

### TC-401: Face Match Same Image (Demo)
- [ ] Capture face
- [ ] Tap "Face Match"
- [ ] Button shows "⏳ Loading..."
- [ ] Processing completes
- [ ] Result shows: Match = "YES"
- [ ] Score is very high (close to 1.0)
- [ ] "Match" status indicator turns green
- [ ] Log shows match success

### TC-402: Face Match without Face Capture
- [ ] Initialize SDK (don't capture face)
- [ ] "Face Match" button should be disabled
- [ ] Cannot process without face

### TC-403: Face Match Error Handling
- [ ] Disconnect network
- [ ] Capture face
- [ ] Tap "Face Match"
- [ ] Network error should be caught
- [ ] Error logged clearly
- [ ] Alert shows error
- [ ] Can retry after network restored

### TC-404: Face Match Poor Quality
- [ ] Capture very blurry face
- [ ] Tap "Face Match"
- [ ] Should still return result
- [ ] Score may be lower
- [ ] Or may error due to quality

---

## Full Workflow Tests

### TC-501: Happy Path Full Workflow
- [ ] Configure valid credentials
- [ ] Tap "▶️ Run Full Workflow"
- [ ] SDK initializes automatically
- [ ] Camera launches for face capture
- [ ] Capture face
- [ ] Liveness processes automatically
- [ ] Face match processes automatically
- [ ] Log shows: "=== Starting Full Workflow ==="
- [ ] Log shows: "=== Workflow Complete ==="
- [ ] All status indicators are green
- [ ] All results are displayed

### TC-502: Full Workflow with Cancellation
- [ ] Configure valid credentials
- [ ] Tap "▶️ Run Full Workflow"
- [ ] Cancel during face capture
- [ ] Workflow stops
- [ ] Log shows cancellation
- [ ] Can retry

### TC-503: Full Workflow without Configuration
- [ ] Launch fresh app
- [ ] Tap "▶️ Run Full Workflow"
- [ ] Alert: "Configuration Required"
- [ ] Configuration modal opens

### TC-504: Full Workflow Network Failure
- [ ] Disconnect network
- [ ] Tap "▶️ Run Full Workflow"
- [ ] Initialization fails
- [ ] Error logged
- [ ] Workflow stops

### TC-505: Full Workflow Already Initialized
- [ ] Initialize SDK manually
- [ ] Tap "▶️ Run Full Workflow"
- [ ] Should skip initialization
- [ ] Proceeds directly to face capture

---

## UI and State Management Tests

### TC-601: Status Indicators
- [ ] All indicators start gray
- [ ] "Initialized" turns green after initialization
- [ ] "Face Captured" turns green after capture
- [ ] "Liveness" turns green only if assessment = "Live"
- [ ] "Match" turns green only if match = true

### TC-602: Button States
- [ ] "Initialize SDK" enabled only when configured and not initialized
- [ ] "Capture Face" enabled only when initialized
- [ ] "Process Liveness" enabled only when face is captured
- [ ] "Face Match" enabled only when face is captured
- [ ] "Run Full Workflow" enabled only when configured
- [ ] All buttons disabled during loading

### TC-603: Loading States
- [ ] During any operation, button shows "⏳ Loading..."
- [ ] All other buttons are disabled during loading
- [ ] UI remains responsive (doesn't freeze)

### TC-604: Image Preview
- [ ] No image shown initially
- [ ] After capture, image appears in preview
- [ ] Image is clear and properly sized
- [ ] Image maintains aspect ratio
- [ ] Replacing face updates preview

### TC-605: Results Display
- [ ] No results shown initially
- [ ] Liveness result appears after processing
- [ ] Match result appears after processing
- [ ] Results show correct values
- [ ] Color coding: green for success, red for failure

### TC-606: Reset Functionality
- [ ] Execute some workflow steps
- [ ] Tap "🔄 Reset"
- [ ] All status indicators turn gray
- [ ] Image preview disappears
- [ ] Results disappear
- [ ] Logs are cleared
- [ ] Configuration is retained
- [ ] Can start workflow again

---

## Logging Tests

### TC-701: Log Entries
- [ ] Each operation adds a log entry
- [ ] Log shows timestamp
- [ ] Log shows clear message
- [ ] Errors are in red
- [ ] Success is in green
- [ ] Info is in default color

### TC-702: Log Expansion
- [ ] Logs section shows count: "Logs (0)"
- [ ] Initially collapsed (shows ▶️)
- [ ] Tap arrow to expand (shows ▼)
- [ ] All logs are visible
- [ ] Tap arrow to collapse
- [ ] Logs are hidden

### TC-703: Log Copy
- [ ] Add some logs
- [ ] Expand logs section
- [ ] Tap 📋 button
- [ ] Logs are copied to clipboard (verify by pasting elsewhere)
- [ ] Format: "[timestamp] message"

### TC-704: Log Clear
- [ ] Add some logs
- [ ] Expand logs section
- [ ] Tap 🗑️ button
- [ ] All logs disappear
- [ ] Count shows: "Logs (0)"
- [ ] Message: "No logs yet"

### TC-705: Log Scroll
- [ ] Execute many operations to generate 20+ logs
- [ ] Expand logs section
- [ ] Logs section is scrollable
- [ ] Can scroll to see all entries
- [ ] Most recent logs appear at top

---

## Error Handling Tests

### TC-801: Network Timeout
- [ ] Use slow/unstable network
- [ ] Try SDK operations
- [ ] Timeout errors are caught
- [ ] Clear error messages in logs and alerts

### TC-802: Invalid Image Data
- [ ] (Requires code modification to inject bad data)
- [ ] SDK should reject invalid data
- [ ] Error is logged clearly

### TC-803: Repeated Errors
- [ ] Trigger same error multiple times
- [ ] Each error is logged
- [ ] App remains stable
- [ ] No crashes

### TC-804: Rapid Button Taps
- [ ] Tap buttons very quickly
- [ ] Buttons should be disabled during processing
- [ ] Only one operation runs at a time
- [ ] No race conditions

---

## Platform-Specific Tests

### TC-901: iOS Specific
- [ ] Test on multiple iOS versions (14, 15, 16, 17)
- [ ] Test on iPhone and iPad
- [ ] Camera rotations work correctly
- [ ] Status bar appears correctly
- [ ] No UI glitches in dark mode

### TC-902: Android Specific
- [ ] Test on multiple Android versions (10, 11, 12, 13, 14)
- [ ] Test on phones and tablets
- [ ] Test on different screen sizes
- [ ] Back button behavior (should minimize app)
- [ ] Camera permissions work correctly

---

## Performance Tests

### TC-1001: Memory Usage
- [ ] Run full workflow 10 times
- [ ] Check for memory leaks
- [ ] App should remain responsive

### TC-1002: Response Times
- [ ] Initialization: < 5 seconds
- [ ] Face capture: Interactive
- [ ] Liveness processing: < 10 seconds
- [ ] Face match: < 10 seconds

---

## Regression Tests

After any code changes, run:
- [ ] TC-101: Basic initialization
- [ ] TC-201: Basic face capture
- [ ] TC-301: Basic liveness
- [ ] TC-401: Basic face match
- [ ] TC-501: Full workflow
- [ ] TC-606: Reset functionality
- [ ] Verify no crashes
- [ ] Verify all logs are clear

---

## Notes

- **Expected Failures**: Some test cases are designed to trigger errors (e.g., invalid credentials, permission denied). These should fail gracefully with clear error messages.
- **Test Environment**: Some tests require specific conditions (network off, permissions denied, etc.). Document your test environment.
- **Device Coverage**: Test on at least one iOS device and one Android device. Emulators/simulators are acceptable for most tests but real devices for camera testing.

---

## Test Report Template

```
Test Date: _______________
Tester: _______________
Device: _______________
OS Version: _______________
App Version: _______________

Test Cases Executed: ___ / ___
Passed: ___
Failed: ___
Blocked: ___

Critical Issues Found:
1. _______________
2. _______________

Notes:
_______________
```
