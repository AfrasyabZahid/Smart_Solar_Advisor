import os
import bcrypt
import random
import smtplib
from bson import ObjectId
from email.mime.text import MIMEText
from email.mime.multipart import MIMEMultipart
from flask import Flask, request, jsonify
from flask_cors import CORS
from pymongo import MongoClient, DESCENDING
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

        # Collections
        users_collection      = db['users']
        calculations_collection = db['calculations']
        chat_sessions_collection = db['chat_sessions']
        activity_logs_collection  = db['activity_logs']

        # Indexes
        users_collection.create_index('email', unique=True)
        calculations_collection.create_index([('user_email', 1), ('calculated_at', DESCENDING)])
        chat_sessions_collection.create_index([('user_email', 1), ('session_started_at', DESCENDING)])
        activity_logs_collection.create_index([('user_email', 1), ('timestamp', DESCENDING)])

        print("Connected to MongoDB successfully.")
    except Exception as e:
        print(f"Error connecting to MongoDB: {e}")
        db = None
else:
    print("WARNING: MONGO_URI not found in environment variables. Database operations will fail.")
    db = None

# Email setup
GMAIL_EMAIL    = os.getenv('GMAIL_EMAIL')
GMAIL_PASSWORD = os.getenv('GMAIL_PASSWORD')

# ─── Helpers ────────────────────────────────────────────────────────────────

def generate_otp():
    return str(random.randint(100000, 999999))

def _log_activity(user_email: str, action: str, details: dict = None):
    """Internal helper — silently log an activity event."""
    if db is None:
        return
    try:
        activity_logs_collection.insert_one({
            "user_email": user_email.lower(),
            "action":     action,
            "details":    details or {},
            "timestamp":  datetime.utcnow(),
        })
    except Exception:
        pass  # never let logging crash a real endpoint

# ─── Health ──────────────────────────────────────────────────────────────────

@app.route('/api/health', methods=['GET'])
def health_check():
    return jsonify({"status": "ok", "db_connected": db is not None}), 200

# ─── Auth ─────────────────────────────────────────────────────────────────────

@app.route('/api/send-otp', methods=['POST'])
def send_otp():
    data = request.json
    if not data or 'email' not in data or 'username' not in data:
        return jsonify({"success": False, "message": "Email and username are required"}), 400

    email    = data['email']
    username = data['username']
    otp      = generate_otp()

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
        msg['From']    = f"Smart Solar Advisor <{GMAIL_EMAIL}>"
        msg['To']      = email

        part = MIMEText(html_content, 'html')
        msg.attach(part)

        server = smtplib.SMTP('smtp.gmail.com', 587)
        server.starttls()
        server.login(GMAIL_EMAIL, GMAIL_PASSWORD)
        server.send_message(msg)
        server.quit()

        return jsonify({"success": True, "message": "OTP sent successfully", "otp": otp}), 200
    except Exception as e:
        print(f"Error sending OTP: {e}")
        return jsonify({"success": False, "message": f"Failed to send OTP. Error: {str(e)}"}), 500


@app.route('/api/check_email', methods=['POST'])
def check_email():
    if db is None:
        return jsonify({"success": False, "message": "Database connection error"}), 500

    data = request.json
    if not data or 'email' not in data:
        return jsonify({"success": False, "message": "Missing required fields"}), 400

    email = data['email'].lower()
    user  = users_collection.find_one({"email": email})
    return jsonify({"exists": user is not None}), 200


@app.route('/api/register', methods=['POST'])
def register():
    if db is None:
        return jsonify({"success": False, "message": "Database connection error"}), 500

    data = request.json
    if not data or 'email' not in data or 'password' not in data or 'name' not in data:
        return jsonify({"success": False, "message": "Missing required fields"}), 400

    email    = data['email'].lower()
    password = data['password']
    name     = data['name']

    hashed_password = bcrypt.hashpw(password.encode('utf-8'), bcrypt.gensalt())

    user_doc = {
        "name":       name,
        "email":      email,
        "password":   hashed_password,
        "city":       "",
        "created_at": datetime.utcnow(),
        "updated_at": datetime.utcnow(),
    }

    try:
        users_collection.insert_one(user_doc)
        _log_activity(email, 'registered')
        return jsonify({
            "success": True,
            "message": "User registered successfully",
            "user":    {"name": name, "email": email}
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

    email    = data['email'].lower()
    password = data['password']

    user = users_collection.find_one({"email": email})

    if user and bcrypt.checkpw(password.encode('utf-8'), user['password']):
        _log_activity(email, 'login')
        return jsonify({
            "success": True,
            "message": "Login successful",
            "user": {
                "name":  user['name'],
                "email": user['email'],
                "city":  user.get('city', ''),
            }
        }), 200

    return jsonify({"success": False, "message": "Invalid email or password"}), 401


@app.route('/api/logout', methods=['POST'])
def logout():
    data = request.json or {}
    email = data.get('email', '').lower()
    if email:
        _log_activity(email, 'logout')
    return jsonify({"success": True, "message": "Logged out"}), 200

# ─── Profile ─────────────────────────────────────────────────────────────────

@app.route('/api/update_profile', methods=['PUT'])
def update_profile():
    if db is None:
        return jsonify({"success": False, "message": "Database connection error"}), 500

    data = request.json
    if not data or 'email' not in data:
        return jsonify({"success": False, "message": "Email is required"}), 400

    email  = data['email'].lower()
    fields = {}

    if 'name' in data and data['name'].strip():
        fields['name'] = data['name'].strip()
    if 'city' in data:
        fields['city'] = data['city'].strip()

    if not fields:
        return jsonify({"success": False, "message": "Nothing to update"}), 400

    fields['updated_at'] = datetime.utcnow()

    result = users_collection.update_one({"email": email}, {"$set": fields})

    if result.matched_count == 0:
        return jsonify({"success": False, "message": "User not found"}), 404

    _log_activity(email, 'profile_updated', {"fields": list(fields.keys())})
    return jsonify({"success": True, "message": "Profile updated successfully"}), 200


@app.route('/api/change_password', methods=['PUT'])
def change_password():
    if db is None:
        return jsonify({"success": False, "message": "Database connection error"}), 500

    data = request.json
    if not data or 'email' not in data or 'current_password' not in data or 'new_password' not in data:
        return jsonify({"success": False, "message": "Missing required fields"}), 400

    email            = data['email'].lower()
    current_password = data['current_password']
    new_password     = data['new_password']

    if len(new_password) < 6:
        return jsonify({"success": False, "message": "New password must be at least 6 characters"}), 400

    user = users_collection.find_one({"email": email})
    if not user:
        return jsonify({"success": False, "message": "User not found"}), 404

    if not bcrypt.checkpw(current_password.encode('utf-8'), user['password']):
        return jsonify({"success": False, "message": "Current password is incorrect"}), 401

    new_hashed = bcrypt.hashpw(new_password.encode('utf-8'), bcrypt.gensalt())
    users_collection.update_one(
        {"email": email},
        {"$set": {"password": new_hashed, "updated_at": datetime.utcnow()}}
    )
    _log_activity(email, 'password_changed')
    return jsonify({"success": True, "message": "Password changed successfully"}), 200

# ─── Calculator ───────────────────────────────────────────────────────────────

@app.route('/api/save_calculation', methods=['POST'])
def save_calculation():
    if db is None:
        return jsonify({"success": False, "message": "Database connection error"}), 500

    data = request.json
    required = ['user_email', 'energy_usage_kwh', 'rooftop_area_sqm',
                'location', 'load_shedding_hours', 'system_size_kw', 'system_cost_pkr']

    if not data or not all(k in data for k in required):
        return jsonify({"success": False, "message": "Missing required fields"}), 400

    doc = {
        "user_email":          data['user_email'].lower(),
        "energy_usage_kwh":    float(data['energy_usage_kwh']),
        "rooftop_area_sqm":    float(data['rooftop_area_sqm']),
        "location":            data['location'],
        "load_shedding_hours": float(data['load_shedding_hours']),
        "system_size_kw":      float(data['system_size_kw']),
        "system_cost_pkr":     float(data['system_cost_pkr']),
        "calculated_at":       datetime.utcnow(),
    }

    calculations_collection.insert_one(doc)
    _log_activity(data['user_email'], 'calculation_saved', {
        "system_size_kw": doc['system_size_kw'],
        "location":       doc['location'],
    })
    return jsonify({"success": True, "message": "Calculation saved"}), 201


@app.route('/api/get_calculations', methods=['GET'])
def get_calculations():
    if db is None:
        return jsonify({"success": False, "message": "Database connection error"}), 500

    email = request.args.get('email', '').lower()
    if not email:
        return jsonify({"success": False, "message": "Email is required"}), 400

    limit = int(request.args.get('limit', 20))
    docs  = list(
        calculations_collection
        .find({"user_email": email}, {"_id": 0})
        .sort("calculated_at", DESCENDING)
        .limit(limit)
    )

    # Convert datetime objects to ISO strings for JSON serialisation
    for d in docs:
        if 'calculated_at' in d:
            d['calculated_at'] = d['calculated_at'].isoformat()

    return jsonify({"success": True, "calculations": docs}), 200

# ─── Chat ─────────────────────────────────────────────────────────────────────

@app.route('/api/chat', methods=['POST'])
def chat():
    if groq_client is None:
        return jsonify({"success": False, "message": "Groq API key not configured"}), 500

    data = request.json
    if not data or 'messages' not in data:
        return jsonify({"success": False, "message": "Missing messages"}), 400

    user_messages = data['messages']

    system_prompt = {
        "role":    "system",
        "content": """You are the Smart Solar Advisor AI — an expert assistant built into the Smart Solar Advisor app, designed specifically for Pakistan's solar energy market.

═══════════════════════════════════════════
ABOUT SMART SOLAR ADVISOR APP
═══════════════════════════════════════════
Smart Solar Advisor is a Flutter-based mobile/web application that helps Pakistani households and businesses:
- Calculate the ideal solar system size based on their daily energy usage
- Estimate system costs in PKR
- Understand the impact of load shedding on their energy needs
- Make informed decisions about going solar

App features:
1. Solar System Calculator — users enter daily energy usage (kWh), rooftop area (m²), city/location, and daily load shedding hours
2. AI Chatbot (you) — answers solar questions intelligently
3. User Profile — manages account details
4. Vendor Directory — lists solar vendors (coming soon)

═══════════════════════════════════════════
CALCULATOR FORMULAS (EXACT — USE THESE)
═══════════════════════════════════════════
System Size (kW) = (Daily Energy Usage in kWh × 1.3) / 5
  - 1.3 factor: accounts for system losses, inverter inefficiency, cloudy days
  - Dividing by 5: assumes 5 peak sun hours/day (Pakistan average)

Estimated Cost (PKR) = System Size (kW) × 300,000
  - PKR 300,000 per kW is the average installed cost in Pakistan

EXAMPLE: Daily usage = 20 kWh
  System Size = (20 × 1.3) / 5 = 5.2 kW
  Cost = 5.2 × 300,000 = PKR 1,560,000

═══════════════════════════════════════════
PAKISTAN SOLAR CONTEXT
═══════════════════════════════════════════
Peak Sun Hours by City:
- Karachi, Hyderabad, Quetta: 5.5–6.5 hrs/day (excellent)
- Lahore, Faisalabad, Multan: 4.5–5.5 hrs/day (very good)
- Islamabad, Rawalpindi, Peshawar: 4.0–5.0 hrs/day (good)
- Gilgit, Murree, Northern areas: 3.5–4.5 hrs/day (moderate)

Load Shedding Reality:
- Urban areas: 4–8 hours/day
- Rural areas: 8–16 hours/day
- Solar + battery completely eliminates load shedding impact
- Hybrid systems are the most popular solution in Pakistan

Net Metering (NEPRA):
- Sell excess electricity back to the grid
- Rate: PKR 19–22 per unit exported (2024–2025)
- Requires bi-directional meter from utility company
- Payback with net metering: typically 4–6 years

Government Incentives:
- Solar panels/equipment: 0% import duty and 0% GST (2023 policy)
- SBP green financing schemes at subsidized rates

═══════════════════════════════════════════
SOLAR SYSTEM COMPONENTS
═══════════════════════════════════════════
PANELS:
- Monocrystalline: 20–22% efficiency, higher cost, best for limited roof space, 25–30 year lifespan
- Polycrystalline: 15–17% efficiency, cheaper, good for large rooftops
- Bifacial: captures light from both sides, 5–10% more output, premium price
- Top brands in Pakistan: Longi, JA Solar, Canadian Solar, Trina Solar

INVERTERS:
- On-Grid: cheapest, no battery, shuts off during load shedding
- Off-Grid: works without grid, requires battery, higher cost
- Hybrid: works with grid AND battery — most popular in Pakistan
- Top brands: Huawei, Growatt, Solis, Knox, Inverex, Voltronics

BATTERIES:
- Lead-Acid: cheapest, 3–5 year life, heavy
- Lithium (LiFePO4): expensive upfront, 10–15 year life, lightweight — RECOMMENDED
- Tubular: mid-range, good for deep cycle
- 1 kWh lithium storage: ~PKR 30,000–50,000

ROOF SPACE:
- 1 kW solar needs ~7–10 m² of roof
- 5 kW system needs ~35–50 m² clear, unshaded roof

═══════════════════════════════════════════
SYSTEM SIZE GUIDE
═══════════════════════════════════════════
Small home (2 rooms): 5–10 kWh/day → 1–3 kW system
Medium home (3–4 rooms): 10–20 kWh/day → 3–5 kW system
Large home: 20–30 kWh/day → 5–8 kW system
Very large / villa: 30–50 kWh/day → 8–13 kW system
Commercial: 50–100 kWh/day → 13–26 kW system

Common appliance consumption (Pakistan):
- AC 1.5 ton (8 hrs): ~12 kWh
- Refrigerator: ~1.5 kWh/day
- Water pump 1hp (2 hrs): ~1.5 kWh
- 10 LED lights (8 hrs): ~0.8 kWh
- 3 fans (12 hrs): ~0.9 kWh
- TV (8 hrs): ~0.4 kWh
- Washing machine (1 hr): ~0.5 kWh

═══════════════════════════════════════════
APPROXIMATE COSTS (PKR, 2024–2025)
═══════════════════════════════════════════
3 kW system:  ~PKR 270,000–350,000
5 kW system:  ~PKR 420,000–550,000
10 kW system: ~PKR 780,000–1,000,000
20 kW system: ~PKR 1,400,000–1,800,000
Battery backup adds: PKR 100,000–300,000 depending on capacity
Payback period (no battery): 3–5 years
Payback period (with battery): 5–8 years

═══════════════════════════════════════════
YOUR RULES
═══════════════════════════════════════════
1. Always give costs in PKR. Show USD only if asked (1 USD ≈ 278 PKR).
2. When a user gives their daily kWh usage, CALCULATE system size and cost using the exact formulas above.
3. Be friendly, concise, and encouraging about solar adoption in Pakistan.
4. Give city-specific advice when the user mentions their location.
5. Encourage users to use the Solar Calculator feature in the app for precise results.
6. Do NOT answer questions unrelated to solar energy, electricity, or energy management.
7. If asked who made you: say "I was built by the Smart Solar Advisor team to help Pakistanis go solar!"
8. Format with bullet points or short paragraphs — never long walls of text.
9. Never make up vendor names, government schemes, or prices beyond what is listed above.
"""
    }

    messages = [system_prompt] + user_messages

    try:
        completion = groq_client.chat.completions.create(
            model="llama-3.1-8b-instant",
            messages=messages,
            temperature=0.7,
            max_tokens=1024,
        )
        reply = completion.choices[0].message.content
        return jsonify({"success": True, "reply": reply}), 200
    except Exception as e:
        print(f"Error calling Groq API: {e}")
        return jsonify({"success": False, "message": f"Error calling AI service: {str(e)}"}), 500


@app.route('/api/save_chat', methods=['POST'])
def save_chat():
    if db is None:
        return jsonify({"success": False, "message": "Database connection error"}), 500

    data = request.json
    if not data or 'user_email' not in data or 'messages' not in data:
        return jsonify({"success": False, "message": "Missing required fields"}), 400

    doc = {
        "user_email":          data['user_email'].lower(),
        "messages":            data['messages'],
        "session_started_at":  data.get('session_started_at', datetime.utcnow().isoformat()),
        "session_ended_at":    datetime.utcnow().isoformat(),
        "message_count":       len(data['messages']),
        "saved_at":            datetime.utcnow(),
    }

    chat_sessions_collection.insert_one(doc)
    _log_activity(data['user_email'], 'chat_session_saved', {
        "message_count": doc['message_count']
    })
    return jsonify({"success": True, "message": "Chat session saved"}), 201


@app.route('/api/get_chats', methods=['GET'])
def get_chats():
    if db is None:
        return jsonify({"success": False, "message": "Database connection error"}), 500

    email = request.args.get('email', '').lower()
    if not email:
        return jsonify({"success": False, "message": "Email is required"}), 400

    limit = int(request.args.get('limit', 10))
    docs  = list(
        chat_sessions_collection
        .find({"user_email": email}, {"_id": 0})
        .sort("saved_at", DESCENDING)
        .limit(limit)
    )

    for d in docs:
        if 'saved_at' in d and hasattr(d['saved_at'], 'isoformat'):
            d['saved_at'] = d['saved_at'].isoformat()

    return jsonify({"success": True, "sessions": docs}), 200

# ─── Activity Log ─────────────────────────────────────────────────────────────

@app.route('/api/log_activity', methods=['POST'])
def log_activity():
    if db is None:
        return jsonify({"success": False, "message": "Database connection error"}), 500

    data = request.json
    if not data or 'user_email' not in data or 'action' not in data:
        return jsonify({"success": False, "message": "Missing required fields"}), 400

    _log_activity(data['user_email'], data['action'], data.get('details', {}))
    return jsonify({"success": True, "message": "Activity logged"}), 201


@app.route('/api/get_activity', methods=['GET'])
def get_activity():
    if db is None:
        return jsonify({"success": False, "message": "Database connection error"}), 500

    email = request.args.get('email', '').lower()
    if not email:
        return jsonify({"success": False, "message": "Email is required"}), 400

    limit = int(request.args.get('limit', 20))
    docs  = list(
        activity_logs_collection
        .find({"user_email": email}, {"_id": 0})
        .sort("timestamp", DESCENDING)
        .limit(limit)
    )

    for d in docs:
        if 'timestamp' in d:
            d['timestamp'] = d['timestamp'].isoformat()

    return jsonify({"success": True, "activities": docs}), 200

# ─── Run ──────────────────────────────────────────────────────────────────────

if __name__ == '__main__':
    port = int(os.getenv('PORT', 5000))
    app.run(host='0.0.0.0', port=port, debug=True)
