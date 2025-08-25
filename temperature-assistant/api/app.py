#!/usr/bin/env python3

# Import necessary libraries
import json                     # For working with JSON data
import subprocess               # For running the LLM script
import os                       # For path operations
from flask import Flask, request, jsonify  # Web API framework
from flask_cors import CORS     # For handling cross-origin requests

# Initialize Flask application
app = Flask(__name__)
CORS(app)  # Enable CORS for all routes

# Path to temperature data file - CUSTOMIZE THIS ON RASPBERRY PI
TEMP_JSON_PATH = os.path.expanduser("~/temperature.json") 

# Path to LLM script - CUSTOMIZE THIS ON RASPBERRY PI
LLM_SCRIPT_PATH = os.path.expanduser("~/llm/run_local_llm.sh")

# Function to get current temperature from JSON file
def get_current_temperature():
    try:
        # Read and parse temperature file
        with open(TEMP_JSON_PATH, 'r') as f:
            temp_data = json.load(f)
            return temp_data
    except Exception as e:
        # Return default values if there's an error
        print(f"Error reading temperature data: {e}")
        return {"celsius": "unknown", "fahrenheit": "unknown", "timestamp": "unknown"}

# API endpoint to get temperature data
@app.route('/api/temperature', methods=['GET'])
def get_temperature():
    # Return current temperature as JSON
    return jsonify(get_current_temperature())

# API endpoint to ask questions to the LLM
@app.route('/api/ask', methods=['POST'])
def ask_llm():
    # Get question from request
    user_query = request.json.get('query', '')
    
    # Print debug info
    print(f"Sending query to LLM: {user_query}")
    
    try:
        # Make script executable if needed
        if os.path.exists(LLM_SCRIPT_PATH) and not os.access(LLM_SCRIPT_PATH, os.X_OK):
            os.chmod(LLM_SCRIPT_PATH, 0o755)
        
        # Call the custom LLM script with temperature file and query
        # The script expects to be called like: ./run_local_llm.sh --json ~/temperature.json "question"
        result = subprocess.run(
            [LLM_SCRIPT_PATH, "--json", TEMP_JSON_PATH, user_query],
            capture_output=True,
            text=True,
            timeout=60
        )
        
        # Get the output
        output = result.stdout.strip()
        
        # Basic processing to clean up the output
        # Remove any lines that start with '>' which are input echoes
        lines = output.split('\n')
        response_lines = [line for line in lines if not line.startswith('>')]
        response_text = '\n'.join(response_lines).strip()
        
        # Get temperature data
        temp_data = get_current_temperature()
        
        # Return response and temperature data
        return jsonify({
            "response": response_text,
            "temperature": temp_data
        })
        
    except Exception as e:
        # Handle errors
        error_message = str(e)
        print(f"Error running LLM: {error_message}")
        
        return jsonify({
            "error": error_message,
            "temperature": get_current_temperature()
        })

# Start the Flask application when run directly
if __name__ == '__main__':
    print(f"Starting LLM API service with script: {LLM_SCRIPT_PATH}")
    print("API running on http://localhost:5000")
    
    # Run on all interfaces on port 5000
    app.run(host='0.0.0.0', port=5000, debug=True)