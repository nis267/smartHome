var express = require('express');
var SocketIO = require('socket.io');
var connection = require('./db.js');
var socketioAuth = require('socketio-auth');
var socketioJwt = require('socketio-jwt');
var jwt = require('jsonwebtoken');
var bcrypt = require('bcrypt');
var generator = require('generate-password');
var fs = require('fs');
var shell = require('shelljs');
var validator = require("email-validator");
var nodemailer = require('nodemailer'); 

const secret_user = 'smarthome_user';
const secret_device = 'smarthome_device';
const saltRounds = 10;
const port = 80;
const python_display_script_pid_file = '/tmp/server_smarthome/server_python_display_pid';
const status_dir = '/tmp/server_smarthome/status/';
const new_users_dir = '/tmp/server_smarthome/new_users/';
const users_status_file = 'users';
const devices_status_file = 'devices';
const account_active_timeout = 600000;

let app = express();
var server = app.listen(port);

const send_hangup_to_python_script_display = () => {
  try {
    if (fs.existsSync(python_display_script_pid_file)) {
      const pid = fs.readFileSync(python_display_script_pid_file, 'utf8');
      process.kill(pid, "SIGHUP");
    }
  } catch (err) {
    console.error(err);
  }
}
const write_to_file = (dir, file, data) => {
  try {
    console.log("dir: ", dir);
    if (!fs.existsSync(dir)) {
      console.log("create dir");
      shell.mkdir('-p', dir);
    }
    console.log("create dir");
    fs.writeFileSync(dir + file, data);
    console.log(`File ${file} written successfully`);
  } catch (err) {
    console.error(err);
  }
  send_hangup_to_python_script_display();
}

console.log('Server starting ...');
app.use(express.json());

app.use(express.urlencoded({ extended: true }))

//Check to make sure header is not undefined, if so, return Forbidden (403)
const checkToken = async (req, res, next, secret) => {
  console.log("here checktoken");
  const header = req.headers['authorization'];

  if (typeof header !== 'undefined') {
    const bearer = header.split(' ');
    const token = bearer[1];

    req.token = token;
    await jwt.verify(token, secret_user, async (err, authorizedData) => {
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

const delete_file = (path) => {
  try {
    if (fs.existsSync(path)) {
      //file exists
      fs.unlinkSync(path);
    }
  } catch(err) {
    console.error(err)
  }
}

app.post('/login', async (req, res) => {
  console.log("Login");

  // check for basic auth header
  if (!req.headers.authorization || req.headers.authorization.indexOf('Basic ') === -1) {
    return res.status(401).json({ message: 'Missing Authorization Header' });
  }
  const base64Credentials = req.headers.authorization.split(' ')[1];
  const credentials = Buffer.from(base64Credentials, 'base64').toString('ascii');
  const [username, password] = credentials.split(':');

  const user = await mysqlQuery('SELECT * FROM user WHERE name = ? LIMIT 1', [username]);
  if (user.length) {
    const check = await bcrypt.compareSync(password, user[0].password);
    if (!check) {
      if (user[0].forgot_password) {
        const check_forgot_password = await bcrypt.compareSync(password, user[0].forgot_password);
        if (check_forgot_password) {
          await mysqlQuery('UPDATE user SET password_changed = FALSE WHERE name = ?', [username]);
        } else {
          return res.json({ error: true, error_msg: 'Wrong credentials' });
        }
      }
      else {
        return res.json({ error: true, error_msg: 'Wrong credentials' });
      }
    } else if (user[0].forgot_password){
      await mysqlQuery('UPDATE user SET forgot_password = NULL WHERE name = ?', [username]);
    }
  } else {
    return res.json({ error: true, error_msg: 'Wrong credentials' });
  }
  
  var token = jwt.sign({ uid: user[0].id }, secret_user, { expiresIn: 86440 });
  return res.json({ error: false, token: token });
});

app.get('/apk', async (req, res) => {
  const file = `${__dirname}/app.apk`;
  res.download(file);
});

app.post('/login_device', async (req, res) => {
  console.log('Login device');
  // check for basic auth header
  if (!req.headers.authorization || req.headers.authorization.indexOf('Basic ') === -1) {
    return res.status(401).json({ message: 'Missing Authorization Header' });
  }
  const base64Credentials = req.headers.authorization.split(' ')[1];
  const credentials = Buffer.from(base64Credentials, 'base64').toString('ascii');
  const [mac_address, password] = credentials.split(':');

  if (mac_address.length) {
    var mac_address_modified = mac_address.replace(/\./g, ":");
  }
  console.log("password: ", password);
  var device = await mysqlQuery('SELECT * FROM device WHERE mac_address = ? LIMIT 1', [mac_address_modified]);
  if (device.length) {
    const check = await bcrypt.compareSync(password, device[0].password);
    if (!check) {
      return res.json({ error: true, error_msg: 'Wrong credentials' });
    }
  } else {
    device = await mysqlQuery('SELECT * FROM device WHERE (mac_address IS NULL AND password IS NOT NULL) LIMIT 1');
    if (!device.length) {
      return res.json({ error: true, error_msg: 'No password available' });
    }
    const check = await bcrypt.compareSync(password, device[0].password);
    if (!check) {
      return res.json({ error: true, error_msg: 'Wrong credentials' });
    }
    const results = await mysqlQuery(`UPDATE device SET mac_address = ? WHERE id = ?`, [mac_address_modified, device[0].id]);
  }
  var token = jwt.sign({ did: device[0].id }, secret_device, { expiresIn: 86440 });
  return res.json({ error: false, token: token });
});

app.post('/user', checkToken, async (req, res) => {
  console.log("getUser");
  const { body } = req;
  const { id } = body;

  const user = await mysqlQuery('SELECT * FROM user WHERE id = ?', [id]);
  return res.json(user);
});

app.post('/user/new_user_name/:id', checkToken, async (req, res) => {
  console.log("new_user_name");
  const userId = req.params.id;
  var new_username = req.body.new_username;

  const user = await mysqlQuery('SELECT * FROM user WHERE name = ?', [new_username]);
  console.log("user here: ", new_username);
  console.log("user: ", user);
  if (user.length) {
    return res.status(400).json({ error: true, error_msg: 'User already exists' });
  }

  const user_update = await mysqlQuery('UPDATE user SET name = ? WHERE id = ?', [new_username, userId]);
  return res.json({ error: false });
});

app.post('/user/forgot_password/', async (req, res) => {
  console.log("forgot_password");
  // Your username has not been recognized
  var username = req.body.username;
  
  try {
    const user = await mysqlQuery('SELECT * FROM user WHERE name = ?', [username]);
    if (!user.length) {
      return res.status(400).json({ error: true, error_msg: 'Your username has not been recognized' });
    }
    if (!user[0].activated) {
      return res.status(400).json({ error: true, error_msg: 'Account not activated' });
    }

    const password = generator.generate({
      length: 10,
      numbers: true,
    });
    var transporter = nodemailer.createTransport({
      service: 'gmail',
      auth: {
        user: 'smarthome42101@gmail.com',
        pass: '15360570smarthome42101'
      }
    });
    
    var mailOptions = {
      from: 'smarthome42101@gmail.com',
      to: user[0].email,
      subject: 'New password smarthome account',
      text: `Username: ${username}\nPassword: ${password}`
    };
    
    transporter.sendMail(mailOptions, function(error, info) {
      if (error) {
        console.log(error);
      } else {
        console.log('Email sent: ' + info.response);
      }
    });
    const salt = await bcrypt.genSaltSync(saltRounds);
    const hash = await bcrypt.hashSync(password, salt);
    const user_update = await mysqlQuery('UPDATE user SET forgot_password = ? WHERE id = ?', [hash, user[0].id]);

  } catch (err) {
    return res.json({ error: true });
  }
  return res.json({ error: false });
});

app.post('/user/choose_password/:id', checkToken, async (req, res) => {
  console.log("choose_password");
  const userId = req.params.id;
  var new_password = req.body.new_password;
  var confirm_new_password = req.body.confirm_new_password;

  const user = await mysqlQuery('SELECT * FROM user WHERE id = ? LIMIT 1', [userId]);
  if (user.length) {
    if (new_password != confirm_new_password) {
      return res.json({ error: true, error_msg: 'Password\'s does not match' });
    }
    if (new_password.length < 6) {
      return res.json({ error: true, error_msg: 'Password must be at least 6 characters' });
    }
  }
  else {
    return res.json({ error: true, error_msg: 'Wrong credentials' });
  }
  const salt = await bcrypt.genSaltSync(saltRounds);
  const hash = await bcrypt.hashSync(new_password, salt);
  const user_update = await mysqlQuery('UPDATE user SET password = ?, password_changed = TRUE, forgot_password = NULL WHERE id = ?', [hash, userId]);
  return res.json({ error: false });
});

app.post('/user/new_email/:id', checkToken, async (req, res) => {
  console.log("new_email");
  const userId = req.params.id;
  var new_email = req.body.new_email;

  const user = await mysqlQuery('SELECT * FROM user WHERE id = ? LIMIT 1', [userId]);
  if (user.length) {
    if (!validator.validate(new_email)) {
      return res.json({ error: true, error_msg: 'Invalid email address' });
    }
  }
  else {
    return res.json({ error: true, error_msg: 'Wrong credentials' });
  }
  if (!user[0].activated) {
    delete_file(new_users_dir + user[0].id);
    console.log("file deleted");
    await mysqlQuery('UPDATE user SET activated = TRUE WHERE id = ?', [user[0].id]);
  }
  const user_update = await mysqlQuery('UPDATE user SET email = ?, email_entered = TRUE WHERE id = ?', [new_email, userId]);
  return res.json({ error: false });
});

app.post('/user/change_password/:id', checkToken, async (req, res) => {
  console.log("change_password");
  const userId = req.params.id;
  var password = req.body.password;
  var new_password = req.body.new_password;
  var confirm_new_password = req.body.confirm_new_password;

  const user = await mysqlQuery('SELECT * FROM user WHERE id = ? LIMIT 1', [userId]);
  if (user.length) {
    const check = await bcrypt.compareSync(password, user[0].password);
    if (!check) {
      return res.json({ error: true, actual_password: true, error_msg: 'Actual password wrong' });
    }
    if (password == new_password) {
      return res.json({ error: true, actual_password: false, error_msg: 'New password same as current password' });
    }
    if (new_password != confirm_new_password) {
      return res.json({ error: true, actual_password: false, error_msg: 'New password and confirm password does not match' });
    }
    if (new_password.length < 6) {
      return res.json({ error: true, actual_password: false, error_msg: 'Password must be at least 6 characters' });
    }

  }
  else {
    return res.json({ error: true, actual_password: true, error_msg: 'Wrong credentials' });
  }
  const salt = await bcrypt.genSaltSync(saltRounds);
  const hash = await bcrypt.hashSync(new_password, salt);
  const user_update = await mysqlQuery('UPDATE user SET password = ? WHERE id = ?', [hash, userId]);
  return res.json({ error: false });
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
  const devices = await mysqlQuery('SELECT * FROM device WHERE (room_id IS NULL AND mac_address IS NOT NULL)');
  return res.json(devices);
});

app.post('/devices/unused', checkToken, async (req, res) => {
  console.log("devices/unused here");
  const devices = await mysqlQuery('SELECT * FROM device WHERE room_id IS NULL AND mac_address IS NOT NULL');
  return res.json(devices);
});

app.post('/devices/:roomId', checkToken, async (req, res) => {
  const roomId = req.params.roomId;
  const { body } = req;
  const { id } = body;

  const devices = await mysqlQuery('SELECT * FROM device WHERE room_id = ?', [roomId]);
  return res.json(devices);
});

app.post('/device/remove', checkToken, async (req, res) => {
  const { body } = req;
  const { devices_ids } = body;

  console.log("devices_ids: ", devices_ids);
  const result = await mysqlQuery('DELETE FROM device WHERE id IN(?)', [devices_ids]);
  console.log("result", result);
  return res.json(true);
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

const delete_non_activated_user_timeout = async (user_id)  => {
  console.log("delete user");
  const user = await mysqlQuery('SELECT * FROM user WHERE id = ? AND activated = FALSE', [user_id]);
  if (user.length) {
    const result = await mysqlQuery('DELETE FROM user WHERE id = ?', [user_id]);
    delete_file(new_users_dir + String(user_id));
    send_hangup_to_python_script_display();
  }
}

app.post('/signup', async (req, res) => {
  var username = req.body.username;

  try {
    const user = await mysqlQuery('SELECT * FROM user WHERE name = ?', [username]);
    if (user.length) {
      return res.status(400).json({ error: true, error_msg: 'User already exists' });
    }
    const password = generator.generate({
      length: 10,
      numbers: true,
    });
    const salt = await bcrypt.genSaltSync(saltRounds);
    const hash = await bcrypt.hashSync(password, salt);
    await mysqlQuery('INSERT INTO user (name, password) VALUES (?, ?)', [username, hash]);
    const new_user = await mysqlQuery('SELECT * FROM user WHERE name = ?', [username]);
    write_to_file(new_users_dir, String(new_user[0].id), new_user[0].name + "\n" + password);
    setTimeout(delete_non_activated_user_timeout, account_active_timeout, new_user[0].id);
  } catch (err) {
    console.log("Error: " + err);
    return res.json({ error: true });
  }
  return res.json({ error: false });
});

app.post('/device/signup', checkToken, async (req, res) => {
  console.log('device signup');

  var password = null;
  const result = await mysqlQuery('DELETE FROM device WHERE (mac_address IS NULL AND password IS NOT NULL)');
  try {
    password = generator.generate({
      length: 10,
      numbers: true,
    });
    console.log("device password: ", password);
    const salt = await bcrypt.genSaltSync(saltRounds);
    const hashed_password = await bcrypt.hashSync(password, salt);
    const response = await mysqlQuery('INSERT INTO device (password) VALUES (?)', [hashed_password]);

  } catch (err) {
    return res.json({ error: true, error_msg: err });
  }
  return res.json({ error: false, password: password });
});



connection.query('CREATE TABLE IF NOT EXISTS room(id INT AUTO_INCREMENT PRIMARY KEY, name VARCHAR(255) NOT NULL)'), function (error, results, fields) {
  if (error) {
    console.log("error: ", error);
  } else if (results) {
    console.log("results: ", results);
  }
};

connection.query('CREATE TABLE IF NOT EXISTS device(id INT AUTO_INCREMENT PRIMARY KEY, room_id INT NULL, name VARCHAR(255), password VARCHAR(60) NOT NULL, mac_address VARCHAR(17), socket_id VARCHAR(29), state BOOLEAN DEFAULT FALSE, CONSTRAINT fk_room_device FOREIGN KEY(room_id) REFERENCES room (id) ON DELETE SET NULL)'), function (error, results, fields) {
  if (error) {
    // throw error;
    console.log("error: ", error);
  } else if (results) {
  }
};

connection.query('CREATE TABLE IF NOT EXISTS user(id INT AUTO_INCREMENT PRIMARY KEY, room_id INT NULL, name VARCHAR(255) NOT NULL, password VARCHAR(60) NOT NULL, forgot_password VARCHAR(60), email VARCHAR(320), socket_id VARCHAR(27), activated BOOLEAN DEFAULT FALSE, password_changed BOOLEAN DEFAULT FALSE, email_entered BOOLEAN DEFAULT FALSE, CONSTRAINT fk_room_user FOREIGN KEY(room_id) REFERENCES room (id) ON DELETE SET NULL)', function (error, results, fields) {
  if (error) {
    // throw error;
    console.log("error: ", error);
  } else if (results) {
  }
});

const initEngine = (io) => {

  var devices_nsp = io.of('/devices');

  devices_nsp.on('connection', socketioJwt.authorize({
    secret: secret_device,
    timeout: 15000 // 15 seconds to send the authentication message
  })).on('authenticated', (socket) => {
    console.log('device namespace connected');
    console.log("device socket.id", socket.id);
    // socket.emit('getInit');
    devices_nsp.to(socket.id).emit('getInit');

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
      const status = await mysqlQuery('select count(socket_id) connected from device');
      write_to_file(status_dir, devices_status_file, String(status[0].connected));
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
      const status = await mysqlQuery('select count(socket_id) connected from device');
      write_to_file(status_dir, devices_status_file, String(status[0].connected));
    });
    // });

  });

  var users_nsp = io.of('/users');

  users_nsp.on('connection', socketioJwt.authorize({
    secret: secret_user,
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

    socket.on('updateDevice', async (device_object) => {
      const device = await mysqlQuery('SELECT * FROM device WHERE id = ?', [device_object.id]);
      if (device.length) {
        const result = await mysqlQuery('UPDATE device SET room_id = ?, name = ? WHERE id = ?', [device_object.roomId, device_object.name, device_object.id]);
        users_nsp.to(device[0].room_id).emit('stateChanged', device[0].room_id);
        if (device[0].room_id != device_object.roomId) {
          users_nsp.to(device_object.roomId).emit('stateChanged', device_object.roomId);
        }
      }
    });

    socket.on('addDevicesToRoom', async (object) => {
      console.log("addDevicesToRoom: ", object);
      const result = await mysqlQuery('UPDATE device SET room_id = ? WHERE id IN(?)', [object.room_id, object.devices_ids]);
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
        const status = await mysqlQuery('select count(socket_id) connected from user');
        console.log("results: ", status[0].connected);
        write_to_file(status_dir, users_status_file, String(status[0].connected));
      }
      else {
        socket.disconnect(true);
      }
    });

    socket.on('setAction', async (object) => {
      const socket_id_split = object.socket_id.split('#')[1];
      io.to(socket_id_split).emit('action');
    });

    socket.on('updateRoom', async (object) => {
      console.log("updateRoom id: ", object.id);
      console.log("updateRoom name: ", object.name);
      const results = await mysqlQuery(`UPDATE room SET name = ? WHERE id = ?`, [object.name, object.id]);
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
      const status = await mysqlQuery('select count(socket_id) connected from user');
      write_to_file(status_dir, users_status_file, String(status[0].connected));  
    });
  })
    .on('unauthorized', (msg) => {
      console.log(`unauthorized: ${JSON.stringify(msg.data)}`);
      // throw new Error(msg.data.type);
    });

  // io.on('connection', (socket) => {
  //   console.log("io socketId: ", socket.id);

  // });
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
