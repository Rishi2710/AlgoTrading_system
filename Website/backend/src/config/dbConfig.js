const { Pool } = require('pg');

const pool = new Pool({
    user: 'rishit',        // Replace with your PostgreSQL username
    host: 'localhost',            // Assuming the database is local
    database: 'trading_data',     // Replace with your database name
    password: '1234',    // Replace with your PostgreSQL password
    port: 5432,                   // The default port for PostgreSQL
});

module.exports = pool;