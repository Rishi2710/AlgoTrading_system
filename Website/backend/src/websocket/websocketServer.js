const WebSocket = require('ws');
const db = require('../config/dbConfig');
const talib = require('talib'); // Example: if using TA-Lib, a popular technical analysis library

function setupWebSocketServer(server) {
    const wss = new WebSocket.Server({ server });
    let latestTimestamp = null; 

    wss.on('connection', async (ws) => {
        console.log('WebSocket connection established');

        try {
            await sendLatestData(ws);
        } catch (err) {
            console.error('Error sending initial data:', err);
        }

        ws.on('close', () => {
            console.log('WebSocket connection closed');
        });

        ws.on('error', (error) => {
            console.error('WebSocket error:', error);
        });
    });

    async function sendLatestData(ws) {
        try {
            const result = await db.query('SELECT * FROM stocks_real_time ORDER BY time DESC LIMIT 1');
            if (result.rows.length > 0) {
                const enrichedData = await calculateIndicators(result.rows[0]);
                ws.send(JSON.stringify(enrichedData));
                latestTimestamp = result.rows[0].time;
            } else {
                ws.send(JSON.stringify({ error: 'No data available' }));
            }
        } catch (err) {
            console.error('Database query error:', err);
            ws.send(JSON.stringify({ error: 'Database query error' }));
        }
    }

    async function calculateIndicators(latestData) {
        // Fetch the last 20 rows to calculate indicators
        const result = await db.query('SELECT * FROM stocks_real_time ORDER BY time DESC LIMIT 20');
        const rows = result.rows.reverse(); // Reverse to have the oldest data first

        // Ensure we have enough data points
        if (rows.length < 20) {
            return latestData; // Return data as is if we don't have enough for calculation
        }

        const closePrices = rows.map(row => row.close_price);

        // Calculate indicators
        const sma = talib.SMA(closePrices, { period: 20 });
        const macd = talib.MACD(closePrices, { fastPeriod: 12, slowPeriod: 26, signalPeriod: 9 });
        const rsi = talib.RSI(closePrices, { period: 14 });
        const bbands = talib.BBANDS(closePrices, { period: 20, nbdevup: 2, nbdevdn: 2 });

        // Add indicators to the latest data point
        latestData.sma_20 = sma[sma.length - 1];
        latestData.macd = macd.outMACD[macd.outMACD.length - 1];
        latestData.macd_signal = macd.outMACDSignal[macd.outMACDSignal.length - 1];
        latestData.rsi = rsi[rsi.length - 1];
        latestData.bb_upper = bbands.outRealUpperBand[bbands.outRealUpperBand.length - 1];
        latestData.bb_middle = bbands.outRealMiddleBand[bbands.outRealMiddleBand.length - 1];
        latestData.bb_lower = bbands.outRealLowerBand[bbands.outRealLowerBand.length - 1];

        return latestData;
    }

    async function checkForNewEntries() {
        try {
            const query = latestTimestamp ? 
                'SELECT * FROM stocks_real_time WHERE time > $1 ORDER BY time ASC' : 
                'SELECT * FROM stocks_real_time ORDER BY time ASC';
            
            const params = latestTimestamp ? [latestTimestamp] : [];
            
            const result = await db.query(query, params);
            if (result.rows.length > 0) {
                for (const row of result.rows) {
                    const enrichedData = await calculateIndicators(row);
                    wss.clients.forEach((client) => {
                        if (client.readyState === WebSocket.OPEN) {
                            client.send(JSON.stringify(enrichedData));
                        }
                    });
                    latestTimestamp = row.time;
                }
            }
        } catch (err) {
            console.error('Database query error:', err);
        }
    }

    setInterval(checkForNewEntries, 60000);

    return wss;
}

module.exports = setupWebSocketServer;