import 'package:flutter/services.dart';
import 'package:flutter_simple_dependency_injection/injector.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
// import 'package:tiche_flutter/config.dart';
import 'package:flutter_app/models/device.dart';
import 'package:flutter_app/models/room.dart';
import 'dart:async';
import 'package:flutter_app/services/authentication.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_app/services/http_request.dart';
import 'package:flutter/foundation.dart';

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
  // BaseAuth auth = new Auth();
  // Injector.getInjector()
  
  StreamController<List<Device>> deviceController = StreamController.broadcast();
  Stream<List<Device>> get stream => deviceController.stream;

  final storage = new FlutterSecureStorage();

  NetworkUtil _netUtil = new NetworkUtil();
  // SocketService() {
  //   deviceController.onListen = () {
  //     deviceController.add(getDeviceModelData()); // triggered when the first subscriber is added
  //   };
  // }

  createSocketConnection(String host, String jwt) {
    _jwt = jwt;
    _host = host;
    print("jwt create socket: " + jwt);
    print("host: " + host);
    socket = IO.io('http://$host:8080/users'/*config.socketUrl*/, <String, dynamic>{
      'query': 'token=' + jwt,
      'path': '/smartHome',
      'transports': ['websocket'],
    });

    print("socket nsp: ");
    print(socket.nsp);
    this.socket.on("connect", (_) => {
      print('Connected'),
      print('jwt: ' + _jwt),
      socket.emit('setUser', _jwt),
      // chatController.
  });
    this.socket.on("disconnect", (_) => {
      print('Disconnected'),
      storage.delete(key: 'token'),
      // SystemNavigator.pop()
      });

    // this.socket.on("deviceDisconnected", (_) => {
    //   print("deviceDisconnected"),
    //   getDeviceModelData()
    // });

    this.socket.on("stateChanged", (roomId) => {
      print("stateChanged: "),
      print(roomId),
      getDeviceModelData(roomId)
    });

    // this.socket.on("deviceConnected", (_) => {
    //   print("deviceConnected"),
    //   getDeviceModelData()
    // });
  }

  closeSocketConnection() {
    // deviceController.close();
    socket.emit('disconnectUser');
    socket.disconnect();
  }

  sendAction(socketId, state) {
    socket.emit('setAction', {'socket_id': socketId, 'state': state});
  }

  setDeviceNameRoom(int id, String roomName, int roomId) {
    socket.emit('setDeviceNameRoom', {'id': id, 'name': roomName, 'room_id': roomId});
  }

  setUserRoom(Room room) {
    socket.emit('setUserRoom', {'room_name': room.name, 'room_id': room.id});
  }

  getDeviceModelData(int roomId) async {
    final userUrl = "http://$_host:8080/devices/$roomId";
    print("useUrl: ");
    print(userUrl);
    final json = await getJsonFromJWT(await storage.read(key: 'token'));

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

    List<Device> devices = await isolateDevices(response);
    deviceController.add(devices);
  }

  Future<List<Room>> getRoomModelData() async {
    final userUrl = "http://$_host:8080/rooms";
    final json = await getJsonFromJWT(await storage.read(key: 'token'));

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
    // deviceController.add(devices);
    return rooms;
  }
}