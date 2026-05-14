# Smart Solar Advisor - Registration System Setup Guide

## Overview
This guide explains how to set up and use the new registration system with OTP email verification.

## Features Implemented

### 1. Username Validation
- **Must start with an alphabet** (a-z, A-Z)
- Can contain letters, numbers, and underscores
- 3-20 characters long
- Example: `john_doe23` ✓, `123john` ✗, `john@doe` ✗

### 2. Full Name Validation
- **Only letters and spaces allowed**
- No special characters or digits
- 3-50 characters long
- Example: `John Doe` ✓, `John123` ✗

### 3. Email Validation
- Standard email format validation
- Verified via OTP sent to the email address
- Example: `john.doe@gmail.com` ✓

### 4. Password Strength Requirements
All of the following are **mandatory**:
- **Minimum 8 characters**
- **At least 1 uppercase letter** (A-Z)
- **At least 1 lowercase letter** (a-z)
- **At least 1 digit** (0-9)
- **At least 1 special character** (!@#$%^&*(),.?":{}|<>)

**Password Strength Indicator:**
- 🔴 **Weak**: 0-2 requirements met
- 🟠 **Medium**: 3-4 requirements met
- 🟢 **Strong**: 5+ requirements met

Example: `SecurePass@123` ✓, `Password123` ✗ (no special char)

### 5. OTP Email Verification
- 6-digit OTP sent to registered email
- Valid for 10 minutes
- Can be resent if expired
- Required to complete registration

## Email Configuration

### Step 1: Set Up Gmail App Password (Recommended)

1. Go to [Google Account Security](https://myaccount.google.com/security)
2. Enable 2-Step Verification if not already enabled
3. Generate an **App Password**:
   - Go to "App passwords" (appears after enabling 2FA)
   - Select "Mail" and "Windows Computer"
   - Copy the generated 16-character password

### Step 2: Update Credentials in Code

Open `lib/services/otp_service.dart` and replace:

```dart
static const String _senderEmail = 'your_email@gmail.com';
static const String _senderPassword = 'your_app_password';
```

**Example:**
```dart
static const String _senderEmail = 'smartsolaradvisor@gmail.com';
static const String _senderPassword = 'abcd efgh ijkl mnop';  // App password
```

### Step 3: Alternative Email Providers

For non-Gmail providers, update the SMTP configuration:

```dart
static const String _smtpServer = 'smtp.gmail.com';  // Change this
static const int _smtpPort = 587;                     // Change if needed
```

**Common SMTP Settings:**
- **Gmail**: `smtp.gmail.com:587`
- **Outlook**: `smtp-mail.outlook.com:587`
- **Yahoo**: `smtp.mail.yahoo.com:587`
- **Custom**: Check your email provider's documentation

## Registration Flow

```
1. User enters registration details
   ├─ Username (validated)
   ├─ Full Name (validated)
   ├─ Email (validated)
   ├─ Password (strength checked)
   └─ Confirm Password (match check)
   
2. User clicks "Continue to Verification"
   ├─ Check if email already exists
   └─ Generate & send OTP via email
   
3. OTP Verification Screen
   ├─ User receives email with OTP
   ├─ User enters 6-digit OTP
   ├─ 10-minute countdown timer
   └─ Option to resend OTP
   
4. Upon successful OTP verification
   └─ User account is created
   └─ Redirect to login screen
```

## File Structure

```
lib/
├── screens/
│   ├── registration_screen.dart       (Updated registration form)
│   └── otp_verification_screen.dart   (New OTP verification)
├── services/
│   └── otp_service.dart               (New SMTP email service)
├── utils/
│   ├── validation.dart                (New validation rules)
│   └── user_preferences.dart          (Updated with username)
└── ...
```

## Validation Rules Summary

| Field | Rules | Error Messages |
|-------|-------|---|
| **Username** | Starts with alphabet, 3-20 chars, alphanumeric + underscore | "Must start with alphabet", "Length 3-20" |
| **Full Name** | Only letters & spaces, 3-50 chars | "Only letters & spaces", "Length 3-50" |
| **Email** | Valid email format | "Invalid email format" |
| **Password** | 8+ chars, 1 upper, 1 lower, 1 digit, 1 special | Specific requirement messages |
| **Confirm Password** | Must match password | "Passwords do not match" |
| **OTP** | 6 digits | "Must be 6 digits" |

## Testing Checklist

- [ ] Username validation (must start with letter)
- [ ] Full name validation (letters and spaces only)
- [ ] Email validation (proper format)
- [ ] Password strength indicator updates
- [ ] Password meets all requirements
- [ ] Confirm password validation
- [ ] OTP email is sent
- [ ] OTP timer countdown works
- [ ] OTP verification succeeds with correct code
- [ ] OTP verification fails with incorrect code
- [ ] Resend OTP works
- [ ] User redirects to login after successful registration

## Troubleshooting

### OTP Not Sent
- Check email credentials in `otp_service.dart`
- Verify Gmail App Password (not regular password)
- Ensure 2FA is enabled on Gmail
- Check firewall/network permissions

### "Unable to find suitable Visual Studio toolchain" on Windows
- This error is for desktop builds - use web build instead:
  ```bash
  flutter run -d chrome
  ```

### Import Errors
- Run `flutter pub get` to download all dependencies
- Make sure `mailer: ^6.1.0` is in `pubspec.yaml`

## Security Notes

⚠️ **Important**: Never commit actual email credentials to version control!

- Use environment variables for production
- Store credentials securely
- Use Gmail App Passwords, not actual passwords
- Consider backend implementation for production

## Next Steps

For production deployment:
1. Implement backend email service (recommended)
2. Add database for user storage
3. Add JWT authentication
4. Implement password reset functionality
5. Add email templates for better HTML formatting

