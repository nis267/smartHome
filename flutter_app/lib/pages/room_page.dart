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
  final _formKey = new GlobalKey<FormState>();

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

  Widget _showForm(BuildContext context) {
    return new Container(
        padding: EdgeInsets.all(16.0),
        child: new Form(
            key: _formKey,
            child: new Column(
              children: <Widget>[
                _showDevices(),
                _showPrimaryButton(context),
              ],
            )));
  }

  Widget _showDevices() {
    return Expanded(
      child: StreamBuilder<List<Device>>(
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
                                  socketService.sendAction(device.socketId);
                                  // .then((ack) => { // TODO
                                  _snackbarText.showSnackBarText(
                                      context,
                                      (device.name != null
                                              ? device.name
                                              : device.macAddress) +
                                          ' is ' +
                                          (value == true ? 'on' : 'off'));
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
                              Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (context) =>
                                              DeviceSettingsPage(
                                                  device: device,
                                                  room: widget.room)))
                                  .then((value) async => {
                                        if (value != null && value == true)
                                          {
                                            _snackbarText.showSnackBarText(
                                                context, 'Device updated')
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
                          title: Text(device.name == null ? "" : device.name),
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
            ]);
          }),
    );
  }

  Widget _showPrimaryButton(BuildContext context) {
    return new SizedBox(
      width: double.infinity,
      height: 40.0,
      child: new RaisedButton(
          elevation: 5.0,
          shape: new RoundedRectangleBorder(
              borderRadius: new BorderRadius.circular(30.0)),
          color: Colors.blue,
          child: new Text('Add devices',
              style: new TextStyle(fontSize: 20.0, color: Colors.white)),
          onPressed: () {
            Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => AddDevicesPage(
                          room: widget.room,
                        ))).then((value) => {
                  if (value != null && value == true)
                    {
                      _snackbarText.showSnackBarText(context, 'Devices added to room'),
                    }
                });
          }),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.room.name),
      ),
      body: Builder(
        builder: (context) => Stack(
          children: <Widget>[
      _showForm(context),
          ],
        ),
      ),
    );
  }
}