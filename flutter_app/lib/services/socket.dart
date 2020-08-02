import 'package:flutter_app/models/user.dart';
import 'package:flutter_phoenix/flutter_phoenix.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:flutter_app/models/device.dart';
import 'package:flutter_app/models/room.dart';
import 'dart:async';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_app/services/http_request.dart';
import 'package:flutter/foundation.dart';
import '../globals.dart' as globals;

List<Device> parsedDevices(dynamic response) {
  final parsed = response.cast<Map<String, dynamic>>();

  return parsed.map<Device>((json) => Device.fromJson(json)).toList();
}

Future<List<Device>> isolateDevices(dynamic response) async {
  return compute(parsedDevices, response);
}

List<Room> parsedRooms(dynamic response) {
  final parsed = response.cast<Map<String, dynamic>>();

  return parsed.map<Room>((json) => Room.fromJson(json)).toList();
}

Future<List<Room>> isolateRooms(dynamic response) async {
  return compute(parsedRooms, response);
}

List<User> parsedUsers(dynamic response) {
  final parsed = response.cast<Map<String, dynamic>>();

  return parsed.map<User>((json) => User.fromJson(json)).toList();
}

Future<List<User>> isolateUsers(dynamic response) async {
  return compute(parsedUsers, response);
}

class SocketService {
  IO.Socket socket;
  String _jwt;
  String _host;
  
  StreamController<List<Device>> deviceController = StreamController.broadcast();
  Stream<List<Device>> get stream => deviceController.stream;

  StreamController<List<Room>> roomsController = StreamController.broadcast();
  Stream<List<Room>> get streamRooms => roomsController.stream;
  final storage = new FlutterSecureStorage();

  NetworkUtil _netUtil = new NetworkUtil();

  createSocketConnection(String host, String jwt) {
    print("socket");
    _jwt = jwt;
    _host = host;
    socket = IO.io('http://$host:8080/users'/*config.socketUrl*/, <String, dynamic>{
      'path': '/smartHome',
      'transports': ['websocket'],
    });

    this.socket.on("connect", (_) => {
      print('Connected'),
      socket.emit('authenticate', { 'token': _jwt }),
  });

  this.socket.on('authenticated', (_) => {
    print('authenticated'),
    socket.emit('setUser', _jwt),
  });

    this.socket.on("disconnect", (_) => {
      print('Disconnected'),
      socket.disconnect(),
      storage.delete(key: 'token'),
      Phoenix.rebirth(globals.context),
      print('globals.context: '),
      print(globals.context),
      _jwt = null
      });

    this.socket.on('unauthorized', (_) => {
      print('unauthorized'),
    });

    this.socket.on("stateChanged", (roomId) => {
      getDeviceModelDataStream(roomId)
    });

    this.socket.on("stateChangedRoom", (_) => {
      print('stateChangedRoom'),
      getRoomModelDataStream()
    });
  }

  closeSocketConnection() {
    socket.emit('disconnectUser');
    socket.disconnect();
  }

  addRoom(String roomName) {
    socket.emit('addRoom', {'room_name': roomName});
  }

  deleteRoom(int roomId) {
    socket.emit('deleteRoom', {'room_id': roomId});
  }

  leaveUserRoom(int roomId) {
    socket.emit('leaveUserRoom', {'room_id': roomId});
  }

  sendAction(socketId, state) async {
    print("socketId: ");
    print(socketId);
    socket.emit('setAction', {'socket_id': socketId, 'state': state});
  }
  // Future <bool>sendAction(socketId, state) async {
  //   Completer<bool> c = new Completer();
  //   socket.emit('setAction', {'socket_id': socketId, 'state': state});
  //   // socket.emitWithAck('setAction', {'socket_id': socketId, 'state': state}, ack: (bool conf) => {
  //   //   print('ack $conf'),
  //   //   // ack = true,
  //   //   c.complete(conf),
  //   // });
  //   return c.future;
  // }

  setDeviceNameRoom(int id, String roomName, int roomId, int actualRoomId) {
    socket.emit('setDeviceNameRoom', {'id': id, 'name': roomName, 'room_id': roomId, 'actual_room_id': actualRoomId});
  }

  addDeviceToRoom(int roomId, int deviceId) {
    socket.emit('addDeviceToRoom', {'room_id': roomId, 'device_id': deviceId});
  }

  removeDeviceFromRoom(int deviceId, int roomId) {
    socket.emit('removeDeviceFromRoom', {'device_id': deviceId, 'room_id': roomId});
  }

  setUserRoom(Room room) {
    socket.emit('setUserRoom', {'room_name': room.name, 'room_id': room.id});
  }

  updateRoomName(Room room) {
    socket.emit('updateRoomName', {'room_name': room.name, 'room_id': room.id});
  }

  getDeviceModelDataStream(int roomId) async {
    final userUrl = "http://$_host:8080/devices/$roomId";

    String token = await storage.read(key: 'token');
    var headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token'
    };
    final response = await _netUtil.post(
      userUrl,
      headers: headers,
      // body: body,
    );
    if (response.length == 0) return deviceController.add(<Device>[]);

    List<Device> devices = await isolateDevices(response);
    deviceController.add(devices);
  }

  Future<List<Device>>getDeviceFree() async {
    final userUrl = "http://$_host:8080/devices/free";

    String token = await storage.read(key: 'token');
    var headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token'
    };
    final response = await _netUtil.post(
      userUrl,
      headers: headers,
      // body: body,
    );
    if (response.length == 0) return <Device>[];

    List<Device> devices = await isolateDevices(response);
    return devices;
  }

  Future <String>getDeviceNewPassword() async {
    final userUrl = "http://$_host:8080/device/signup";

    String token = await storage.read(key: 'token');
    var headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token'
    };
    final response = await _netUtil.post(
      userUrl,
      headers: headers,
      // body: body,
    );
    if (response["error"]) {
      print('here error');
      throw new Exception(response["error_msg"]);
    }
    return response["password"];
  }

  Future<List<Room>> getRoomModelData() async {
    final userUrl = "http://$_host:8080/rooms";

    String token = await storage.read(key: 'token');
    var headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token'
    };
    final response = await _netUtil.post(
      userUrl,
      headers: headers,
      // body: body,
    );

    if (response.length == 0) return null;

    List<Room> rooms = await isolateRooms(response);
    return rooms;
  }

  getRoomModelDataStream() async {
    final userUrl = "http://$_host:8080/rooms";

    String token = await storage.read(key: 'token');
    var headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token'
    };
    final response = await _netUtil.post(
      userUrl,
      headers: headers,
      // body: body,
    );

    if (response.length == 0) return roomsController.add(<Room>[]);

    List<Room> rooms = await isolateRooms(response);
    roomsController.add(rooms);
  }

  Future<bool> checkRoomExist(int roomId) async {
    final userUrl = "http://$_host:8080/rooms/$roomId";

    String token = await storage.read(key: 'token');
    var headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token'
    };
    final response = await _netUtil.post(
      userUrl,
      headers: headers,
      // body: body,
    );

    if (response.length == 0) return false;

    return true;
  }

  Future<bool> checkRoomEmpty(int roomId) async {
    final userUrl = "http://$_host:8080/rooms/empty/$roomId";

    String token = await storage.read(key: 'token');
    var headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token'
    };
    final response = await _netUtil.post(
      userUrl,
      headers: headers,
      // body: body,
    );

    if (response.length == 0) return true;

    return false;
  }

  Future<bool> checkDeviceExist(int deviceId) async {
    final userUrl = "http://$_host:8080/device/exist/$deviceId";

    String token = await storage.read(key: 'token');
    var headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token'
    };
    final response = await _netUtil.post(
      userUrl,
      headers: headers,
      // body: body,
    );

    if (response.length == 0) return false;

    return true;
  }

  Future<List<User>> getUser(int userId) async {
    final userUrl = "http://$_host:8080/device/exist/$userId";

    String token = await storage.read(key: 'token');
    var headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token'
    };
    final response = await _netUtil.post(
      userUrl,
      headers: headers,
      // body: body,
    );

    if (response.length == 0) return null;

    List<User> users = await isolateUsers(response);
    return users;
  }
}