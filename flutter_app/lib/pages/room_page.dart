import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_app/models/device.dart';
import 'package:flutter_app/models/room.dart';
import 'package:flutter_app/services/snackBarText.dart';
import 'package:flutter_simple_dependency_injection/injector.dart';
import 'package:flutter_app/services/socket.dart';
import 'dart:async';
// import 'package:flutter/cupertino.dart';

class RoomPage extends StatefulWidget {
  RoomPage({Key key, this.room}) : super(key: key);

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
  SnackbarText _snackbarText = new SnackbarText();
  // List<Room> _roomList = [];

  @override
  void initState() {
    socketService = injector.get<SocketService>();
    socketService.setUserRoom(widget.room);
    socketService.getDeviceModelDataStream(widget.room.id);
    super.initState();
  }

  @override
  void didUpdateWidget(RoomPage oldWidget) {
    super.didUpdateWidget(oldWidget);
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  void deactivate() {
    socketService.leaveUserRoom(widget.room.id);
    super.deactivate();
  }

  String currentSelectedName;
  List<String> settings = new List(2);

  final _formKey = new GlobalKey<FormState>();

  Room getCurrentRoom(int roomId, roomList) {
    int i;
    for (i = 0; i < roomList.length; i++) {
      if (roomList[i].id == roomId) {
        return roomList[i];
      }
    }
    return null;
  }

  Future<List<dynamic>> createDialogWindow(
      BuildContext contextScafold, String name, int roomId) async {
    currentSelectedName = name;
    Room currentSelectedRoom;
    return await showDialog(
        context: contextScafold,
        builder: (BuildContext context) {
          return new FutureBuilder(
              future: socketService.getRoomModelData(),
              builder: (context, future) {
                if (!future.hasData) {
                  return new Center(child: CircularProgressIndicator());
                } else {
                  currentSelectedRoom = getCurrentRoom(roomId, future.data);
                  return new AlertDialog(
                    title: Text("Device settings"),
                    content: Column(mainAxisSize: MainAxisSize.min, children: [
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
                                                padding:
                                                    const EdgeInsets.fromLTRB(
                                                        0.0, 15.0, 0.0, 0.0),
                                                child:
                                                    new DropdownButtonFormField(
                                                  onTap: () {
                                                    FocusScope.of(context)
                                                        .unfocus();
                                                  },
                                                  decoration:
                                                      new InputDecoration(
                                                    labelText: 'Select Room',
                                                    // hintText: 'Name',
                                                  ),
                                                  // hint: Text('Select Room'),
                                                  value: currentSelectedRoom,
                                                  onChanged: (Room newValue) {
                                                    setState(() {
                                                      currentSelectedRoom =
                                                          newValue;
                                                    });
                                                  },
                                                  isExpanded: true,
                                                  items: future.data
                                                      .map<
                                                          DropdownMenuItem<
                                                              Room>>((value) =>
                                                          DropdownMenuItem<
                                                              Room>(
                                                            child: Text(
                                                                value.name),
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
                    ]),
                    actions: <Widget>[
                      FlatButton(
                        // elevation: 5.0,
                        child: Text('Cancel'),
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                      ),
                      FlatButton(
                        // elevation: 5.0,
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
                            _snackbarText.showSnackBarText(
                                contextScafold, name + ' is modified');
                          }
                        },
                      )
                    ],
                  );
                }
              });
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

  // void _snackbarText.showSnackBarText(BuildContext context, String text) {
  //   final snackBar =
  //       SnackBar(content: Text(text), duration: Duration(milliseconds: 2000));
  //   Scaffold.of(context).removeCurrentSnackBar();
  //   Scaffold.of(context).showSnackBar(snackBar);
  // }

  Future<Device> createDialogRemoveDevice(
      BuildContext contextScafold, Device device) async {
    return await showDialog(
        context: contextScafold,
        builder: (BuildContext context) {
          return new AlertDialog(
            title: Text("Remove device"),
            content: Text('You really want to remove ' +
                (device.name == null ? device.macAddress : device.name) +
                ' from ' +
                widget.room.name +
                ' ?'),
            actions: <Widget>[
              FlatButton(
                child: Text('No'),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
              FlatButton(
                child: Text('Yes'),
                onPressed: () {
                  Navigator.of(context).pop(device);
                },
              ),
            ],
          );
        });
  }

  Future<Device> createDialogAddDevice(BuildContext contextScafold) async {
    Device currentSelectedDevice;
    return await showDialog(
        context: contextScafold,
        builder: (BuildContext context) {
          return new FutureBuilder(
              future: socketService.getDeviceFree(),
              builder: (context, future) {
                if (future.hasData && future.data.length >= 1) {
                  return new AlertDialog(
                    title: Text('Add device'),
                    content: Column(mainAxisSize: MainAxisSize.min, children: [
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
                                              new DropdownButtonFormField(
                                                decoration: new InputDecoration(
                                                  labelText: 'Select Device',
                                                ),
                                                value: currentSelectedDevice,
                                                onChanged: (Device newValue) {
                                                  setState(() {
                                                    currentSelectedDevice =
                                                        newValue;
                                                  });
                                                },
                                                isExpanded: true,
                                                items: future.data
                                                    .map<
                                                            DropdownMenuItem<
                                                                Device>>(
                                                        (Device value) =>
                                                            DropdownMenuItem<
                                                                Device>(
                                                              child: Text(value
                                                                          .name ==
                                                                      null
                                                                  ? value
                                                                      .macAddress
                                                                  : value.name),
                                                              value: value,
                                                            ))
                                                    .toList(),
                                                validator: (value) => value ==
                                                        null
                                                    ? 'Device can\'t be empty'
                                                    : null,
                                              ),
                                            ],
                                          )))));
                        },
                      ),
                    ]),
                    actions: <Widget>[
                      FlatButton(
                        child: Text('Cancel'),
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                      ),
                      FlatButton(
                        child: Text('Submit'),
                        onPressed: () {
                          final form = _formKey.currentState;
                          if (form.validate()) {
                            form.save();
                            Navigator.of(context).pop(currentSelectedDevice);
                          }
                        },
                      ),
                    ],
                  );
                } else if (future.hasData && future.data.length == 0) {
                  return new AlertDialog(
                    title: Text('Add device'),
                    content: Text('No devices available'),
                    actions: <Widget>[
                      FlatButton(
                        child: Text('Ok'),
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                      ),
                    ],
                  );
                }
                return new Center(child: CircularProgressIndicator());
              });
        });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.room.name),
      ),
      body: StreamBuilder<List<Device>>(
          stream: socketService.deviceController.stream,
          builder: (context, stream) {
            if (!stream.hasData)
              return Center(child: CircularProgressIndicator());
            return Column(children: [
              Expanded(
                  child: ListView(
                children: stream.data
                    .map((device) => Card(
                            child: ListTile(
                          trailing: Switch(
                            value: device.state == 1 ? true : false,
                            activeColor: Colors.green,
                            onChanged: (bool value) async {
                              bool deviceExist = await socketService
                                  .checkDeviceExist(device.id);
                              if (deviceExist) {
                                if (device.socketId != null) {
                                  socketService
                                      .sendAction(device.socketId);
                                      // .then((ack) => {
                                            _snackbarText.showSnackBarText(
                                                context,
                                                (device.name != null ? device.name : device.macAddress) +
                                                    ' is ' +
                                                    (value == true
                                                        ? 'on'
                                                        : 'off'));
                                          // });
                                  setState(() {});
                                } else {
                                  _snackbarText.showSnackBarText(context,
                                      device.name + ' is not connected');
                                }
                              } else {
                                _snackbarText.showSnackBarText(
                                    context,
                                    'Device ' +
                                        (device.name == null
                                            ? device.macAddress
                                            : device.name) +
                                        ' not available');
                              }
                            },
                          ),
                          onLongPress: () async {
                            bool deviceExist =
                                await socketService.checkDeviceExist(device.id);
                            if (deviceExist) {
                              createDialogRemoveDevice(context, device)
                                  .then((onValue) {
                                if (onValue != null) {
                                  socketService.removeDeviceFromRoom(
                                      onValue.id, widget.room.id);
                                  _snackbarText.showSnackBarText(
                                      context,
                                      (onValue.name == null
                                              ? onValue.macAddress
                                              : onValue.name) +
                                          ' removed from ' +
                                          widget.room.name);
                                }
                              });
                            } else {
                              _snackbarText.showSnackBarText(
                                  context,
                                  'Device ' +
                                      (device.name == null
                                          ? device.macAddress
                                          : device.name) +
                                      ' not available');
                            }
                          },
                          onTap: () async {
                            bool deviceExist =
                                await socketService.checkDeviceExist(device.id);
                            if (deviceExist) {
                              createDialogWindow(
                                      context, device.name, device.roomId)
                                  .then((onValue) {
                                if (onValue != null)
                                  socketService.setDeviceNameRoom(device.id,
                                      onValue[0], onValue[1], widget.room.id);
                              });
                            } else {
                              _snackbarText.showSnackBarText(
                                  context,
                                  'Device ' +
                                      (device.name == null
                                          ? device.macAddress
                                          : device.name) +
                                      ' not available');
                            }
                          },
                          title: Text(
                              device.name == null ? "No name" : device.name),
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
                        )))
                    .toList(),
              )),
              Padding(
                  padding: const EdgeInsets.fromLTRB(0.0, 15.0, 0.0, 15.0),
                  child: SizedBox(
                      height: 40.0,
                      child: RaisedButton.icon(
                        elevation: 5.0,
                        icon: Icon(
                          Icons.add,
                          color: Colors.white,
                        ),
                        onPressed: () {
                          createDialogAddDevice(context).then((device) => {
                                if (device != null)
                                  {
                                    socketService.addDeviceToRoom(
                                        widget.room.id, device.id),
                                  }
                              });
                        },
                        label: Text('Add a device',
                            style: new TextStyle(
                                fontSize: 20.0, color: Colors.white)),
                        color: Colors.blue,
                        shape: new RoundedRectangleBorder(
                            borderRadius: new BorderRadius.circular(30.0)),
                      )))
            ]);
          }),
    );
  }
}
