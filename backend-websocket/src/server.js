import express from 'express';
import SocketIO from 'socket.io';
import connection from './db.js';
import socketioAuth from 'socketio-auth';
import jwtAuth from 'socketio-jwt-auth';
import socketioJwt from 'socketio-jwt';
import jwt from 'jsonwebtoken';
import bcrypt from 'bcrypt';
import generator from 'generate-password';

const secret = 'smarthome';
const saltRounds = 10;

let app = express();
var server = app.listen(8080);

// Parse URL-encoded bodies (as sent by HTML forms)
// app.use(express.urlencoded());

// Parse JSON bodies (as sent by API clients)
console.log('Server starting ...');
app.use(express.json());

app.use(express.urlencoded({ extended: true }))

//Check to make sure header is not undefined, if so, return Forbidden (403)
const checkToken = async (req, res, next) => {
    const header = req.headers['authorization'];

    if (typeof header !== 'undefined') {
        const bearer = header.split(' ');
        const token = bearer[1];

        req.token = token;
        await jwt.verify(token, secret, async (err, authorizedData) => {
            if (err) {
                //If error send Forbidden (403)
                console.log('ERROR: Could not connect to the protected route');
                res.sendStatus(403);
            } else {
                //If token is successfully verified, we can send the autorized data 
                console.log("authorized");
                next();
            }
        });
    } else {
        //If header is undefined return Forbidden (403)
        res.sendStatus(403)
    }
}

const mysqlQuery = (query, replacements) => {
    return new Promise(resolve => {
        connection.query(query, replacements, (error, rows, fields) => {
            resolve(JSON.parse(JSON.stringify(rows)));
        })
    });
}

app.post('/login', async (req, res) => {
    console.log("Login");

    const user = await mysqlQuery('SELECT * FROM user WHERE name = ? LIMIT 1', [req.body.username]);
    if (user.length) {
        const check = await bcrypt.compareSync(req.body.password, user[0].password);
        if (!check) {
            return res.json({ error: true, error_msg: 'Wrong credentials' });
        }
    } else {
        return res.json({ error: true, error_msg: 'Wrong credentials' });
    }
    var token = jwt.sign({ uid: user[0].id }, secret, { expiresIn: 86440 });
    return res.json({ error: false, token: token });
    //  resp.render('/home');
});

app.post('/user', checkToken, async (req, res) => {
    console.log("getUser");
    const { body } = req;
    const { id } = body;

    const user = await mysqlQuery('SELECT id, room_id, name, socket_id FROM user WHERE id = ? LIMIT 1', [id]);
    return res.json(user[0]);
});

app.post('/room', checkToken, async (req, res) => {
    console.log("get rooms");

    const room = await mysqlQuery('SELECT name FROM room');
    if (user.length) {
        const check = await bcrypt.compareSync(req.body.password, user[0].password);
        if (!check) {
            return res.json({ error: true, error_msg: 'Wrong credentials' });
        }
    } else {
        return res.json({ error: true, error_msg: 'Wrong credentials' });
    }
    var token = jwt.sign({ uid: user[0].id }, secret, { expiresIn: 86440 });
    return res.json({ error: false, token: token });
    //  resp.render('/home');
});

app.post('/devices', checkToken, async (req, res) => {
    console.log("getDevices");
    const { body } = req;
    const { id } = body;

    const devices = await mysqlQuery('SELECT id, room_id, name, mac_address, state, socket_id FROM device');
    console.log("devices: ");
    console.log(devices);
    return res.json(devices);
});

async function withTransaction(connection, callback) {
    try {
        await connection.beginTransaction();
        await callback();
        await connection.commit();
    } catch (err) {
        await connection.rollback();
        throw err;
    }
    // finally {
    //   await connection.close();
    // }
}

app.post('/signup', async (req, res) => {
    var username = req.body.username;

    try {
        const user = await mysqlQuery('SELECT * FROM user WHERE name = ?', [username]);
        if (user.length) {
            return res.status(400).json({ error: true, error_msg: 'User already exists' });
        }
        if (!user.length) {
            const password = generator.generate({
                length: 10,
                numbers: true,
            });
            console.log("password: " + password);
            const salt = await bcrypt.genSaltSync(saltRounds);
            const hash = await bcrypt.hashSync(password, salt);
            const response = await mysqlQuery('INSERT INTO user (name, password) VALUES (?, ?)', [username, hash]);
        }
    } catch (err) {
        console.log("Error: " + err);
        return res.json({ error: true });
    }
    return res.json({ error: false });
});

connection.query('CREATE TABLE IF NOT EXISTS room(room_id INT AUTO_INCREMENT PRIMARY KEY, name VARCHAR(255) NOT NULL)'), function (error, results, fields) {
    if (error) {
        console.log("error: ", error);
    } else if (results) {
        console.log("results: ", results);
    }
};

connection.query('CREATE TABLE IF NOT EXISTS device(id INT AUTO_INCREMENT PRIMARY KEY, room_id INT NULL, name VARCHAR(255), mac_address VARCHAR(17), socket_id VARCHAR(20), state BOOLEAN DEFAULT FALSE, CONSTRAINT fk_room_device FOREIGN KEY(room_id) REFERENCES room (room_id) ON DELETE SET NULL)'), function (error, results, fields) {
    if (error) {
        // throw error;
        console.log("error: ", error);
    } else if (results) {
    }
};

connection.query('CREATE TABLE IF NOT EXISTS user(id INT AUTO_INCREMENT PRIMARY KEY, room_id INT NULL, name VARCHAR(255) NOT NULL, password VARCHAR(60) NOT NULL, socket_id VARCHAR(20), CONSTRAINT fk_room_user FOREIGN KEY(room_id) REFERENCES room (room_id) ON DELETE SET NULL)', function (error, results, fields) {
    if (error) {
        // throw error;
        console.log("error: ", error);
    } else if (results) {
    }
});



const initEngineDevices = (io) => {

    io.on('connection', (socket) => {
        console.log('Device connected');
        // socket.emit('action', 'ON');
        socket.emit('getInit');

        io.emit('deviceConnected');

        socket.on('setUser', async (data) => {
            console.log("jwt: ", jwt.decode(data));
            const user_id = jwt.decode(data).uid;
            // const user_id = socket.decoded_token.uid;
            // console.log(`User ${user_id} socket connection`);
            const results = await mysqlQuery('UPDATE user SET socket_id = ? WHERE id = ?', [socket.id, user_id]);
        });

        socket.on('setAction', async (object) => {
            // console.log("action: ", action);
            const state = object.state == 1 ? 0 : 1;
            console.log("state: ", state);
            io.to(object.socket_id).emit('action', state);
        });

        socket.on('state', async (object) => {
            const result = await mysqlQuery('UPDATE device SET state = ? WHERE mac_address = ?', [object.state, object.mac]);
            io.emit('stateChanged');
        });

        socket.on('disconnect', async () => {
            let result = await mysqlQuery('UPDATE device SET socket_id = NULL WHERE socket_id = ?', [socket.id]);
            if (result && result.affectedRows == 0) {
                result = await mysqlQuery('UPDATE user SET socket_id = NULL WHERE socket_id = ?', [socket.id]);
            }
            else {
                io.emit('deviceDisconnected');
            }
        })

        socket.on('setInit', async (object) => {

            console.log("setInit: ", object);
            const results = await mysqlQuery('SELECT * FROM device WHERE mac_address = ?', [object.mac]);
            if (results.length == 0) {
                const results = await mysqlQuery(`INSERT INTO device(room_id, mac_address, socket_id, state) VALUES(NULL, "${object.mac}", "${socket.id}", "${object.state}"`);
            } else {
                const results = await mysqlQuery(`UPDATE device SET socket_id = "${socket.id}", state = ${object.state} WHERE mac_address = "${object.mac}"`);
            }
        }
        )
    });
};

const initEngineUsers = (io) => {

    io.use(socketioJwt.authorize({
        secret: secret,
        handshake: true,
    }));

    io.on('connection', (socket) => {
        const user_id = socket.decoded_token.uid;
        console.log(`User ${user_id} socket connection`);
        const results = mysqlQuery('UPDATE user SET socket_id = ? WHERE id = ?', [socket.id, user_id]);


        socket.on('disconnect', (socket) => {
            console.log("User disconnect");
            const results = mysqlQuery('UPDATE user SET socket_id = NULL WHERE id = ?', [user_id]);
        });
    });
};

const ioDevices = new SocketIO(server, {
    path: '/device',
    serveClient: false,
    // below are engine.IO options
    pingInterval: 10000,
    pingTimeout: 5000,
    cookie: false,
});

const ioUsers = new SocketIO(server, {
    path: '/user',
    serveClient: false,
    // below are engine.IO options
    pingInterval: 10000,
    pingTimeout: 5000,
    cookie: false,
});

initEngineDevices(ioDevices);
initEngineUsers(ioUsers);
