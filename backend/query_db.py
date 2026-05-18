import os
from dotenv import load_dotenv
import psycopg2
from psycopg2.extras import RealDictCursor

# Load environment variables
load_dotenv()

DATABASE_URL = os.getenv("DATABASE_URL")
if not DATABASE_URL:
    print("Error: DATABASE_URL not set in your .env file.")
    exit(1)

print("Connecting to Supabase PostgreSQL...")
try:
    conn = psycopg2.connect(DATABASE_URL)
    cursor = conn.cursor(cursor_factory=RealDictCursor)
    print("Connected successfully!\n")
    
    tables = ['users', 'calculations', 'chat_sessions', 'activity_logs']
    
    print("==================================================")
    print("          SUPABASE CURRENT DATABASE STATS         ")
    print("==================================================")
    
    for table in tables:
        # Get count
        cursor.execute(f"SELECT COUNT(*) as count FROM {table}")
        count = cursor.fetchone()['count']
        print(f"Table '{table}': {count} total rows")
        
        # Get latest record email/action if any
        if count > 0:
            if table == 'users':
                cursor.execute("SELECT name, email, city, created_at FROM users ORDER BY created_at DESC LIMIT 1")
                row = cursor.fetchone()
                print(f"  -> Latest: '{row['name']}' ({row['email']}) in {row['city'] or 'N/A'} at {row['created_at']}")
            elif table == 'calculations':
                cursor.execute("SELECT user_email, location, system_size_kw, calculated_at FROM calculations ORDER BY calculated_at DESC LIMIT 1")
                row = cursor.fetchone()
                print(f"  -> Latest: {row['system_size_kw']} kW calculation in '{row['location']}' by {row['user_email']} at {row['calculated_at']}")
            elif table == 'chat_sessions':
                cursor.execute("SELECT user_email, message_count, saved_at FROM chat_sessions ORDER BY saved_at DESC LIMIT 1")
                row = cursor.fetchone()
                print(f"  -> Latest: Session with {row['message_count']} messages by {row['user_email']} at {row['saved_at']}")
            elif table == 'activity_logs':
                cursor.execute("SELECT user_email, action, timestamp FROM activity_logs ORDER BY timestamp DESC LIMIT 1")
                row = cursor.fetchone()
                print(f"  -> Latest Action: '{row['action']}' by {row['user_email']} at {row['timestamp']}")
        print()
        
    print("==================================================")
    cursor.close()
    conn.close()
except Exception as e:
    print(f"Database error: {e}")
