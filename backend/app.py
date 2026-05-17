import os
import bcrypt
import random
import smtplib
from email.mime.text import MIMEText
from email.mime.multipart import MIMEMultipart
from flask import Flask, request, jsonify
from flask_cors import CORS
from pymongo import MongoClient
from pymongo.errors import DuplicateKeyError
from dotenv import load_dotenv
from datetime import datetime
from groq import Groq

# Load environment variables
load_dotenv()

app = Flask(__name__)
CORS(app)

GROQ_API_KEY = os.getenv('GROQ_API_KEY')
groq_client = Groq(api_key=GROQ_API_KEY) if GROQ_API_KEY and GROQ_API_KEY != "your_groq_api_key_here" else None

# MongoDB setup
MONGO_URI = os.getenv('MONGO_URI')
if MONGO_URI:
    try:
        client = MongoClient(MONGO_URI)
        db = client['smart_solar_db']
        users_collection = db['users']
        # Create unique index on email
        users_collection.create_index('email', unique=True)
        print("Connected to MongoDB successfully.")
    except Exception as e:
        print(f"Error connecting to MongoDB: {e}")
        db = None
else:
    print("WARNING: MONGO_URI not found in environment variables. Database operations will fail.")
    db = None

# Email setup
GMAIL_EMAIL = os.getenv('GMAIL_EMAIL')
GMAIL_PASSWORD = os.getenv('GMAIL_PASSWORD')

def generate_otp():
    return str(random.randint(100000, 999999))

@app.route('/api/health', methods=['GET'])
def health_check():
    return jsonify({"status": "ok", "db_connected": db is not None}), 200

@app.route('/api/send-otp', methods=['POST'])
def send_otp():
    data = request.json
    if not data or 'email' not in data or 'username' not in data:
        return jsonify({"success": False, "message": "Email and username are required"}), 400
        
    email = data['email']
    username = data['username']
    otp = generate_otp()
    
    html_content = f"""
      <html>
        <body style="font-family: Arial, sans-serif; background-color: #f5f5f5; padding: 20px;">
          <div style="max-width: 600px; margin: 0 auto; background-color: white; padding: 30px; border-radius: 10px; box-shadow: 0 2px 10px rgba(0,0,0,0.1);">
            <div style="text-align: center; margin-bottom: 30px;">
              <h1 style="color: #FF8C00; margin: 0;">Smart Solar Advisor</h1>
              <p style="color: #666; margin: 10px 0 0 0;">Email Verification</p>
            </div>
            
            <h2 style="color: #333; text-align: center; margin-bottom: 20px;">Verify Your Email Address</h2>
            
            <p style="color: #555; font-size: 16px; line-height: 1.6;">
              Hello <strong>{username}</strong>,
            </p>
            
            <p style="color: #555; font-size: 16px; line-height: 1.6;">
              Thank you for signing up with Smart Solar Advisor. To complete your registration, please use the following One-Time Password (OTP) to verify your email address:
            </p>
            
            <div style="text-align: center; margin: 30px 0;">
              <div style="background-color: #f9f9f9; padding: 20px; border-radius: 8px; border: 2px solid #FF8C00;">
                <p style="font-size: 12px; color: #999; margin: 0 0 10px 0;">Your OTP Code</p>
                <p style="font-size: 36px; font-weight: bold; color: #FF8C00; margin: 0; letter-spacing: 5px;">{otp}</p>
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
    """
    
    try:
        msg = MIMEMultipart('alternative')
        msg['Subject'] = 'Verify Your Email - OTP Code'
        msg['From'] = f"Smart Solar Advisor <{GMAIL_EMAIL}>"
        msg['To'] = email
        
        part = MIMEText(html_content, 'html')
        msg.attach(part)
        
        server = smtplib.SMTP('smtp.gmail.com', 587)
        server.starttls()
        server.login(GMAIL_EMAIL, GMAIL_PASSWORD)
        server.send_message(msg)
        server.quit()
        
        return jsonify({
            "success": True,
            "message": "OTP sent successfully",
            "otp": otp # In production, don't send this back. Keep it for testing based on existing code.
        }), 200
    except Exception as e:
        print(f"Error sending OTP: {e}")
        return jsonify({
            "success": False,
            "message": f"Failed to send OTP. Error: {str(e)}"
        }), 500

@app.route('/api/chat', methods=['POST'])
def chat():
    if groq_client is None:
        return jsonify({"success": False, "message": "Groq API key not configured"}), 500
        
    data = request.json
    if not data or 'messages' not in data:
        return jsonify({"success": False, "message": "Missing messages"}), 400
        
    user_messages = data['messages']
    
    # System prompt to give the AI context about the Smart Solar Advisor app
    system_prompt = {
        "role": "system",
        "content": "You are the Smart Solar Advisor Chatbot. You help users understand their solar energy needs, calculate system sizes based on daily energy usage and roof area, and explain load shedding impact. Be helpful, concise, and friendly. Answer specifically about solar energy, panels, inverters, and the Smart Solar Advisor project. Do not answer completely unrelated queries."
    }
    
    # Prepend the system prompt to the user's message history
    messages = [system_prompt] + user_messages
    
    try:
        completion = groq_client.chat.completions.create(
            model="llama-3.1-8b-instant", # Updated model
            messages=messages,
            temperature=0.7,
            max_tokens=1024,
        )
        
        reply = completion.choices[0].message.content
        return jsonify({
            "success": True,
            "reply": reply
        }), 200
    except Exception as e:
        print(f"Error calling Groq API: {e}")
        return jsonify({
            "success": False,
            "message": f"Error calling AI service: {str(e)}"
        }), 500

@app.route('/api/check_email', methods=['POST'])
def check_email():
    if db is None:
        return jsonify({"success": False, "message": "Database connection error"}), 500
        
    data = request.json
    if not data or 'email' not in data:
        return jsonify({"success": False, "message": "Missing required fields"}), 400
        
    email = data['email'].lower()
    user = users_collection.find_one({"email": email})
    
    return jsonify({"exists": user is not None}), 200

@app.route('/api/register', methods=['POST'])
def register():
    if db is None:
        return jsonify({"success": False, "message": "Database connection error"}), 500
        
    data = request.json
    if not data or 'email' not in data or 'password' not in data or 'name' not in data:
        return jsonify({"success": False, "message": "Missing required fields"}), 400
        
    email = data['email'].lower()
    password = data['password']
    name = data['name']
    
    hashed_password = bcrypt.hashpw(password.encode('utf-8'), bcrypt.gensalt())
    
    user_doc = {
        "name": name,
        "email": email,
        "password": hashed_password,
        "created_at": datetime.utcnow()
    }
    
    try:
        users_collection.insert_one(user_doc)
        return jsonify({
            "success": True, 
            "message": "User registered successfully",
            "user": {
                "name": name,
                "email": email
            }
        }), 201
    except DuplicateKeyError:
        return jsonify({"success": False, "message": "Email already exists"}), 409
    except Exception as e:
        return jsonify({"success": False, "message": f"An error occurred: {str(e)}"}), 500

@app.route('/api/login', methods=['POST'])
def login():
    if db is None:
        return jsonify({"success": False, "message": "Database connection error"}), 500
        
    data = request.json
    if not data or 'email' not in data or 'password' not in data:
        return jsonify({"success": False, "message": "Missing required fields"}), 400
        
    email = data['email'].lower()
    password = data['password']
    
    user = users_collection.find_one({"email": email})
    
    if user:
        if bcrypt.checkpw(password.encode('utf-8'), user['password']):
            return jsonify({
                "success": True, 
                "message": "Login successful",
                "user": {
                    "name": user['name'],
                    "email": user['email']
                }
            }), 200
            
    return jsonify({"success": False, "message": "Invalid email or password"}), 401

if __name__ == '__main__':
    port = int(os.getenv('PORT', 5000))
    app.run(host='0.0.0.0', port=port, debug=True)
