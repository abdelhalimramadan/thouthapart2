# Doctor Profile Update - QA Checklist

## Test Environment
- **App**: thotha_mobile_app (Flutter)
- **Screen**: Doctor Profile Screen (`DoctorProfileScreen`)
- **Feature**: Retrieve, Edit, Validate, and Update Doctor Profile
- **Date**: March 13, 2026

---

## 1. DATA RETRIEVAL & DISPLAY
### Scenario 1.1: Profile Loads All 8 Fields Correctly
**Precondition**: User is logged in with valid JWT token containing `doctor_id`

**Steps**:
1. Navigate to Profile Screen (Doctor Profile)
2. Wait for data to load
3. Verify all 8 fields are populated:
   - [ ] Email (Arabic RTL text, LTR input)
   - [ ] First Name (Arabic RTL)
   - [ ] Last Name (Arabic RTL)
   - [ ] Phone Number (LTR, numeric)
   - [ ] University (Arabic RTL, from dropdown list)
   - [ ] Study Year (Arabic RTL, from dropdown list)
   - [ ] Governorate/City (Arabic RTL, from dropdown list)
   - [ ] Category/Specialization (Arabic RTL, from dropdown list)

**Expected Result**: 
- All fields display loaded data without truncation
- No loading spinner visible after data loads
- Fields are in correct text direction (RTL for Arabic, LTR for Email/Phone)

**Actual Result**: ___________

**Status**: ✅ Pass / ❌ Fail

---

### Scenario 1.2: Profile Loads from Cache When API Fails
**Precondition**: Disconnect internet or mock API failure

**Steps**:
1. Navigate to Profile Screen
2. Verify fallback to cached data
3. Confirm all 8 fields still display (from cache)

**Expected Result**:
- Fields populate from local SharedPreferences cache
- No error message displayed if cache is valid
- App remains responsive

**Actual Result**: ___________

**Status**: ✅ Pass / ❌ Fail

---

## 2. FIELD EDITING & CHANGE DETECTION
### Scenario 2.1: Save Button Disabled on Initial Load
**Precondition**: Profile loaded with no edits

**Steps**:
1. Observe Save button color and state
2. Verify button is NOT clickable

**Expected Result**:
- Save button has gray gradient (disabled state)
- Button text "حفظ" is grayed out
- OnTap is null/disabled

**Actual Result**: ___________

**Status**: ✅ Pass / ❌ Fail

---

### Scenario 2.2: Save Button Enabled After Single Field Change
**Precondition**: Profile loaded, no previous edits

**Steps**:
1. Click edit icon next to "First Name"
2. Focus on first name input field
3. Type "Test Name"
4. Observe Save button

**Expected Result**:
- Save button color changes to blue gradient (enabled)
- Button becomes clickable
- Button shows no spinner

**Actual Result**: ___________

**Status**: ✅ Pass / ❌ Fail

---

### Scenario 2.3: Reverting Changes Disables Save Button
**Precondition**: First Name was edited to "Test Name"

**Steps**:
1. Clear the first name field
2. Type original name back
3. Observe Save button

**Expected Result**:
- Save button returns to gray (disabled)
- Button becomes non-clickable again

**Actual Result**: ___________

**Status**: ✅ Pass / ❌ Fail

---

## 3. INPUT VALIDATION
### Scenario 3.1: First Name Validation - Minimum Length
**Precondition**: Profile loaded

**Steps**:
1. Click edit icon for First Name
2. Clear field completely
3. Type single character "أ"
4. Click Save button

**Expected Result**:
- Red SnackBar appears with Arabic message: "يرجى إدخال الاسم الأول بشكل صحيح"
- Save does NOT execute
- Profile data unchanged

**Actual Result**: ___________

**Status**: ✅ Pass / ❌ Fail

---

### Scenario 3.2: Last Name Validation - Minimum Length
**Precondition**: Profile loaded

**Steps**:
1. Click edit icon for Last Name
2. Clear field
3. Type empty or single char
4. Click Save button

**Expected Result**:
- Red SnackBar with Arabic message: "يرجى إدخال اسم العائلة بشكل صحيح"
- Save blocked

**Actual Result**: ___________

**Status**: ✅ Pass / ❌ Fail

---

### Scenario 3.3: Email Validation - Invalid Format
**Precondition**: Profile loaded

**Steps**:
1. Click email field
2. Change email to invalid format (e.g., "notanemail" without @)
3. Click Save

**Expected Result**:
- Red SnackBar: "يرجى إدخال بريد إلكتروني صحيح"
- Save blocked
- Field retains entered text for user correction

**Actual Result**: ___________

**Status**: ✅ Pass / ❌ Fail

---

### Scenario 3.4: Email Validation - Valid Format
**Precondition**: Profile loaded, email field selected

**Steps**:
1. Change email to valid format: "doctor@hospital.com"
2. Keep all other fields unchanged
3. Click Save

**Expected Result**:
- Validation passes (no error message)
- Save executes (spinner shows)
- Green success SnackBar appears: "Profile Updated Successfully"

**Actual Result**: ___________

**Status**: ✅ Pass / ❌ Fail

---

### Scenario 3.5: Phone Validation - Invalid Format
**Precondition**: Profile loaded

**Steps**:
1. Click phone field
2. Enter invalid phone (e.g., "123" - too short)
3. Click Save

**Expected Result**:
- Red SnackBar: "يرجى إدخال رقم هاتف صحيح"
- Save blocked

**Actual Result**: ___________

**Status**: ✅ Pass / ❌ Fail

---

### Scenario 3.6: Phone Validation - Valid Formats
**Precondition**: Profile loaded

**Steps**:
1. Test each valid phone format:
   - [ ] 10 digits: "0201034567890"
   - [ ] With spaces: "020 103 45678"
   - [ ] With dashes: "020-103-45678"
   - [ ] With +: "+2020103456789"
2. Click Save for each

**Expected Result**:
- All formats pass validation
- Save executes successfully

**Actual Result**: ___________

**Status**: ✅ Pass / ❌ Fail

---

### Scenario 3.7: Required Field Validation - University Empty
**Precondition**: Profile loaded, University was selected before

**Steps**:
1. Click edit icon for University
2. In dialog, do NOT select any item
3. Close dialog by back button
4. University should be empty
5. Click Save

**Expected Result**:
- Red SnackBar: "يرجى اختيار الجامعة"
- Save blocked

**Actual Result**: ___________

**Status**: ✅ Pass / ❌ Fail

---

### Scenario 3.8: Required Field Validation - All Dropdowns Empty
**Precondition**: Profile loaded

**Steps**:
1. Clear all 4 dropdown fields (University, Year, City, Category) via dialogs
2. Clear all text fields (keeping valid values temporarily)
3. Click Save without filling any required field

**Expected Result**:
- First missing field error shown (in order: firstName, lastName, email, phone, university, year, city, category)
- Save blocked

**Actual Result**: ___________

**Status**: ✅ Pass / ❌ Fail

---

## 4. SAVE & API INTERACTION
### Scenario 4.1: All 8 Fields Send in Request Payload
**Precondition**: Profile loaded, all fields valid

**Steps**:
1. Edit each of 8 fields (small change to each)
2. Click Save button
3. Monitor network request (e.g., with proxy or logs)

**Expected Result**:
- PUT request to `/api/doctor/updateDoctor` includes:
  ```json
  {
    "id": <doctorId>,
    "doctorId": <doctorId>,
    "firstName": "...",
    "lastName": "...",
    "email": "...",
    "phoneNumber": "...",
    "universityName": "...",
    "studyYear": "...",
    "cityName": "...",
    "categoryName": "..."
  }
  ```

**Actual Result**: ___________

**Status**: ✅ Pass / ❌ Fail

---

### Scenario 4.2: Save Shows Spinner While Loading
**Precondition**: Profile loaded, valid changes made

**Steps**:
1. Add network delay (throttle to slow 3G)
2. Click Save
3. Observe button immediately

**Expected Result**:
- Save button shows circular spinner (white, 20x20 size)
- Button remains disabled during request
- Button text "حفظ" hidden behind spinner

**Actual Result**: ___________

**Status**: ✅ Pass / ❌ Fail

---

### Scenario 4.3: Save Success - Green SnackBar with Arabic Message
**Precondition**: Valid changes, save clicked

**Steps**:
1. Wait for network response (success 200-201)
2. Observe feedback

**Expected Result**:
- Green SnackBar appears with: "Profile Updated Successfully"
- Floating/bottom navigation style
- Auto-dismisses after ~2-3 seconds
- All fields refreshed with returned data

**Actual Result**: ___________

**Status**: ✅ Pass / ❌ Fail

---

### Scenario 4.4: Save Failure - Red SnackBar with Error Message
**Precondition**: Setup to mock API error (e.g., 403 Forbidden)

**Steps**:
1. Make valid changes
2. Click Save
3. Wait for error response

**Expected Result**:
- Red SnackBar appears with error message (e.g., "ممنوع الوصول: تأكد من صلاحياتك")
- Spinner removed from button
- Save button returns to enabled state
- User can retry

**Actual Result**: ___________

**Status**: ✅ Pass / ❌ Fail

---

## 5. DATA PERSISTENCE & CACHING
### Scenario 5.1: Updated Data Persists in Local Cache
**Precondition**: Profile updated and saved successfully

**Steps**:
1. Note new email: "newemail@hospital.eg"
2. Save successfully (green SnackBar)
3. Navigate away from profile
4. Return to profile screen

**Expected Result**:
- Email field displays new value immediately (from cache)
- No need to wait for API re-fetch

**Actual Result**: ___________

**Status**: ✅ Pass / ❌ Fail

---

### Scenario 5.2: Multiple Field Updates Atomic
**Precondition**: Profile loaded

**Steps**:
1. Change firstName to "أحمد"
2. Change lastName to "محمد"
3. Change email to "ahmad@test.com"
4. Save

**Expected Result**:
- All 3 fields update in DB atomically (single request)
- LocalCache updated with all 3 simultaneously
- No partial updates

**Actual Result**: ___________

**Status**: ✅ Pass / ❌ Fail

---

### Scenario 5.3: No Data Loss on Concurrent Edits
**Precondition**: Profile loaded

**Steps**:
1. Edit firstName
2. Edit lastName (while firstName value still in memory)
3. Edit email
4. Save

**Expected Result**:
- All 3 edits sent together
- No values overwritten or lost
- DB contains all new values

**Actual Result**: ___________

**Status**: ✅ Pass / ❌ Fail

---

## 6. SELECTION DIALOGS
### Scenario 6.1: Dropdown Dialog Preserves Searched Text
**Precondition**: Profile loaded, University field visible

**Steps**:
1. Click edit icon for University
2. Dialog opens with search field
3. Type university name (e.g., "القاهرة")
4. Observe filtered list
5. Tap university to select

**Expected Result**:
- Search field show typed text
- List filters in real-time
- Selection updates University field
- Dialog closes

**Actual Result**: ___________

**Status**: ✅ Pass / ❌ Fail

---

### Scenario 6.2: Selection Persists in Controller
**Precondition**: University selected from dialog

**Steps**:
1. Select "جامعة القاهرة"
2. Close dialog
3. Click edit icon again
4. Open same dialog

**Expected Result**:
- Previous selection still highlighted/visible
- Can select different university or confirm

**Actual Result**: ___________

**Status**: ✅ Pass / ❌ Fail

---

### Scenario 6.3: All 4 Dropdowns Have Correct Items
**Precondition**: Profile loaded

**Steps**:
1. Click edit for Study Year dropdown
   - [ ] Verify all 7 years: الأولى, الثانية, الثالثة, الرابعة, الخامسة, امتياز, مزاول
2. Click edit for Governorate dropdown
   - [ ] Verify Egyptian governorates appear
3. Click edit for University dropdown
   - [ ] Verify universities loaded from API
4. Click edit for Category dropdown
   - [ ] Verify medical specializations appear

**Expected Result**:
- All dropdowns show correct options
- No duplicates
- Arabic text renders correctly

**Actual Result**: ___________

**Status**: ✅ Pass / ❌ Fail

---

## 7. UI/UX FLOW
### Scenario 7.1: RTL/LTR Text Direction Correct
**Precondition**: Profile loaded

**Steps**:
1. Observe First Name field (Arabic)
   - [ ] Text aligned right
   - [ ] Cursor starts from right
2. Observe Email field (email format)
   - [ ] Text aligned left
   - [ ] Cursor at left
3. Observe Phone field (numbers)
   - [ ] Text aligned left

**Expected Result**:
- Arabic fields: RTL (right-to-left)
- Email/Phone fields: LTR (left-to-right)

**Actual Result**: ___________

**Status**: ✅ Pass / ❌ Fail

---

### Scenario 7.2: Edit Icons Visible and Responsive
**Precondition**: Profile loaded

**Steps**:
1. Observe each of 8 fields
2. Verify blue edit icon (pencil) appears next to label
3. Tap edit icon

**Expected Result**:
- Edit icon shows blue gradient color
- Icon tappable and responsive
- Tapping focuses input or opens dialog

**Actual Result**: ___________

**Status**: ✅ Pass / ❌ Fail

---

### Scenario 7.3: Bottom Navigation Bar Layout
**Precondition**: Profile loaded, scrolled to bottom

**Steps**:
1. Observe Save button
2. Observe Change Password button
3. Observe Delete Account button
4. Check spacing and alignment

**Expected Result**:
- Save button (gradient blue) at top
- Change Password button (outline) below
- Delete Account button (outline red) below
- All buttons full-width with proper spacing
- No overlap

**Actual Result**: ___________

**Status**: ✅ Pass / ❌ Fail

---

## 8. ERROR SCENARIOS & EDGE CASES
### Scenario 8.1: Network Timeout Handling
**Precondition**: Slow network (>15s timeout)

**Steps**:
1. Make valid changes
2. Click Save
3. Wait >15 seconds without response

**Expected Result**:
- Error message appears: "انتهت مهلة الاتصال. تحقق من الإنترنت"
- Save button returns to enabled state
- User can retry

**Actual Result**: ___________

**Status**: ✅ Pass / ❌ Fail

---

### Scenario 8.2: No Internet Connection
**Precondition**: Device offline

**Steps**:
1. Make changes
2. Click Save

**Expected Result**:
- Error message: "تعذر الاتصال بالخادم. تحقق من الإنترنت"
- Save button enabled for retry
- UI remains responsive

**Actual Result**: ___________

**Status**: ✅ Pass / ❌ Fail

---

### Scenario 8.3: Server 500 Error
**Precondition**: Mock API returns 500

**Steps**:
1. Make valid changes
2. Click Save
3. Wait for 500 response

**Expected Result**:
- Error message: "خطأ في الخادم (500)"
- Save button enabled for retry
- User data not cleared

**Actual Result**: ___________

**Status**: ✅ Pass / ❌ Fail

---

### Scenario 8.4: 401 Unauthorized (Token Expired)
**Precondition**: Setup mock 401 response

**Steps**:
1. Make changes
2. Click Save with expired token

**Expected Result**:
- Error message: "غير مصرح: يرجى تسجيل الدخول مجدداً (401)"
- Save button enabled
- User prompted to retry or re-login

**Actual Result**: ___________

**Status**: ✅ Pass / ❌ Fail

---

### Scenario 8.5: Empty Response from API
**Precondition**: API returns empty body

**Steps**:
1. Setup mock to return 200 but empty payload
2. Make valid changes and save

**Expected Result**:
- Error message displayed (or generic success if 200)
- App doesn't crash
- User notified of unexpected response

**Actual Result**: ___________

**Status**: ✅ Pass / ❌ Fail

---

## 9. INTEGRATION WITH OTHER SCREENS
### Scenario 9.1: Updated Name Reflects in Drawer
**Precondition**: Doctor Home Screen drawer visible before profile update

**Steps**:
1. Open drawer, note doctor name
2. Navigate to Profile Screen
3. Update first name
4. Save successfully
5. Return to Doctor Home
6. Open drawer

**Expected Result**:
- Doctor name in drawer updated to new name immediately
- Used cached `first_name` value from SharedPreferences

**Actual Result**: ___________

**Status**: ✅ Pass / ❌ Fail

---

### Scenario 9.2: Updated Category Reflects in Category Selection
**Precondition**: Doctor Home, Category selection screen visible

**Steps**:
1. Note current category in Category Doctors Screen
2. Go to Profile, update category
3. Save successfully
4. Return to category screen

**Expected Result**:
- Category field shows new value
- Requests filtered by new category if applicable

**Actual Result**: ___________

**Status**: ✅ Pass / ❌ Fail

---

## 10. RESPONSIVE DESIGN
### Scenario 10.1: Small Screen (Phone Portrait)
**Precondition**: Device in portrait mode, small screen (~375px width)

**Steps**:
1. Open Profile Screen
2. Scroll through all fields
3. Test editing a field
4. Verify all text visible and input accessible

**Expected Result**:
- All fields fit without horizontal scrolling
- Text wraps appropriately
- Buttons clickable without overlap
- Keyboard doesn't hide critical UI

**Actual Result**: ___________

**Status**: ✅ Pass / ❌ Fail

---

### Scenario 10.2: Large Screen (Tablet Landscape)
**Precondition**: Device in landscape, 1000px+

**Steps**:
1. Open Profile
2. Verify layout adapts to large screen
3. No excessive spacing

**Expected Result**:
- UI scales appropriately
- No wasted space
- All elements visible without excessive scrolling

**Actual Result**: ___________

**Status**: ✅ Pass / ❌ Fail

---

## SUMMARY

| Category | Tests | Passed | Failed |
|----------|-------|--------|--------|
| Data Retrieval & Display | 2 | __ | __ |
| Field Editing & Change Detection | 3 | __ | __ |
| Input Validation | 8 | __ | __ |
| Save & API Interaction | 4 | __ | __ |
| Data Persistence & Caching | 3 | __ | __ |
| Selection Dialogs | 3 | __ | __ |
| UI/UX Flow | 3 | __ | __ |
| Error Scenarios & Edge Cases | 5 | __ | __ |
| Integration with Other Screens | 2 | __ | __ |
| Responsive Design | 2 | __ | __ |
| **TOTAL** | **35** | __ | __ |

### Overall Status: ___________

### Critical Issues Found:
1. ___________
2. ___________
3. ___________

### Notes:
___________
___________

---

**Tested By**: ___________
**Date**: ___________
**Environment**: ___________
**Build**: ___________
