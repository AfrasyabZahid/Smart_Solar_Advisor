# Smart Solar Advisor - OTP Backend Server

This is a simple Node.js backend server for handling OTP email sending.

## Setup Instructions

### 1. Install Dependencies
```bash
cd backend
npm install
```

### 2. Configure Gmail Credentials

Edit the `.env` file with your Gmail credentials:
```
GMAIL_EMAIL=your-gmail@gmail.com
GMAIL_PASSWORD=your-app-password
PORT=3000
```

**Important:** Use a Gmail App Password, not your regular password:
1. Go to https://myaccount.google.com/apppasswords
2. Select "Mail" and "Windows" (or your OS)
3. Copy the generated 16-character password
4. Paste it in `.env` as `GMAIL_PASSWORD`

### 3. Start the Server
```bash
npm start
```

Or for development with auto-reload:
```bash
npm run dev
```

The server will run on `http://localhost:3000`

## API Endpoints

### Send OTP
**POST** `/api/send-otp`

Request body:
```json
{
  "email": "user@example.com",
  "username": "john_doe"
}
```

Response:
```json
{
  "success": true,
  "message": "OTP sent successfully",
  "otp": "123456"
}
```

### Health Check
**GET** `/api/health`

Response:
```json
{
  "status": "OK"
}
```

## Testing

You can test the OTP endpoint using curl:
```bash
curl -X POST http://localhost:3000/api/send-otp \
  -H "Content-Type: application/json" \
  -d '{"email":"your-email@gmail.com","username":"testuser"}'
```

## Notes

- The OTP is valid for 10 minutes
- The backend sends the OTP in the response for testing purposes (remove in production)
- CORS is enabled for development - restrict it in production
- Make sure the Gmail account has 2FA enabled
