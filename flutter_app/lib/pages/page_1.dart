import 'package:flutter/material.dart';
import 'package:flutter_app/models/device.dart';
import 'package:flutter_app/services/authentication.dart';
import 'dart:async';
import 'dart:convert';

import 'package:flutter_app/services/http_request.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'package:flutter_simple_dependency_injection/injector.dart';
import 'package:flutter_app/services/socket.dart';
import 'package:flutter_app/services/socket.dart';

class Page1 extends StatefulWidget {
  Page1({Key key, }) : super(key: key);

  @override
  _Page1State createState() => _Page1State();
}

// class _Page1State extends State<Page1> {
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: Center(
//         child: Text(
//           "This page is to add Item",
//         ),
//       ),

//       floatingActionButton: FloatingActionButton(
//         child: Icon(
//           Icons.add,
//         ),
//         onPressed: (){},
//       ),
//     );
//   }
// }

class _Page1State extends State<Page1> {
  final injector = Injector.getInjector();
  SocketService socketService;

  @override
  void initState() {
  socketService = injector.get<SocketService>();
    socketService.getDeviceModelData();
    super.initState();
  }


  @override
  void didUpdateWidget(Page1 oldWidget) {
    // if (somethingChanged) {
      // load();
    // }
    super.didUpdateWidget(oldWidget);
  }

  @override
    void dispose() {
      // socketService.deviceController.close();
      // print();
      super.dispose();
    }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Fetching data from DB - ListView'),
      ),
      body: StreamBuilder<List<Device>>(
          stream: socketService.deviceController.stream,
          // initialData: 2,
          builder: (context, stream) {
            print("stream: ");
            print(stream);
            if (!stream.hasData)
              return Center(child: CircularProgressIndicator());
            return ListView(
              children: stream.data
                  .map((device) =>
                      // ChatItem()
                      ListTile(
                        onTap: () {
                          print("widget: ");
                          print(widget);
                          print("device.state: ");
                          print(device.state);
                          // device.state = device.state == 0 ? 1 : 0;
                          if (device.socketId != null)
                            widget.auth.sendAction(device.socketId, device.state);
                          // socketService.sendAction(device.socketId, button);
                          return device;
                        },
                        title:
                            Text(device.name == null ? "No name" : device.name),
                        subtitle: Text(device.macAddress),
                        leading: CircleAvatar(
                          backgroundColor: device.socketId != null
                              ? Colors.green
                              : Colors.red,
                          // child: Text(device.name == null ? "No name" : device.name,
                          //     style: TextStyle(
                          //       fontSize: 18.0,
                          //       color: Colors.white,
                          //     )),
                        ),
                      ))
                  .toList(),
            );
          }),
    );
  }
}
