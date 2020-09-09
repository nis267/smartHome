import 'package:flutter/material.dart';
import 'package:flutter_app/models/device.dart';
import 'package:flutter_app/services/snackBarText.dart';
import 'package:flutter_app/services/socket.dart';
import 'package:flutter_simple_dependency_injection/injector.dart';

class UnusedDevicesPage extends StatefulWidget {
  UnusedDevicesPage({Key key}) : super(key: key);

  @override
  _UnusedDevicesPageState createState() => _UnusedDevicesPageState();
}

class DeviceCheckbox {
  int id;
  bool isChecked;

  DeviceCheckbox({
    this.id,
    this.isChecked = false,
  });
}

class _UnusedDevicesPageState extends State<UnusedDevicesPage> {
  var devicesCheckboxStatus = List<DeviceCheckbox>.empty(growable: true);
  var devicesToRemove;
  final injector = Injector.getInjector();
  SocketService socketService;
  SnackbarText _snackbarText = new SnackbarText();

  @override
  void initState() {
    socketService = injector.get<SocketService>();
    super.initState();
  }

  Future<bool> createDialogRemoveDeviceFromRoom(
      BuildContext contextScafold, int nbr) async {
    return await showDialog(
        context: contextScafold,
        builder: (BuildContext context) {
          return new AlertDialog(
            title: Text("Remove devices"),
            content: Text('You really want to remove ' +
                nbr.toString() +
                (nbr > 1 ? ' devices' : ' device')),
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
                  Navigator.of(context).pop(true);
                },
              ),
            ],
          );
        });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text("Unused devices"),
        ),
        body: FutureBuilder<List<Device>>(
            future: socketService.getUnusedDevices(),
            builder: (context, future) {
              if (!future.hasData) {
                return new Center(child: CircularProgressIndicator());
              }
              devicesToRemove = devicesCheckboxStatus
                  .where((device) => device.isChecked == true)
                  .map((device) => device.id)
                  .toList();
              return Column(
                children: [
                  Expanded(
                      child: ListView(
                    children: future.data.asMap().entries.map((entry) {
                      int index = entry.key;
                      Device device = entry.value;
                      bool addDeviceCheckbox = true;
                      DeviceCheckbox currentDeviceCheckbox;
                      for (DeviceCheckbox deviceCheckbox
                          in devicesCheckboxStatus) {
                        if (deviceCheckbox.id == device.id) {
                          addDeviceCheckbox = false;
                          currentDeviceCheckbox = deviceCheckbox;
                          break;
                        }
                      }
                      if (addDeviceCheckbox) {
                        currentDeviceCheckbox =
                            DeviceCheckbox(id: device.id, isChecked: false);
                        devicesCheckboxStatus.add(currentDeviceCheckbox);
                      }
                      return Card(
                          child: ListTile(
                        title:
                            Text(device.name == null ? "" : device.name),
                        subtitle: Text(device.macAddress),
                        onTap: () {
                          setState(() {
                            currentDeviceCheckbox.isChecked =
                                !currentDeviceCheckbox.isChecked;
                          });
                        },
                        trailing: Checkbox(
                          // title: new Text(key),
                          value: currentDeviceCheckbox.isChecked,
                          activeColor: Colors.blue,
                          checkColor: Colors.white,
                          onChanged: (bool value) {
                            setState(() {
                              currentDeviceCheckbox.isChecked = value;
                            });
                          },
                        ),
                      ));
                    }).toList(),
                  )),
                  if (devicesToRemove.length > 0)
                    Padding(
                        padding:
                            const EdgeInsets.fromLTRB(0.0, 15.0, 0.0, 15.0),
                        child: SizedBox(
                            height: 40.0,
                            child: RaisedButton.icon(
                              elevation: 5.0,
                              icon: Icon(
                                Icons.delete,
                                color: Colors.white,
                              ),
                              onPressed: () async {
                                createDialogRemoveDeviceFromRoom(
                                        context, devicesToRemove.length)
                                    .then((value) => {
                                          if (value != null && value == true)
                                            {
                                              socketService
                                                  .removeUnusedDevices(
                                                      devicesToRemove)
                                                  .then((value) => {
                                                        _snackbarText.showSnackBarText(context, devicesToRemove.length.toString() + 
                                                        (devicesToRemove.length > 1 ? " devices" : " device") + " deleted"),
                                                        devicesCheckboxStatus
                                                            .removeWhere((element) =>
                                                                devicesToRemove
                                                                    .contains(
                                                                        element
                                                                            .id)),
                                                        setState(() {}),
                                                      })
                                            }
                                        });
                              },
                              label: Text('Remove devices',
                                  style: new TextStyle(
                                      fontSize: 20.0, color: Colors.white)),
                              color: Colors.red,
                              shape: new RoundedRectangleBorder(
                                  borderRadius:
                                      new BorderRadius.circular(30.0)),
                            )))
                ],
              );
            }));
  }
}
