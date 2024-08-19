const express = require('express');
const cors = require('cors');
const setupWebSocketServer = require('./src/websocket/websocketServer');
const db = require('./src/config/dbConfig');

const app = express();
const PORT = process.env.PORT || 5000;

// Middleware setup
app.use(cors());
app.use(express.json());

// Basic route for testing
app.get('/', (req, res) => res.send('Trading Simulator API Running'));

// Start server and setup WebSocket
const server = app.listen(PORT, () => console.log(`Server running on port ${PORT}`));

setupWebSocketServer(server);

module.exports = app;