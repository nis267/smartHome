import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_app/models/device.dart';
import 'package:flutter_app/models/room.dart';
import 'package:flutter_app/pages/add_devices_page.dart';
import 'package:flutter_app/pages/device_settings_page.dart';
import 'package:flutter_app/services/snackBarText.dart';
import 'package:flutter_simple_dependency_injection/injector.dart';
import 'package:flutter_app/services/socket.dart';
import 'dart:async';
// import 'package:flutter/cupertino.dart';

class RoomPage extends StatefulWidget {
  RoomPage({Key key, this.room}) : super(key: key);

  final Room room;

  @override
  _RoomPageState createState() => _RoomPageState();
}

class _RoomPageState extends State<RoomPage> {
  final injector = Injector.getInjector();
  SocketService socketService;
  SnackbarText _snackbarText = new SnackbarText();

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

  final _formKey = new GlobalKey<FormState>();

  Future<Device> createDialogRemoveDeviceFromRoom(
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
                              createDialogRemoveDeviceFromRoom(context, device)
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
                              Navigator.push(context, MaterialPageRoute(builder: (context) => DeviceSettingsPage(device: device, room: widget.room))).then((value) async => {
                                if (value != null && value == true) {
                                  _snackbarText.showSnackBarText(context, 'Device updated')
                                },
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
                              device.name == null ? "" : device.name),
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
                        )
                        )
                        )
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
                          Navigator.push(context,
                          MaterialPageRoute(builder: (context) => AddDevicesPage(room: widget.room,))).then((value) => {
                            if (value != null && value == true) {
                              _snackbarText.showSnackBarText(context, 'Room updated'),
                            }
                          });
                        },
                        label: Text('Add devices',
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
