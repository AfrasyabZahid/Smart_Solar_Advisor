const express = require('express');
const nodemailer = require('nodemailer');
const cors = require('cors');
require('dotenv').config();

const app = express();

app.use(cors());
app.use(express.json());

// Configure Nodemailer with Gmail
const transporter = nodemailer.createTransport({
  service: 'gmail',
  auth: {
    user: process.env.GMAIL_EMAIL,
    pass: process.env.GMAIL_PASSWORD,
  },
});

// Generate 6-digit OTP
function generateOTP() {
  return Math.floor(100000 + Math.random() * 900000).toString();
}

// Send OTP endpoint
app.post('/api/send-otp', async (req, res) => {
  try {
    const { email, username } = req.body;

    if (!email || !username) {
      return res.status(400).json({
        success: false,
        message: 'Email and username are required',
      });
    }

    const otp = generateOTP();

    const htmlContent = `
      <html>
        <body style="font-family: Arial, sans-serif; background-color: #f5f5f5; padding: 20px;">
          <div style="max-width: 600px; margin: 0 auto; background-color: white; padding: 30px; border-radius: 10px; box-shadow: 0 2px 10px rgba(0,0,0,0.1);">
            <div style="text-align: center; margin-bottom: 30px;">
              <h1 style="color: #FF8C00; margin: 0;">Smart Solar Advisor</h1>
              <p style="color: #666; margin: 10px 0 0 0;">Email Verification</p>
            </div>
            
            <h2 style="color: #333; text-align: center; margin-bottom: 20px;">Verify Your Email Address</h2>
            
            <p style="color: #555; font-size: 16px; line-height: 1.6;">
              Hello <strong>${username}</strong>,
            </p>
            
            <p style="color: #555; font-size: 16px; line-height: 1.6;">
              Thank you for signing up with Smart Solar Advisor. To complete your registration, please use the following One-Time Password (OTP) to verify your email address:
            </p>
            
            <div style="text-align: center; margin: 30px 0;">
              <div style="background-color: #f9f9f9; padding: 20px; border-radius: 8px; border: 2px solid #FF8C00;">
                <p style="font-size: 12px; color: #999; margin: 0 0 10px 0;">Your OTP Code</p>
                <p style="font-size: 36px; font-weight: bold; color: #FF8C00; margin: 0; letter-spacing: 5px;">${otp}</p>
              </div>
            </div>
            
            <p style="color: #555; font-size: 16px; line-height: 1.6;">
              <strong>Important:</strong> This OTP is valid for 10 minutes. Do not share this code with anyone.
            </p>
            
            <p style="color: #555; font-size: 16px; line-height: 1.6;">
              If you didn't create this account, please ignore this email or contact us immediately.
            </p>
            
            <hr style="border: none; border-top: 1px solid #ddd; margin: 30px 0;">
            
            <p style="color: #999; font-size: 12px; text-align: center; margin: 0;">
              © 2026 Smart Solar Advisor. All rights reserved.
            </p>
          </div>
        </body>
      </html>
    `;

    const mailOptions = {
      from: `Smart Solar Advisor <${process.env.GMAIL_EMAIL}>`,
      to: email,
      subject: 'Verify Your Email - OTP Code',
      html: htmlContent,
      text: `Hello ${username},\n\nThank you for signing up with Smart Solar Advisor. Your OTP code is: ${otp}\n\nThis code is valid for 10 minutes. Do not share this code with anyone.\n\nIf you didn't create this account, please ignore this email.\n\nBest regards,\nSmart Solar Advisor Team`,
      headers: {
        'X-Priority': '3',
        'X-MSMail-Priority': 'Normal',
        'X-Mailer': 'Smart Solar Advisor',
        'Importance': 'normal',
      },
    };

    await transporter.sendMail(mailOptions);

    res.json({
      success: true,
      message: 'OTP sent successfully',
      otp: otp, // In production, don't send this! Only for testing.
    });
  } catch (error) {
    console.error('Error sending OTP:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to send OTP. Error: ' + error.message,
    });
  }
});

// Health check endpoint
app.get('/api/health', (req, res) => {
  res.json({ status: 'OK' });
});

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
  console.log(`Server running on http://localhost:${PORT}`);
});
