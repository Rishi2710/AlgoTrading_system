const WebSocket = require('ws');

// Replace with the correct WebSocket URL (e.g., ws://localhost:5000)
const ws = new WebSocket('ws://localhost:5000');

ws.on('open', () => {
    console.log('WebSocket connection opened');
    
    // Send a test message to the server
    ws.send(JSON.stringify({ message: 'Hello, server!' }));
});

ws.on('message', (event) => {
    // Handle cases where event.data might not exist or be undefined
    if (event) {
        // If the data is a buffer or needs conversion
        const dataStr = typeof event === 'string' ? event : event.toString();
        console.log('Raw data from server:', dataStr);

        // Parse the string as JSON if it's a JSON string
        try {
            const data = JSON.parse(dataStr);
            console.log('Parsed message from server:', data);
        } catch (error) {
            console.error('Error parsing message from server:', error);
        }
    } else {
        console.error('No data received from server');
    }
});

ws.on('error', (error) => {
    console.error('WebSocket error:', error);
});

ws.on('close', () => {
    console.log('WebSocket connection closed');
});