import json
import random
import sys
import os
from datetime import datetime

# Add the current folder to sys.path so app can be imported
sys.path.append(os.path.abspath(os.path.dirname(__file__)))

from app import app, db_pool

print("==================================================")
print("     SMART SOLAR ADVISOR ENDPOINT VALIDATOR       ")
print("==================================================")

# Generate a random test email to avoid duplicate key issues on multiple runs
test_id = random.randint(1000, 9999)
test_email = f"solar_tester_{test_id}@example.com"
test_password = "SecurePassword123"
test_name = f"Solar Tester {test_id}"

print(f"Target Test User Email: {test_email}")

# Initialize Flask test client
client = app.test_client()

# Utility to print assertion status
def assert_check(name, condition, details=""):
    if condition:
        print(f"[ PASS ] {name} {details}")
    else:
        print(f"[ FAIL ] {name} {details}")
        sys.exit(1)

# 1. Health check
print("\nTesting: GET /api/health")
response = client.get('/api/health')
assert_check("Health status code is 200", response.status_code == 200)
res_json = response.get_json()
assert_check("Health status is 'ok'", res_json.get('status') == 'ok')
assert_check("Database is connected", res_json.get('db_connected') is True)

# 2. Check email before registering
print("\nTesting: POST /api/check_email (Unregistered email)")
response = client.post('/api/check_email', json={"email": test_email})
assert_check("Check email code is 200", response.status_code == 200)
res_json = response.get_json()
assert_check("Email does not exist yet", res_json.get('exists') is False)

# 3. Register user
print("\nTesting: POST /api/register")
register_payload = {
    "email": test_email,
    "password": test_password,
    "name": test_name
}
response = client.post('/api/register', json=register_payload)
assert_check("Register status code is 201", response.status_code == 201)
res_json = response.get_json()
assert_check("Registration successful flag", res_json.get('success') is True)
assert_check("Returns registered user name", res_json.get('user', {}).get('name') == test_name)

# 4. Check duplicate registration
print("\nTesting: POST /api/register (Duplicate)")
response = client.post('/api/register', json=register_payload)
assert_check("Duplicate register returns 409 conflict", response.status_code == 409)

# 5. Check email after registering
print("\nTesting: POST /api/check_email (Registered email)")
response = client.post('/api/check_email', json={"email": test_email})
assert_check("Check email code is 200", response.status_code == 200)
res_json = response.get_json()
assert_check("Email exists now", res_json.get('exists') is True)

# 6. Login
print("\nTesting: POST /api/login (Success)")
response = client.post('/api/login', json={"email": test_email, "password": test_password})
assert_check("Login status code is 200", response.status_code == 200)
res_json = response.get_json()
assert_check("Login success flag", res_json.get('success') is True)
assert_check("Returns correct user email", res_json.get('user', {}).get('email') == test_email)

# 7. Update profile
print("\nTesting: PUT /api/update_profile")
response = client.update_profile = client.put('/api/update_profile', json={
    "email": test_email,
    "name": f"{test_name} Updated",
    "city": "Lahore"
})
assert_check("Update profile status is 200", response.status_code == 200)
res_json = response.get_json()
assert_check("Update profile success flag", res_json.get('success') is True)

# 8. Save calculation
print("\nTesting: POST /api/save_calculation")
calc_payload = {
    "user_email": test_email,
    "energy_usage_kwh": 25.5,
    "rooftop_area_sqm": 45.0,
    "location": "Lahore",
    "load_shedding_hours": 2.0,
    "system_size_kw": 6.6,
    "system_cost_pkr": 1980000.0
}
response = client.post('/api/save_calculation', json=calc_payload)
assert_check("Save calculation status is 201", response.status_code == 201)

# 9. Get calculations
print("\nTesting: GET /api/get_calculations")
response = client.get(f'/api/get_calculations?email={test_email}')
assert_check("Get calculations status code is 200", response.status_code == 200)
res_json = response.get_json()
assert_check("Get calculations success flag", res_json.get('success') is True)
assert_check("Calculation count is at least 1", len(res_json.get('calculations', [])) >= 1)
saved_calc = res_json.get('calculations')[0]
assert_check("Matches saved location", saved_calc.get('location') == "Lahore")
assert_check("Matches saved system capacity", saved_calc.get('system_size_kw') == 6.6)

# 10. Save chat session
print("\nTesting: POST /api/save_chat")
chat_payload = {
    "user_email": test_email,
    "messages": [
        {"role": "user", "content": "Hello solar AI chatbot!"},
        {"role": "assistant", "content": "Hello! I am your Smart Solar Advisor."}
    ],
    "session_started_at": datetime.utcnow().isoformat()
}
response = client.post('/api/save_chat', json=chat_payload)
assert_check("Save chat session status is 201", response.status_code == 201)

# 11. Get chat sessions
print("\nTesting: GET /api/get_chats")
response = client.get(f'/api/get_chats?email={test_email}')
assert_check("Get chats status code is 200", response.status_code == 200)
res_json = response.get_json()
assert_check("Get chats success flag", res_json.get('success') is True)
assert_check("Chat session count is at least 1", len(res_json.get('sessions', [])) >= 1)
saved_session = res_json.get('sessions')[0]
assert_check("Chat message count is correct", saved_session.get('message_count') == 2)
assert_check("Messages parsed successfully", len(saved_session.get('messages', [])) == 2)

# 12. Query Activity logs
print("\nTesting: GET /api/get_activity")
response = client.get(f'/api/get_activity?email={test_email}')
assert_check("Get activity status code is 200", response.status_code == 200)
res_json = response.get_json()
assert_check("Get activity success flag", res_json.get('success') is True)
activities = res_json.get('activities', [])
assert_check("Logged at least one activity", len(activities) >= 1)
actions = [a.get('action') for a in activities]
print(f"Logged actions for this flow: {actions}")
assert_check("Logged 'registered' action", "registered" in actions)
assert_check("Logged 'login' action", "login" in actions)

print("\n==================================================")
print("     ALL API ENDPOINT CHECKS PASSED SUCCESSFULLY! ")
print("==================================================")

# Clean up DB pool
if db_pool:
    db_pool.closeall()
