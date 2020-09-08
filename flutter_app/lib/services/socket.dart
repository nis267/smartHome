import 'dart:convert';

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
  String _url;
  final int _port = 80;
  
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
    _url = (host.startsWith("http") ? host : "http://$host:$_port");
    print("url: ");
    print(_url);
    socket = IO.io('$_url/users'/*config.socketUrl*/, <String, dynamic>{
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

  sendAction(socketId) async {
    print("socketId: ");
    print(socketId);
    socket.emit('setAction', {'socket_id': socketId});
  }

  addDevicesToRoom(int roomId, List<int> deviceIds) {
    socket.emit('addDevicesToRoom', jsonDecode(jsonEncode({"room_id": roomId, "devices_ids": deviceIds})));
  }

  removeDeviceFromRoom(int deviceId, int roomId) {
    socket.emit('removeDeviceFromRoom', {'device_id': deviceId, 'room_id': roomId});
  }

  setUserRoom(Room room) {
    socket.emit('setUserRoom', {'room_name': room.name, 'room_id': room.id});
  }

  updateDevice(Device device, int actualRoomId) {
    socket.emit('updateDevice', jsonDecode(jsonEncode(device)));
  }

  updateRoom(Room room) {
    print("here room");
    print(jsonEncode(room));
    socket.emit('updateRoom', jsonDecode(jsonEncode(room)));
  }

  getDeviceModelDataStream(int roomId) async {
    final userUrl = "$_url/devices/$roomId";

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
    final userUrl = "$_url/devices/free";

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

  Future<List<Device>>getUnusedDevices() async {
    final userUrl = "$_url/devices/unused";

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

  Future<bool>removeUnusedDevices(ids) async {
    final userUrl = "$_url/device/remove";
    print("url: ");
    print(userUrl);
    print("ids: ");
    print(ids);
    String token = await storage.read(key: 'token');
    var headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token'
    };
    final response = await _netUtil.post(
      userUrl,
      headers: headers,
      body: json.encode(
        {
          "devices_ids": ids
        }
      ),
    );
    print("response: ");
    print(response);
    return true;
  }

  Future <String>getDeviceNewPassword() async {
    final userUrl = "$_url/device/signup";

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
    final userUrl = "$_url/rooms";

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
    final userUrl = "$_url/rooms";

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
    final userUrl = "$_url/rooms/$roomId";

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
    final userUrl = "$_url/rooms/empty/$roomId";

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
    final userUrl = "$_url/device/exist/$deviceId";

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

  Future<bool> setNewUserName(int userId, String newUsername) async {
    final userUrl = "$_url/user/new_user_name/$userId";

    print("userUrl: ");
    print(userUrl);
    String token = await storage.read(key: 'token');
    print("token:");
    print(token);
    var headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token'
    };
    final response = await _netUtil.post(
      userUrl,
      headers: headers,
      body: json.encode(
        {
          "new_username": newUsername
        }
      ),
    );

    print("response[error]: ");
    print(response["error"]);
    if (response["error"]) {
      print('here error');
      throw new Exception(response["error_msg"]);
    }

    if (response.length == 0) return false;

    // List<User> users = await isolateUsers(response);
    // return users[0];
    return true;
  }

  Future<bool> setNewUserPassword(int userId, String password, String newPassword, String confirmPassword) async {
    final userUrl = "$_url/user/change_password/$userId";

    String token = await storage.read(key: 'token');
    var headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token'
    };
    final response = await _netUtil.post(
      userUrl,
      headers: headers,
      body: json.encode(
        {
          "password": password,
          "new_password": newPassword,
          "confirm_new_password": confirmPassword
        }
      ),
    );

    if (response["error"]) {
      throw new Exception(response["error_msg"]);
    }
    if (response.length == 0) return false;
    return true;
  }

  Future<bool> chooseNewUserPassword(int userId, String newPassword, String confirmPassword) async {
    final userUrl = "$_url/user/choose_password/$userId";

    String token = await storage.read(key: 'token');
    var headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token'
    };
    final response = await _netUtil.post(
      userUrl,
      headers: headers,
      body: json.encode(
        {
          "new_password": newPassword,
          "confirm_new_password": confirmPassword
        }
      ),
    );

    if (response["error"]) {
      throw new Exception(response["error_msg"]);
    }
    if (response.length == 0) return false;
    return true;
  }

  Future<bool> chooseNewUseremail(int userId, String newEmail) async {
    final userUrl = "$_url/user/new_email/$userId";

    String token = await storage.read(key: 'token');
    var headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token'
    };
    final response = await _netUtil.post(
      userUrl,
      headers: headers,
      body: json.encode(
        {
          "new_email": newEmail,
        }
      ),
    );

    if (response["error"]) {
      throw new Exception(response["error_msg"]);
    }
    if (response.length == 0) return false;
    return true;
  }
}