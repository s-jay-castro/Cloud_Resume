async function updateWebCounter() {
  // Set API Gateway URL
  const apiUrl = 'https://hncd0z2k9j.execute-api.ap-southeast-2.amazonaws.com/get-count'; 

  try {
    const response = await fetch(apiUrl);
    
    if (!response.ok) {
      throw new Error(`HTTP error! Status: ${response.status}`);
    }

    const data = await response.json();
    
    // Updates the HTML element with the new count
    document.getElementById('counter-display').innerText = data.count;
  } catch (error) {
    console.error('Failed to update counter:', error);
    document.getElementById('counter-display').innerText = "Error loading";
  }
}

// Run the function when the page loads
window.addEventListener('DOMContentLoaded', updateWebCounter);
