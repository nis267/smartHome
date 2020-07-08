import 'package:flutter_simple_dependency_injection/injector.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
// import 'package:tiche_flutter/config.dart';
import 'package:flutter_app/models/device.dart';
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

class SocketService {
  IO.Socket socket;
  String _jwt;
  String _host;
  // BaseAuth auth = new Auth();
  // Injector.getInjector()
  
  StreamController<List<Device>> deviceController = StreamController.broadcast();
  // Stream<List<Device>> get stream => deviceController.stream;

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
    socket = IO.io('http://$host:8080/'/*config.socketUrl*/, <String, dynamic>{
      'query': 'token=' + jwt,
      'path': '/device',
      'transports': ['websocket'],
    });

    this.socket.on("connect", (_) => {
      print('Connected'),
      print('jwt: ' + _jwt),
      socket.emit('setUser', _jwt),
      // chatController.
  });
    this.socket.on("disconnect", (_) => print('Disconnected'));

    this.socket.on("deviceDisconnected", (_) => {
      print("deviceDisconnected"),
      getDeviceModelData()
    });

    this.socket.on("stateChanged", (_) => {
      print("stateChanged"),
      getDeviceModelData()
    });

    this.socket.on("deviceConnected", (_) => {
      print("deviceConnected"),
      getDeviceModelData()
    });
  }

  closeSocketConnection() {
    // deviceController.close();
    socket.disconnect();
    print("deviceController: ");
    print(deviceController);
  }

  sendAction(socketId, state) {
    socket.emit('setAction', {'socket_id': socketId, 'state': state});
  }

  getDeviceModelData() async {
    print("host: ");
    print(_host);
    final userUrl = "http://$_host:8080/devices";
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
}