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

class SocketService {
  IO.Socket socket;
  String _jwt;
  String _host;
  
  StreamController<List<Device>> deviceController = StreamController.broadcast();
  Stream<List<Device>> get stream => deviceController.stream;
  final storage = new FlutterSecureStorage();

  NetworkUtil _netUtil = new NetworkUtil();

  createSocketConnection(String host, String jwt) {
    _jwt = jwt;
    _host = host;
    socket = IO.io('http://$host:8080/users'/*config.socketUrl*/, <String, dynamic>{
      'query': 'token=' + jwt,
      'path': '/smartHome',
      'transports': ['websocket'],
    });

    this.socket.on("connect", (_) => {
      print('Connected'),
      print('jwt: '),
      print(_jwt),
      socket.emit('setUser', _jwt),
  });

    this.socket.on("disconnect", (_) => {
      print('Disconnected'),
      socket.disconnect(),
      storage.delete(key: 'token'),
      Phoenix.rebirth(globals.context),
      _jwt = null
      });

    this.socket.on("stateChanged", (roomId) => {
      getDeviceModelData(roomId)
    });
  }

  closeSocketConnection() {
    socket.emit('disconnectUser');
    socket.disconnect();
  }

  leaveUserRoom(int roomId) {
    socket.emit('leaveUserRoom', {'room_id': roomId});
  }

  sendAction(socketId, state) {
    socket.emit('setAction', {'socket_id': socketId, 'state': state});
  }

  setDeviceNameRoom(int id, String roomName, int roomId, int actualRoomId) {
    socket.emit('setDeviceNameRoom', {'id': id, 'name': roomName, 'room_id': roomId, 'actual_room_id': actualRoomId});
  }

  setUserRoom(Room room) {
    socket.emit('setUserRoom', {'room_name': room.name, 'room_id': room.id});
  }

  getDeviceModelData(int roomId) async {
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
}