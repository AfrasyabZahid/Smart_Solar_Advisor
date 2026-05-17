# Registration Validation Examples

## Quick Reference for Testing

### Username Examples

✅ **Valid Usernames:**
- `john_doe` - starts with letter, contains underscore
- `alice123` - starts with letter, contains numbers
- `User_2024` - mixed case with underscore
- `a` - minimum valid (3 chars actually required)

❌ **Invalid Usernames:**
- `123john` - starts with digit
- `_john` - starts with underscore (special char)
- `@user` - starts with special character
- `user@name` - contains special characters
- `ab` - too short (< 3 chars)
- `this_is_a_very_long_username_that_exceeds_limit` - too long (> 20 chars)

---

### Full Name Examples

✅ **Valid Names:**
- `John Doe` - only letters and space
- `Mary Jane Watson` - multiple spaces
- `A` - single letter
- `Anne Marie` - letters and space

❌ **Invalid Names:**
- `John123` - contains numbers
- `John_Doe` - contains underscore
- `John-Doe` - contains hyphen
- `John@Doe` - contains special character
- `ab` - too short (< 3 chars)

---

### Email Examples

✅ **Valid Emails:**
- `john.doe@gmail.com`
- `user+tag@example.co.uk`
- `contact_me@company.org`
- `simple@mail.com`

❌ **Invalid Emails:**
- `john.doe@` - missing domain
- `@gmail.com` - missing local part
- `john doe@gmail.com` - contains space
- `john@.com` - missing domain name

---

### Password Examples

Requirements: 8+ chars, 1 Upper, 1 lower, 1 digit, 1 special

✅ **Strong Passwords:**
- `SecurePass@123` - has all requirements
- `MyPass!Word2024` - has all requirements  
- `Abc123!@#` - has all requirements
- `Complex$Pass1` - has all requirements

❌ **Weak Passwords:**
- `password` - no uppercase, no digit, no special char
- `Password123` - no special character
- `UPPERCASE123!` - no lowercase
- `lowercasepass!` - no uppercase, no digit
- `Pass123` - too short, no special char
- `Pass@wor` - too short

---

### Password Strength Calculation

```
Requirements met (out of 6):
1. ✓ Length >= 8
2. ✓ Has uppercase (A-Z)
3. ✓ Has lowercase (a-z)
4. ✓ Has digit (0-9)
5. ✓ Has special (!@#$%^&*)

Score Calculation:
- 0-2 requirements → Weak 🔴
- 3-4 requirements → Medium 🟠
- 5-6 requirements → Strong 🟢
```

**Examples:**
- `password` → Score 0/5 → Weak 🔴
- `Password1` → Score 4/5 → Medium 🟠
- `Pass@word1` → Score 5/5 → Strong 🟢

---

### OTP Examples

✅ **Valid OTP:**
- `123456` - 6 digits
- `000000` - all zeros
- `999999` - all nines

❌ **Invalid OTP:**
- `12345` - too short
- `1234567` - too long
- `12345a` - contains letter
- `12 34 56` - contains space
- `` - empty

---

## Testing Workflow

### Test 1: Username Validation
```
Input: "123user"
Expected Error: "Username must start with an alphabet"
Status: ❌ FAILS
```

### Test 2: Full Name Validation
```
Input: "John123"
Expected Error: "Name can only contain letters and spaces"
Status: ❌ FAILS
```

### Test 3: Email Validation
```
Input: "john.doe@gmail.com"
Expected: ✓ Valid
Status: ✅ PASSES
```

### Test 4: Password Strength
```
Input: "SecurePass@123"
Requirements Met: 5/5
Expected Strength: "Strong" 🟢
Status: ✅ PASSES
```

### Test 5: Complete Registration Flow
```
1. Username: "john_doe" → ✓ Valid
2. Full Name: "John Doe" → ✓ Valid
3. Email: "john@example.com" → ✓ Valid
4. Password: "MyPass@2024" → ✓ Valid (Strong)
5. Confirm: "MyPass@2024" → ✓ Match
6. OTP Sent: ✓ Email received
7. OTP Entered: "123456" → ✓ Verified
8. Registration: ✓ Success → Login Screen
```

---

## Error Messages Reference

### Username Errors
- "Username is required"
- "Username must be at least 3 characters"
- "Username must not exceed 20 characters"
- "Username must start with an alphabet"
- "Username can only contain letters, numbers, and underscores"

### Full Name Errors
- "Full name is required"
- "Name must be at least 3 characters"
- "Name must not exceed 50 characters"
- "Name can only contain letters and spaces"

### Email Errors
- "Email is required"
- "Please enter a valid email address"

### Password Errors
- "Password is required"
- "Password must be at least 8 characters"
- "Password must contain at least one uppercase letter"
- "Password must contain at least one lowercase letter"
- "Password must contain at least one digit"
- "Password must contain at least one special character"

### Confirm Password Errors
- "Please confirm your password"
- "Passwords do not match"

### OTP Errors
- "OTP is required"
- "OTP must be 6 digits"
- "OTP must contain only digits"
- "Invalid OTP. Please try again."

---

## How to Verify Each Validation

### In Flutter Inspector / Debug Console:

```dart
// Test username validation
ValidationUtils.validateUsername('123john');
// Output: "Username must start with an alphabet"

ValidationUtils.validateUsername('john_doe');
// Output: null (valid)

// Test password strength
ValidationUtils.getPasswordStrength('SecurePass@123');
// Output: "Strong"

ValidationUtils.getPasswordStrength('password');
// Output: "Weak"
```

---

## Environment Setup for Email Testing

If using Gmail:

1. Enable 2-Factor Authentication
2. Generate App Password (NOT regular password)
3. Update `lib/services/otp_service.dart`:
   ```dart
   static const String _senderEmail = 'your.email@gmail.com';
   static const String _senderPassword = 'xxxx xxxx xxxx xxxx'; // 16 chars
   ```
4. Test by registering with a test account
5. Check email inbox for OTP

