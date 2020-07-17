import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_app/models/device.dart';
import 'package:flutter_app/models/room.dart';
import 'package:flutter_simple_dependency_injection/injector.dart';
import 'package:flutter_app/services/socket.dart';
import 'package:flutter_app/services/socket.dart';
import 'dart:convert';
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
  final injector = Injector.getInjector();
  SocketService socketService;

  // List<Room> _rooms;
  List<Room> _roomList = [];

  @override
  void initState() {
    socketService = injector.get<SocketService>();
    socketService.getDeviceModelData();
    socketService.getRoomModelData().then((value) => {
          setState(() {
            _roomList = value;
          })
        });
    super.initState();
  }

  @override
  void didUpdateWidget(Page1 oldWidget) {
    socketService.getDeviceModelData();
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

  List<String> _dropdownValues = ["One", "Two", "Three", "Four", "Five"];
  Room currentSelectedRoom;
  String currentSelectedName;
  List<String> settings = new List(2);

  final _formKey = new GlobalKey<FormState>();

  Future<List<dynamic>> createDialogWindow(
      BuildContext conetxt, String name) async {
    currentSelectedName = name;

    // _dropdownValues = []
    print("rooms: ");
    // _rooms = await socketService.getRoomModelData();
    // print(json.encode(_rooms));
    // _rooms.map((e) => {print("e: "), print(e)});

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
                                      child:
                                          // FutureBuilder(
                                          // future: socketService.getRoomModelData(),
                                          // builder: (context, snapshot) {
                                          // if (snapshot.hasError)
                                          //   return Text(snapshot.error);

                                          // if (snapshot.hasData) {
                                          //   return
                                          new DropdownButtonFormField(
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
                                          print("currentSelectedRoom: " +
                                              currentSelectedRoom.name);
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



          //   actions: 
          //   <Widget>[
          //     Row(
          //       // mainAxisAlignment: MainAxisAlignment.spaceBetween,
          //       children: <Widget>[
          //     MaterialButton(
          //       elevation: 5.0,
          //       child: Text('Cancel'),
          //       onPressed: () {
          //         Navigator.of(context).pop();
          //       },
          //     ),
          //     MaterialButton(
          //       elevation: 5.0,
          //       child: Text('Submit'),
          //       onPressed: () {
          //         final form = _formKey.currentState;
          //         if (form.validate()) {
          //           form.save();
          //           // List<String>['ergerg', 'eghergerg'];
          //           Navigator.of(context).pop([
          //             currentSelectedName.toString(),
          //             currentSelectedRoom.id.toInt()
          //           ]);
          //           // Navigator.of(context).pop(currentSelectedName.toString());
          //         }
          //       },
          //     )
          //       ]
          // )
          //   ],



          );
        });
  }

  // Widget showDropDownRooms(BuildContext context) {
  //   return Padding(
  //       padding: const EdgeInsets.fromLTRB(0.0, 15.0, 0.0, 0.0),
  //       // child: DropdownButtonHideUnderline(
  //       child: DropdownButton<String>(
  //         onTap: () {
  //           FocusScope.of(context).unfocus();
  //           // customController.clear();
  //           // customController.dispose();
  //           // customController.hasListeners
  //           // print("hereeeee");
  //         },
  //         hint: Text('Select Room'),
  //         value: currentSelectedRoom,
  //         onChanged: (String newValue) {
  //           // currentSelectedRoom = newValue;
  //           setState(() {
  //             currentSelectedRoom = newValue;
  //           });
  //           print("currentSelectedRoom: " + currentSelectedRoom);
  //         },
  //         isExpanded: true,
  //         items: _dropdownValues
  //             .map((value) => DropdownMenuItem(
  //                   child: Text(value),
  //                   value: value,
  //                 ))
  //             .toList(),
  //       ));
  //   // );
  // }

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
        title: Text('Fetching data from DB - ListView'),
      ),
      body: StreamBuilder<List<Device>>(
          stream: socketService.deviceController.stream,
          builder: (context, stream) {
            if (!stream.hasData)
              return Center(child: CircularProgressIndicator());
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
                          createDialogWindow(context, device.name)
                              .then((onValue) {
                            print("hereee");
                            print(onValue);
                            if (onValue != null)
                            socketService.setDeviceNameRoom(
                                device.id, onValue[0], onValue[1]);
                            print("hereee aggainnnn");
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
    );
  }
}
