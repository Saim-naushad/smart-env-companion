#!/usr/bin/env python3

# Import necessary libraries
import time                     # For adding delays between readings
import board                    # For accessing Raspberry Pi hardware pins
import adafruit_mcp9808         # The MCP9808 temperature sensor library
import json                     # For saving data in JSON format
import os                       # For handling file paths

# Print a startup message so we know the program has started
print("MCP9808 Temperature Sensor Reader")
print("--------------------------------")
print("Press CTRL+C to exit")
print()

# Path for saving temperature data (in user's home directory)
JSON_FILE_PATH = os.path.expanduser('~/temperature.json')
try:
    # Create an I2C interface object - this is how we talk to the sensor
    # board.I2C() automatically uses the correct GPIO pins (2 and 3) for I2C communication
    i2c = board.I2C()  # Uses board.SCL and board.SDA
    
    # Create the sensor object using the I2C interface
    # This establishes communication with the MCP9808 sensor at address 0x18
    sensor = adafruit_mcp9808.MCP9808(i2c)
    
    print("Sensor initialized successfully!")
    print("Starting temperature readings...\n")
    print(f"Saving data to: {JSON_FILE_PATH}")
    print()
    
    # Main loop - this runs continuously
    while True:
        # Read the temperature from the sensor (in Celsius)
        celsius = sensor.temperature
        # Convert Celsius to Fahrenheit using the formula: F = C × (9/5) + 32
        fahrenheit = celsius * 9 / 5 + 32
        # Get current timestamp in a human-readable format
        timestamp = time.strftime("%Y-%m-%d %H:%M:%S")
        # Print the current temperature in both units
        # The :.2f format specifier shows 2 decimal places
        print(f"[{timestamp}] Temperature: {celsius:.2f}°C ({fahrenheit:.2f}°F)")
        # Create a dictionary with the temperature data
        # This makes it easy to convert to JSON format
        temp_data = {
            "celsius": celsius,
            "fahrenheit": fahrenheit,
            "timestamp": timestamp
        }
        # Save the temperature data to a JSON file
        # This file will be read by other parts of the system
        try:
            with open(JSON_FILE_PATH, 'w') as f:
                json.dump(temp_data, f)
        except Exception as e:
            print(f"Warning: Could not save to {JSON_FILE_PATH}: {e}")
        # Wait for 60 seconds before taking the next reading
        time.sleep(60)
except KeyboardInterrupt:
    # This code runs when you press CTRL+C to stop the program
    print("\nProgram stopped by user")
    
except Exception as e:
    # This code runs if any error occurs
    print(f"\nAn error occurred: {e}")
    
finally:
    # This code always runs before the program exits
    print("\nExiting temperature reader")