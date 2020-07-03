import mysql from 'mysql'

var connection =  mysql.createConnection({
    host: 'localhost',
    user: 'root',
    password: 'smarthome',
    database: 'smarthome'
});

export default connection;