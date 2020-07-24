import express from 'express';
import SocketIO from 'socket.io';
// import connection from '.db.js';
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
  try {
    return new Promise(resolve => {
      connection.query(query, replacements, (error, rows, fields) => {
        resolve(JSON.parse(JSON.stringify(rows)));
      })
    });
  } catch (e) {
    console.log("error: ", e);
  }
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
});

app.post('/user', checkToken, async (req, res) => {
  console.log("getUser");
  const { body } = req;
  const { id } = body;

  const user = await mysqlQuery('SELECT * FROM user WHERE id = ?', [id]);
  return res.json(user);
});

app.post('/rooms', checkToken, async (req, res) => {
  console.log("get rooms");
  const rooms = await mysqlQuery('SELECT id, name FROM room');
  return res.json(rooms);
});

app.post('/rooms/:roomId', checkToken, async (req, res) => {
  console.log("get room");
  const roomId = req.params.roomId;
  const room = await mysqlQuery('SELECT id, name FROM room WHERE id = ?', [roomId]);
  return res.json(room);
});

app.post('/rooms/empty/:roomId', checkToken, async (req, res) => {
  console.log("get users room");
  const roomId = req.params.roomId;
  const room = await mysqlQuery('SELECT * FROM user WHERE room_id = ?', [roomId]);
  return res.json(room);
});

app.post('/devices/free', checkToken, async (req, res) => {
  console.log("devices/free");
  const devices = await mysqlQuery('SELECT * FROM device WHERE room_id IS NULL');
  return res.json(devices);
});

app.post('/devices/:roomId', checkToken, async (req, res) => {
  const roomId = req.params.roomId;
  const { body } = req;
  const { id } = body;

  const devices = await mysqlQuery('SELECT * FROM device WHERE room_id = ?', [roomId]);
  return res.json(devices);
});

app.post('/device/exist/:deviceId', checkToken, async (req, res) => {
  const deviceId = req.params.deviceId;
  const { body } = req;
  const { id } = body;

  const devices = await mysqlQuery('SELECT * FROM device WHERE id = ?', [deviceId]);
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

connection.query('CREATE TABLE IF NOT EXISTS room(id INT AUTO_INCREMENT PRIMARY KEY, name VARCHAR(255) NOT NULL)'), function (error, results, fields) {
  if (error) {
    console.log("error: ", error);
  } else if (results) {
    console.log("results: ", results);
  }
};

connection.query('CREATE TABLE IF NOT EXISTS device(id INT AUTO_INCREMENT PRIMARY KEY, room_id INT NULL, name VARCHAR(255), mac_address VARCHAR(17), socket_id NVARCHAR(20), state BOOLEAN DEFAULT FALSE, CONSTRAINT fk_room_device FOREIGN KEY(room_id) REFERENCES room (id) ON DELETE SET NULL)'), function (error, results, fields) {
  if (error) {
    // throw error;
    console.log("error: ", error);
  } else if (results) {
  }
};

connection.query('CREATE TABLE IF NOT EXISTS user(id INT AUTO_INCREMENT PRIMARY KEY, room_id INT NULL, name VARCHAR(255) NOT NULL, password VARCHAR(60) NOT NULL, socket_id VARCHAR(27), CONSTRAINT fk_room_user FOREIGN KEY(room_id) REFERENCES room (id) ON DELETE SET NULL)', function (error, results, fields) {
  if (error) {
    // throw error;
    console.log("error: ", error);
  } else if (results) {
  }
});



const initEngine = (io) => {

  // const devices_nsp = io.of('/devices');
  const users_nsp = io.of('/users');

  // users_nsp.use(socketioJwt.authorize({
  //   secret: secret,
  //   handshake: true,
  // }));

  users_nsp.on('connection', socketioJwt.authorize({
    secret: secret,
    timeout: 15000 // 15 seconds to send the authentication message
  })).on('authenticated', (socket) => {
  
  // async (socket) => {
    console.log("user connection authenticated");

    socket.on('setUserRoom', async (object) => {
      socket.join(object.room_id);
      console.log("setUserRoom object: ", object);

      const result = await mysqlQuery('UPDATE user SET room_id = ? WHERE socket_id = ?', [object.room_id, socket.id]);
    });

    socket.on('leaveUserRoom', async (object) => {
      console.log("leaveUserRoom object.room_id: ", object.room_id);
      socket.leave(object.room_id);
      const result = await mysqlQuery('UPDATE user SET room_id = NULL WHERE socket_id = ?', [socket.id]);
    });

    socket.on('setDeviceNameRoom', async (object) => {
      const result = await mysqlQuery('UPDATE device SET room_id = ?, name = ? WHERE id = ?', [object.room_id, object.name, object.id]);
      users_nsp.to(object.actual_room_id).emit('stateChanged', object.actual_room_id);
      if (object.room_id != object.actual_room_id) {
        users_nsp.to(object.room_id).emit('stateChanged', object.room_id);
      }
    });

    socket.on('addDeviceToRoom', async (object) => {
      const result = await mysqlQuery('UPDATE device SET room_id = ? WHERE id = ?', [object.room_id, object.device_id]);
      users_nsp.to(object.room_id).emit('stateChanged', object.room_id);
    });

    socket.on('removeDeviceFromRoom', async (object) => {
      console.log("object: ", object);
      const result = await mysqlQuery('UPDATE device SET room_id = NULL WHERE id = ?', [object.device_id]);
      users_nsp.to(object.room_id).emit('stateChanged', object.room_id);
    })

    socket.on('setUser', async (jwtString) => {
      if (jwtString) {
        let user_id = jwt.decode(jwtString).uid;
        const results = await mysqlQuery(`UPDATE user SET socket_id = ? WHERE id = ?`, [socket.id, user_id]);
      }
      else {
        socket.disconnect(true);
      }
    });

    socket.on('setAction', async (object, callback) => {
      const state = object.state == 1 ? 0 : 1;
      io.to(object.socket_id).emit('action', state);
      callback(true);
    });

    socket.on('updateRoomName', async (object) => {
      console.log("updateRoomName: ", object);
      const results = await mysqlQuery(`UPDATE room SET name = ? WHERE id = ?`, [object.room_name, object.room_id]);
      console.log("updateRoomName");
      // socket.emit('stateChangedRoom');
      users_nsp.emit('stateChangedRoom');
    });

    socket.on('addRoom', async (object) => {
      const results = await mysqlQuery('INSERT INTO room(name) VALUES(?)', [object.room_name]);
      users_nsp.emit('stateChangedRoom');
    });

    socket.on('deleteRoom', async (object) => {
      const results = await mysqlQuery('DELETE FROM room WHERE id = ?', [object.room_id]);
      users_nsp.emit('stateChangedRoom');
    });

    socket.on('disconnect', async () => {
      console.log("User disconnect");
      const results = await mysqlQuery('UPDATE user SET room_id = NULL, socket_id = NULL WHERE socket_id = ?', [socket.id]);
    });
  });

  io.on('connection', (socket) => {
    console.log('Device connected');
    socket.emit('getInit');

    // users_nsp.emit('stateChanged');

    // socket.on('setAction', async (object) => {
    //   const state = object.state == 1 ? 0 : 1;
    //   io.to(object.socket_id).emit('action', state);
    // });

    socket.on('state', async (object) => {
      const result = await mysqlQuery('UPDATE device SET state = ? WHERE mac_address = ?', [object.state, object.mac]);
      let results = await mysqlQuery('SELECT * FROM device WHERE mac_address = ? LIMIT 1', [object.mac]);
      const roomId = results[0].room_id;
      users_nsp.to(roomId).emit('stateChanged', roomId);
    });

    socket.on('disconnect', async () => {
      console.log("device dissconnect");
      let results = await mysqlQuery('SELECT * FROM device WHERE socket_id = ? LIMIT 1', [socket.id]);
      if (results.length) {
        const roomId = results[0].room_id;
        let result = await mysqlQuery('UPDATE device SET socket_id = NULL, state = 0 WHERE socket_id = ?', [socket.id]);
        if (roomId) {
          users_nsp.to(roomId).emit('stateChanged', roomId);
        }
      }
    });

    socket.on('setInit', async (object) => {
      var roomId = null;
      let results = await mysqlQuery('SELECT * FROM device WHERE mac_address = ? LIMIT 1', [object.mac]);
      if (results.length == 0) {
        results = await mysqlQuery(`INSERT INTO device(mac_address, socket_id, state) VALUES(?, ?, ?)`, [object.mac, socket.id, object.state]);
      } else {
        roomId = results[0].room_id;
        results = await mysqlQuery(`UPDATE device SET socket_id = ?, state = ? WHERE mac_address = ?`, [socket.id, object.state, object.mac]);
      }
      if (roomId != null) {
        users_nsp.to(roomId).emit('stateChanged', roomId);
      }
    });
  });
};

const ioEngine = new SocketIO(server, {
  path: '/smartHome',
  serveClient: false,
  // below are engine.IO options
  pingInterval: 10000,
  pingTimeout: 5000,
  cookie: false,
});

initEngine(ioEngine);
