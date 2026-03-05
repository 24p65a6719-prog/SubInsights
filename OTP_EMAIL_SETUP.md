# OTP Email Configuration Guide

## Problem Summary
Users were not receiving OTP (One-Time Password) emails during registration because the system was running in **DEMO MODE**.

In demo mode, instead of actually sending emails, the system:
- Prints emails to the server console
- Does NOT send to actual email addresses

## Solution Implemented

### For Testing & Development (Demo Mode)
The system has been updated to make testing easier:

1. **OTP Code Displayed During Registration**
   - When you register, the OTP code is now shown in the response
   - You can see the OTP code in the registration success message

2. **OTP Code Display on Verification Page**
   - The verify-otp.html page now displays:
     - The 6-digit OTP code in a yellow alert box
     - A message indicating "Demo Mode"
   - The OTP input fields are automatically filled with the demo OTP

3. **Email Logs Endpoint**
   - Access email logs at: `http://127.0.0.1:5000/api/debug/email-logs`
   - Shows all emails that would be sent in demo mode
   - Only available when DEMO_MODE=true

### How to Use in Demo Mode

#### Step 1: Register
```
1. Go to /login-register.html
2. Fill in:
   - Full Name: Your Name
   - Email: any@email.com
   - Password: At least 6 characters
   - Phone: Optional
3. Click "Register"
4. See the OTP code in the success message and in localStorage
```

#### Step 2: Verify OTP
```
1. You'll be redirected to /verify-otp.html
2. The OTP code will be displayed in the yellow box at the top
3. The input fields will be automatically filled
4. Click "Verify & Create Account"
```

#### Step 3: Login
```
1. Go back to /login-register.html
2. Click "Already have an account? Login"
3. Enter the email and password you registered with
4. Click "Login"
```

## Setup Real Email Sending (Production)

If you want to actually send emails instead of using demo mode:

### Step 1: Prepare Gmail

1. Go to https://myaccount.google.com/security
2. Enable "2-Step Verification"
3. Go to https://myaccount.google.com/apppasswords
4. Select:
   - App: "Mail"
   - Device: "Windows Computer" (or your device)
5. Google will generate a 16-character password
6. **Copy this password** (you'll use it in the .env file)

### Step 2: Create .env File

1. In the project root directory (c:\Subinsights\), create a file named `.env`
2. Copy the content from `.env.example`
3. Fill in:
   ```env
   DEMO_MODE=false
   SMTP_SERVER=smtp.gmail.com
   SMTP_PORT=587
   SENDER_EMAIL=your-email@gmail.com
   SENDER_PASSWORD=xxxx-xxxx-xxxx-xxxx  # 16-char password from Google
   ```

### Step 3: Restart the Server

1. Stop the current Flask server (Ctrl+C)
2. Run the server again:
   ```bash
   cd c:\Subinsights\backend
   python server.py
   ```
3. Check the console output - it should say:
   ```
   [EmailService] Using REAL EMAIL MODE - Emails will be sent via SMTP
   ```

### Step 4: Test

1. Register with a real email address
2. Check your email inbox for the OTP
3. You should receive the email within 1-2 minutes

## Troubleshooting

### "OTP not received in email" when DEMO_MODE=false

**Possible causes:**

1. **Email not configured**
   - Check if .env file exists in project root
   - Verify DEMO_MODE=false is set
   - Check email and password are correct

2. **Gmail App Passwords issue**
   - Verify you're using the 16-character app password (not your regular Gmail password)
   - Go to https://myaccount.google.com/apppasswords and regenerate if needed

3. **Email in spam folder**
   - Check spam/junk email folder
   - The emails might have a "SubInsights" header

4. **SMTP connection error**
   - Check your internet connection
   - Verify SMTP_SERVER and SMTP_PORT are correct
   - Check the server console for detailed error messages

### Check Email Logs (Demo Mode)

To see all emails that would be sent:

```bash
curl http://127.0.0.1:5000/api/debug/email-logs
```

Or open in browser:
```
http://127.0.0.1:5000/api/debug/email-logs
```

This returns JSON with:
- `email_logs`: List of all emails sent/printed
- `email_stats`: Statistics grouped by email type
- `demo_mode`: Current mode status

## Files Modified

### Backend
- `backend/server.py`: Updated register and resend-otp endpoints to return OTP in demo mode
- `backend/server.py`: Added `/api/debug/email-logs` endpoint

### Frontend
- `frontend/login-register.html`: Updated to store demo_otp in localStorage
- `frontend/verify-otp.html`: Added display for demo OTP code
- `frontend/verify-otp.html`: Added auto-fill for OTP inputs

### Configuration
- `.env.example`: Example environment configuration file

## Security Notes

- **Never commit .env files** to version control
- **Never share your Gmail App Password**
- The demo OTP display should only be used for development/testing
- In production, remove the `demo_otp` from API responses
- Change the JWT_SECRET in .env for production use

## Support

If you continue to experience issues:

1. Check the Flask server console for error messages
2. Verify .env file is in the correct location (project root: c:\Subinsights\)
3. Check Gmail 2FA is enabled
4. Verify the 16-character app password is correct
5. Test SMTP connection manually if needed

---

**Status**: OTP registration system is now fully functional with demo mode for easy testing!
