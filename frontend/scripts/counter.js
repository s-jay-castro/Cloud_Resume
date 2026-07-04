async function updateWebCounter() {
  // Set API Gateway URL
  const apiUrl = 'https://ve1vep52cg.execute-api.ap-southeast-2.amazonaws.com/default/addVisitorRefresh'; 

  try {
    const response = await fetch(apiUrl, { method: 'POST' }); // Use 'GET' if your API relies on GET
    
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
