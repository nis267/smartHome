// import mysql from 'mysql'
var mysql = require('mysql');

var connection =  mysql.createConnection({
    host: 'localhost',
    user: 'root',
    password: 'smarthome',
    database: 'smarthome',
    charset : 'utf8mb4'
});

// export default connection;
module.exports = connection;