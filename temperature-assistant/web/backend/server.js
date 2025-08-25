// Import required modules
const express = require('express');  // Web server framework
const cors = require('cors');        // Handle cross-origin requests
const axios = require('axios');      // Make HTTP requests
const path = require('path');        // Work with file paths

// Initialize Express app
const app = express();
const PORT = 3000;                   // Port for web server
const API_URL = 'http://localhost:5000/api';  // Flask API URL

// Middleware setup
app.use(express.json());             // Parse JSON requests
app.use(cors());                     // Enable CORS
app.use(express.static(path.join(__dirname, '../frontend'))); // Serve frontend files

// API endpoint to get temperature data
app.get('/api/temperature', async (req, res) => {
  try {
    // Forward request to Flask API
    const response = await axios.get(`${API_URL}/temperature`);
    res.json(response.data);
  } catch (error) {
    console.error('Error fetching temperature:', error.message);
    res.status(500).json({ error: 'Failed to fetch temperature data' });
  }
});

// API endpoint to send questions to LLM
app.post('/api/ask', async (req, res) => {
  try {
    // Forward question to Flask API
    console.log(`Received question: ${req.body.query}`);
    const response = await axios.post(`${API_URL}/ask`, {
      query: req.body.query
    });
    res.json(response.data);
  } catch (error) {
    console.error('Error asking LLM:', error.message);
    res.status(500).json({ error: 'Failed to get response from LLM' });
  }
});

// Start the server
app.listen(PORT, '0.0.0.0', () => {
  console.log(`Web server running on http://localhost:${PORT}`);
});