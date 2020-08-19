import 'package:flutter/material.dart';
import 'package:flutter_app/services/snackBarText.dart';
import 'package:flutter_app/services/socket.dart';
import 'package:flutter_simple_dependency_injection/injector.dart';

class UnusedDevicesPage extends StatefulWidget {
  UnusedDevicesPage({Key key}) : super(key: key);

  @override
  _UnusedDevicesPageState createState() => _UnusedDevicesPageState();
}

class _UnusedDevicesPageState extends State<UnusedDevicesPage> {
  final injector = Injector.getInjector();
  SocketService socketService;
  SnackbarText _snackbarText = new SnackbarText();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Unused devices"),
      ),
      body: FutureBuilder(
        future: socketService.
        builder: null)
    );
  }
}