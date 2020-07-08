import 'package:flutter/material.dart';
import 'package:flutter_app/models/device.dart';
import 'package:flutter_simple_dependency_injection/injector.dart';
import 'package:flutter_app/services/socket.dart';
import 'package:flutter_app/services/socket.dart';
// import 'package:flutter/cupertino.dart';

class Page1 extends StatefulWidget {
  Page1({
    Key key,
  }) : super(key: key);

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
  bool _lights = false;
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
    print("didUpdateWidget");
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
          builder: (context, stream) {
            if (!stream.hasData)
              return Center(child: CircularProgressIndicator());
            return ListView(
              children: stream.data
                  .map((device) =>
                      ListTile(
                        trailing: Switch(
                          value: device.state == 1 ? true : false,
                          onChanged: (bool value) {
                            setState(() {
                              _lights = value;
                            });
                          },
                        ),
                        onTap: () {
                          if (device.socketId != null)
                            socketService.sendAction(device.socketId, device.state);
                        },
                        title:
                            Text(device.name == null ? "No name" : device.name),
                        subtitle: Text(device.macAddress),
                        leading: CircleAvatar(
                          backgroundColor: device.socketId != null
                              ? Colors.green
                              : Colors.red,
                        ),
                      ))
                  .toList(),
            );
          }),
    );
  }
}
