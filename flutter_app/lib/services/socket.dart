import 'package:socket_io_client/socket_io_client.dart' as IO;
// import 'package:tiche_flutter/config.dart';

class SocketService {
  IO.Socket socket;

  createSocketConnection(String host, String jwt) {
    print("jwt create socket: " + jwt);
    print("host: " + host);
    socket = IO.io('http://$host:8080/'/*config.socketUrl*/, <String, dynamic>{
      'query': 'token=' + jwt,
      'path': '/user',
      'transports': ['websocket'],
    });

    this.socket.on("connect", (_) => {
      print('Connected'),

  });
    this.socket.on("disconnect", (_) => print('Disconnected'));
  }

  closeSocketConnection() {
    socket.disconnect();
  }
}