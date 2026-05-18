import os
import json
from datetime import datetime
from dotenv import load_dotenv
from pymongo import MongoClient
import psycopg2
from psycopg2.extras import RealDictCursor

# Load environment variables
load_dotenv()

MONGO_URI = os.getenv("MONGO_URI", "mongodb+srv://malikrida2626_db_user:Hawwa123@cluster0.0c9oio0.mongodb.net/smart_solar_db?retryWrites=true&w=majority&appName=Cluster0")
DATABASE_URL = os.getenv("DATABASE_URL")

print("==================================================")
print("     SMART SOLAR ADVISOR DATABASE MIGRATOR        ")
print("==================================================")
print(f"MongoDB URI found: {'Yes (Using Atlas/Configured)' if MONGO_URI else 'No'}")
print(f"Supabase DB URL found: {'Yes' if DATABASE_URL else 'No'}")
print("==================================================")

if not DATABASE_URL:
    raise ValueError("Error: DATABASE_URL not set in environment or .env file.")

# Initialize Connections
print("Connecting to Supabase PostgreSQL...")
try:
    pg_conn = psycopg2.connect(DATABASE_URL)
    pg_conn.autocommit = True
    pg_cursor = pg_conn.cursor()
    print("Successfully connected to Supabase.")
except Exception as e:
    print(f"Error connecting to Supabase: {e}")
    exit(1)

# Ensure schemas exist
print("Creating tables on Supabase if they do not exist...")
tables_schema = """
-- Users Table
CREATE TABLE IF NOT EXISTS users (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    email VARCHAR(150) UNIQUE NOT NULL,
    password VARCHAR(255) NOT NULL,
    city VARCHAR(100) DEFAULT '',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Solar System Calculations Table
CREATE TABLE IF NOT EXISTS calculations (
    id SERIAL PRIMARY KEY,
    user_email VARCHAR(150) NOT NULL,
    energy_usage_kwh FLOAT NOT NULL,
    rooftop_area_sqm FLOAT NOT NULL,
    location VARCHAR(100) NOT NULL,
    load_shedding_hours FLOAT NOT NULL,
    system_size_kw FLOAT NOT NULL,
    system_cost_pkr FLOAT NOT NULL,
    calculated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- AI Chat Sessions Table
CREATE TABLE IF NOT EXISTS chat_sessions (
    id SERIAL PRIMARY KEY,
    user_email VARCHAR(150) NOT NULL,
    messages JSONB NOT NULL,
    session_started_at VARCHAR(100) NOT NULL,
    session_ended_at VARCHAR(100) NOT NULL,
    message_count INT NOT NULL,
    saved_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- User Activity Logs Table
CREATE TABLE IF NOT EXISTS activity_logs (
    id SERIAL PRIMARY KEY,
    user_email VARCHAR(150) NOT NULL,
    action VARCHAR(100) NOT NULL,
    details JSONB NOT NULL,
    timestamp TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Performance & Lookup Optimization Indices
CREATE INDEX IF NOT EXISTS idx_calculations_email ON calculations (user_email);
CREATE INDEX IF NOT EXISTS idx_chat_sessions_email ON chat_sessions (user_email);
CREATE INDEX IF NOT EXISTS idx_activity_logs_email ON activity_logs (user_email);
"""

try:
    pg_cursor.execute(tables_schema)
    print("Supabase database schema verified and created successfully.")
except Exception as e:
    print(f"Error creating tables on Supabase: {e}")
    pg_cursor.close()
    pg_conn.close()
    exit(1)

# Connect to MongoDB
print("\nConnecting to MongoDB Atlas...")
try:
    mongo_client = MongoClient(MONGO_URI)
    db = mongo_client['smart_solar_db']
    print("Successfully connected to MongoDB.")
except Exception as e:
    print(f"Error connecting to MongoDB: {e}")
    print("Skipping data migration, only schemas were created.")
    pg_cursor.close()
    pg_conn.close()
    exit(0)

# MIGRATION: USERS
print("\nMigrating [users] collection...")
try:
    users_collection = db['users']
    mongo_users = list(users_collection.find())
    print(f"Found {len(mongo_users)} users in MongoDB.")
    
    migrated_users = 0
    skipped_users = 0
    
    for u in mongo_users:
        email = u['email'].lower()
        
        # Check if already exists in Supabase
        pg_cursor.execute("SELECT id FROM users WHERE email = %s", (email,))
        if pg_cursor.fetchone():
            skipped_users += 1
            continue
            
        name = u.get('name', 'User')
        
        # In PyMongo, password might be stored as bytes
        password = u.get('password')
        if isinstance(password, bytes):
            password = password.decode('utf-8')
            
        city = u.get('city', '')
        created_at = u.get('created_at', datetime.utcnow())
        updated_at = u.get('updated_at', datetime.utcnow())
        
        pg_cursor.execute(
            """
            INSERT INTO users (name, email, password, city, created_at, updated_at)
            VALUES (%s, %s, %s, %s, %s, %s)
            """,
            (name, email, password, city, created_at, updated_at)
        )
        migrated_users += 1
        
    print(f"Users migration summary: {migrated_users} migrated, {skipped_users} skipped (already existed).")
except Exception as e:
    print(f"Error migrating users: {e}")

# MIGRATION: CALCULATIONS
print("\nMigrating [calculations] collection...")
try:
    calculations_collection = db['calculations']
    mongo_calcs = list(calculations_collection.find())
    print(f"Found {len(mongo_calcs)} calculations in MongoDB.")
    
    migrated_calcs = 0
    skipped_calcs = 0
    
    for c in mongo_calcs:
        user_email = c.get('user_email', '').lower()
        if not user_email:
            skipped_calcs += 1
            continue
            
        energy_usage_kwh = float(c.get('energy_usage_kwh', 0))
        rooftop_area_sqm = float(c.get('rooftop_area_sqm', 0))
        location = c.get('location', '')
        load_shedding_hours = float(c.get('load_shedding_hours', 0))
        system_size_kw = float(c.get('system_size_kw', 0))
        system_cost_pkr = float(c.get('system_cost_pkr', 0))
        calculated_at = c.get('calculated_at', datetime.utcnow())
        
        # Check if identical record already exists in Supabase
        pg_cursor.execute(
            """
            SELECT id FROM calculations 
            WHERE user_email = %s AND calculated_at = %s AND system_size_kw = %s
            """,
            (user_email, calculated_at, system_size_kw)
        )
        if pg_cursor.fetchone():
            skipped_calcs += 1
            continue
            
        pg_cursor.execute(
            """
            INSERT INTO calculations (user_email, energy_usage_kwh, rooftop_area_sqm, location, load_shedding_hours, system_size_kw, system_cost_pkr, calculated_at)
            VALUES (%s, %s, %s, %s, %s, %s, %s, %s)
            """,
            (user_email, energy_usage_kwh, rooftop_area_sqm, location, load_shedding_hours, system_size_kw, system_cost_pkr, calculated_at)
        )
        migrated_calcs += 1
        
    print(f"Calculations migration summary: {migrated_calcs} migrated, {skipped_calcs} skipped.")
except Exception as e:
    print(f"Error migrating calculations: {e}")

# MIGRATION: CHAT SESSIONS
print("\nMigrating [chat_sessions] collection...")
try:
    chat_sessions_collection = db['chat_sessions']
    mongo_chats = list(chat_sessions_collection.find())
    print(f"Found {len(mongo_chats)} chat sessions in MongoDB.")
    
    migrated_chats = 0
    skipped_chats = 0
    
    for cs in mongo_chats:
        user_email = cs.get('user_email', '').lower()
        if not user_email:
            skipped_chats += 1
            continue
            
        messages = cs.get('messages', [])
        session_started_at = cs.get('session_started_at', datetime.utcnow().isoformat())
        session_ended_at = cs.get('session_ended_at', datetime.utcnow().isoformat())
        message_count = int(cs.get('message_count', len(messages)))
        saved_at = cs.get('saved_at', datetime.utcnow())
        
        # Verify JSON list format
        messages_json = json.dumps(messages)
        
        # Check if identical record already exists in Supabase
        pg_cursor.execute(
            """
            SELECT id FROM chat_sessions 
            WHERE user_email = %s AND session_started_at = %s
            """,
            (user_email, session_started_at)
        )
        if pg_cursor.fetchone():
            skipped_chats += 1
            continue
            
        pg_cursor.execute(
            """
            INSERT INTO chat_sessions (user_email, messages, session_started_at, session_ended_at, message_count, saved_at)
            VALUES (%s, %s, %s, %s, %s, %s)
            """,
            (user_email, messages_json, session_started_at, session_ended_at, message_count, saved_at)
        )
        migrated_chats += 1
        
    print(f"Chat sessions migration summary: {migrated_chats} migrated, {skipped_chats} skipped.")
except Exception as e:
    print(f"Error migrating chat sessions: {e}")

# MIGRATION: ACTIVITY LOGS
print("\nMigrating [activity_logs] collection...")
try:
    activity_logs_collection = db['activity_logs']
    mongo_logs = list(activity_logs_collection.find())
    print(f"Found {len(mongo_logs)} activity logs in MongoDB.")
    
    migrated_logs = 0
    skipped_logs = 0
    
    for l in mongo_logs:
        user_email = l.get('user_email', '').lower()
        if not user_email:
            skipped_logs += 1
            continue
            
        action = l.get('action', '')
        details = l.get('details', {})
        timestamp = l.get('timestamp', datetime.utcnow())
        
        details_json = json.dumps(details)
        
        # Check if identical record already exists in Supabase
        pg_cursor.execute(
            """
            SELECT id FROM activity_logs 
            WHERE user_email = %s AND action = %s AND timestamp = %s
            """,
            (user_email, action, timestamp)
        )
        if pg_cursor.fetchone():
            skipped_logs += 1
            continue
            
        pg_cursor.execute(
            """
            INSERT INTO activity_logs (user_email, action, details, timestamp)
            VALUES (%s, %s, %s, %s)
            """,
            (user_email, action, details_json, timestamp)
        )
        migrated_logs += 1
        
    print(f"Activity logs migration summary: {migrated_logs} migrated, {skipped_logs} skipped.")
except Exception as e:
    print(f"Error migrating activity logs: {e}")

# Clean up
pg_cursor.close()
pg_conn.close()
print("\n==================================================")
print("             MIGRATION COMPLETED!                 ")
print("==================================================")
