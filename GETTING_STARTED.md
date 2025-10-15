# Getting Started - Face Verification Testing

Quick guide for testing face liveness detection and face matching.

---

## What You Need

### 1. Acuant API Credentials
Get from Acuant (https://www.acuant.com):
- **Username**
- **Password**
- **Subscription ID**

### 2. API Endpoints (by region)
SDK connects to these Acuant cloud servers:

**USA (default):**
- https://us.passlive.acuant.net (Liveness)
- https://frm.acuant.net (Face Match)

**EU:**
- https://eu.passlive.acuant.net
- https://eu.frm.acuant.net

**Australia:**
- https://aus.passlive.acuant.net
- https://aus.frm.acuant.net

*Region is auto-configured when you select it in the app.*

### 3. Hardware
- Mobile device with camera
- Internet connection

### 4. Test Materials
- A person to take selfie (for liveness check)
- A reference photo to compare against (ID photo, stored image, etc.)

---

## Quick Setup

```bash
cd example
./setup.sh
yarn ios    # or yarn android
```

---

## Testing Steps

1. **Open app** → Tap **⚙️ Configure**
2. **Enter credentials** (username, password, subscription ID)
3. **Select region** (USA/EU/AUS)
4. **Tap "Initialize SDK"** → Connects to Acuant servers
5. **Tap "Capture Face"** → Take selfie
6. **Tap "Process Liveness"** → Verifies person is live (3-8 seconds)
7. **Tap "Select ID & Match"** → Compare against stored photo

---

## Expected Results

✅ **Liveness:** "Live" with score >80
✅ **Face Match:** Score >75 for same person
⏱️ **Total time:** ~10-15 seconds

---

## Common Issues

| Problem | Fix |
|---------|-----|
| Initialization fails | Check credentials, internet, and region |
| "NOT_LIVE" result | Ensure real person, good lighting, no screen photos |
| Low match score | Use clear, frontal face photos with similar lighting |
| Network timeout | Check firewall allows access to Acuant endpoints above |

---

## Support

- **Logs:** Tap "Copy Logs" in app
- **Acuant Support:** https://support.acuant.com
- **Documentation:** See `/docs/PHASE1_API_DESIGN.md`
