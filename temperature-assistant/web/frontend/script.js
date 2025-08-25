// Wait for the DOM to be fully loaded
document.addEventListener('DOMContentLoaded', function() {
  // Get elements from the page
  const tempCelsius = document.getElementById('temp-celsius');
  const tempFahrenheit = document.getElementById('temp-fahrenheit');
  const timestamp = document.getElementById('timestamp');
  const refreshBtn = document.getElementById('refresh-btn');
  const questionInput = document.getElementById('question-input');
  const askButton = document.getElementById('ask-button');
  const responseContainer = document.getElementById('response-container');
  const exampleButtons = document.querySelectorAll('.example-btn');
  
  // Fetch current temperature from the API
  async function fetchTemperature() {
    try {
      // Show loading state
      tempCelsius.textContent = 'Loading...';
      tempFahrenheit.textContent = '';
      
      // Fetch data from API
      const response = await fetch('/api/temperature');
      
      if (!response.ok) {
        throw new Error(`Error: ${response.status}`);
      }
      
      // Parse JSON response
      const data = await response.json();
      
      // Update temperature display
      tempCelsius.textContent = formatTemperature(data.celsius);
      tempFahrenheit.textContent = formatTemperature(data.fahrenheit);
      timestamp.textContent = formatTimestamp(data.timestamp);
      
      // Update temperature color
      updateTemperatureColor(data.celsius);
      
    } catch (error) {
      console.error('Error fetching temperature:', error);
      tempCelsius.textContent = '--';
      tempFahrenheit.textContent = '--';
      
      // Show error message
      showError('Failed to fetch temperature data');
    }
  }
  
  // Format temperature to one decimal place
  function formatTemperature(value) {
    if (typeof value === 'number') {
      return value.toFixed(1);
    }
    return '--';
  }
  
  // Format timestamp to readable format
  function formatTimestamp(timestamp) {
    if (!timestamp || timestamp === 'unknown') {
      return '--';
    }
    
    try {
      const date = new Date(timestamp);
      return date.toLocaleString();
    } catch (error) {
      return timestamp;
    }
  }
  
  // Add color class based on temperature
  function updateTemperatureColor(celsius) {
    tempCelsius.className = '';
    
    if (celsius < 16) {
      tempCelsius.classList.add('temp-cold');
    } else if (celsius < 20) {
      tempCelsius.classList.add('temp-cool');
    } else if (celsius < 24) {
      tempCelsius.classList.add('temp-comfortable');
    } else if (celsius < 28) {
      tempCelsius.classList.add('temp-warm');
    } else {
      tempCelsius.classList.add('temp-hot');
    }
  }
  
  // Ask a question to the LLM
  async function askQuestion(question) {
    try {
      // Show loading state
      responseContainer.innerHTML = '<p class="loading">Thinking... (this may take 30-60 seconds)</p>';
      
      // Send question to API
      const response = await fetch('/api/ask', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json'
        },
        body: JSON.stringify({ query: question })
      });
      
      if (!response.ok) {
        throw new Error(`Error: ${response.status}`);
      }
      
      // Parse response
      const data = await response.json();
      
      if (data.error) {
        throw new Error(data.error);
      }
      
      // Format and display response
      responseContainer.innerHTML = `<div>${formatResponse(data.response)}</div>`;
      
    } catch (error) {
      console.error('Error asking question:', error);
      responseContainer.innerHTML = `<p class="error">Error: ${error.message}</p>`;
    }
  }
  
  // Format the response text
  function formatResponse(text) {
    if (!text) {
      return 'No response received.';
    }
    
    // Escape HTML to prevent XSS
    text = text
      .replace(/&/g, "&amp;")
      .replace(/</g, "&lt;")
      .replace(/>/g, "&gt;")
      .replace(/"/g, "&quot;")
      .replace(/'/g, "&#039;");
    
    // Convert newlines to <br>
    return text.replace(/\n/g, '<br>');
  }
  
  // Show an error message
  function showError(message) {
    const errorElement = document.createElement('div');
    errorElement.className = 'error';
    errorElement.textContent = message;
    
    document.querySelector('.container').insertBefore(
      errorElement,
      document.querySelector('.temp-card')
    );
    
    setTimeout(() => {
      errorElement.remove();
    }, 5000);
  }
  
  // Event listener for refresh button
  refreshBtn.addEventListener('click', fetchTemperature);
  
  // Event listener for ask button
  askButton.addEventListener('click', function() {
    const question = questionInput.value.trim();
    if (question) {
      askQuestion(question);
    }
  });
  
  // Event listeners for example buttons
  exampleButtons.forEach(button => {
    button.addEventListener('click', function() {
      const question = this.getAttribute('data-question');
      questionInput.value = question;
      askQuestion(question);
    });
  });
  
  // Fetch temperature on page load
  fetchTemperature();
  
  // Set up automatic refresh every minute
  setInterval(fetchTemperature, 60000);
});