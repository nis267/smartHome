import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_app/models/device.dart';
import 'package:flutter_app/models/room.dart';
import 'package:flutter_simple_dependency_injection/injector.dart';
import 'package:flutter_app/services/socket.dart';
// import 'package:flutter/cupertino.dart';

class RoomPage extends StatefulWidget {
  RoomPage({
    Key key, this.room
  }) : super(key: key);

  final Room room;

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

class _Page1State extends State<RoomPage> {
  final injector = Injector.getInjector();
  SocketService socketService;

  // List<Room> _rooms;
  List<Room> _roomList = [];

  @override
  void initState() {
    socketService = injector.get<SocketService>();
    print("hereeeeee");
    // print(widget.room.name);
    socketService.setUserRoom(widget.room);
    socketService.getDeviceModelData(widget.room.id);
    socketService.getRoomModelData().then((value) => {
          setState(() {
            _roomList = value;
          })
        });
    super.initState();
  }

  @override
  void didUpdateWidget(RoomPage oldWidget) {
    // socketService.getDeviceModelData(widget.room.id);
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

  Room currentSelectedRoom;
  String currentSelectedName;
  List<String> settings = new List(2);

  final _formKey = new GlobalKey<FormState>();

  void getCurrentRoom(int roomId) {
    int i;
    for (i = 0; i < _roomList.length; i++) {
      if (_roomList[i].id == roomId) {
        currentSelectedRoom = _roomList[i];
      }
    }
  }

  Future<List<dynamic>> createDialogWindow(BuildContext conetxt, String name, int roomId) async {
    currentSelectedName = name;
    getCurrentRoom(roomId);
    return await showDialog(
        context: context,
        builder: (BuildContext context) {
          return new AlertDialog(
            title: Text("Device settings"),
            content: 
            
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
            
            new StatefulBuilder(
              builder: (BuildContext context, StateSetter setState) {
                return SingleChildScrollView(
                    child: ListTileTheme(
                        child: new Container(
                            padding: EdgeInsets.all(16.0),
                            child: new Form(
                                key: _formKey,
                                child: new ListBody(
                                  children: <Widget>[
                                    showNameInput(),
                                    // showDropDownRooms(context)
                                    new Padding(
                                      padding: const EdgeInsets.fromLTRB(
                                          0.0, 15.0, 0.0, 0.0),
                                      child: new DropdownButtonFormField(
                                        onTap: () {
                                          FocusScope.of(context).unfocus();
                                        },
                                        decoration: new InputDecoration(
                                          labelText: 'Select Room',
                                          // hintText: 'Name',
                                        ),
                                        // hint: Text('Select Room'),
                                        value: currentSelectedRoom,
                                        onChanged: (Room newValue) {
                                          setState(() {
                                            currentSelectedRoom = newValue;
                                          });
                                        },
                                        isExpanded: true,
                                        items: _roomList
                                            .map<DropdownMenuItem<Room>>(
                                                (value) =>
                                                    DropdownMenuItem<Room>(
                                                      child: Text(value.name),
                                                      value: value,
                                                    ))
                                            .toList(),
                                        // validator: (value) => value == null ? 'Room can\'t be empty' : null,
                                      ),
                                      // }
                                      // return Center(child: CircularProgressIndicator());
                                      // }
                                      // )
                                    ),
                                  ],
                                )))));
              },
            ),

            Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
              MaterialButton(
                elevation: 5.0,
                child: Text('Cancel'),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
              MaterialButton(
                elevation: 5.0,
                child: Text('Submit'),
                onPressed: () {
                  final form = _formKey.currentState;
                  if (form.validate()) {
                    form.save();
                    // List<String>['ergerg', 'eghergerg'];
                    Navigator.of(context).pop([
                      currentSelectedName.toString(),
                      currentSelectedRoom.id.toInt()
                    ]);
                    // Navigator.of(context).pop(currentSelectedName.toString());
                  }
                },
              )
                ]
          )
              ]
          )
          );
        });
  }

  Widget showNameInput() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0.0, 15.0, 0.0, 0.0),
      child: new TextFormField(
        initialValue: currentSelectedName,
        maxLines: 1,
        keyboardType: TextInputType.text,
        autofocus: false,
        decoration: new InputDecoration(
          labelText: 'Name',
          // hintText: 'Name',
        ),
        validator: (value) => value.isEmpty ? 'Name can\'t be empty' : null,
        onSaved: (value) => {
          currentSelectedName = value.trim(),
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.room.name),
      ),
      body: StreamBuilder<List<Device>>(
          stream: socketService.stream,
          initialData: <Device>[],
          builder: (context, stream) {
            // if (!stream.hasData)
              // return Center(child: CircularProgressIndicator());
            return ListView(
              children: stream.data
                  .map((device) => ListTile(
                        trailing: Switch(
                          value: device.state == 1 ? true : false,
                          onChanged: (bool value) {
                            setState(() {
                              //  value;
                            });
                          },
                        ),
                        onLongPress: () {
                          createDialogWindow(context, device.name, device.roomId)
                              .then((onValue) {
                            if (onValue != null)
                            socketService.setDeviceNameRoom(
                                device.id, onValue[0], onValue[1]);
                          });
                        },
                        onTap: () {
                          if (device.socketId != null)
                            socketService.sendAction(
                                device.socketId, device.state);
                        },
                        title:
                            Text(device.name == null ? "No name" : device.name),
                        subtitle: Text(device.macAddress),
                        leading: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CircleAvatar(
                              radius: 10,
                              backgroundColor: device.socketId != null
                                  ? Colors.green
                                  : Colors.red,
                            ),
                          ],
                        ),
                      ))
                  .toList(),
            );
          }),
          floatingActionButton: FloatingActionButton(
        onPressed: () {
          print("button pressed");

        },
        tooltip: 'Add device',
        child: Icon(Icons.add),
      ),
    );
  }
}
