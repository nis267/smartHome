import 'package:flutter/material.dart';
import 'package:flutter_app/models/device.dart';
import 'package:flutter_app/services/snackBarText.dart';
import 'package:flutter_app/services/socket.dart';
import 'package:flutter_simple_dependency_injection/injector.dart';

class RemoveDevicesPage extends StatefulWidget {
  RemoveDevicesPage({Key key}) : super(key: key);

  @override
  _RemoveDevicesPageState createState() => _RemoveDevicesPageState();
}

class DeviceCheckbox {
  int id;
  bool isChecked;

  DeviceCheckbox({
    this.id,
    this.isChecked = false,
  });
}

class _RemoveDevicesPageState extends State<RemoveDevicesPage> {
  var devicesCheckboxStatus = List<DeviceCheckbox>.empty(growable: true);
  List<int> devicesToRemove = List<int>();
  final injector = Injector.getInjector();
  SocketService socketService;
  final _formKey = new GlobalKey<FormState>();
  bool _isLoading;
  String _errorMessage;
  List<Device> devicesList = List<Device>();

  Future<void> getDevices() async {
    devicesList = await socketService.getUnusedDevices();
    setState(() {});
  }

  @override
  void initState() {
    socketService = injector.get<SocketService>();
    _isLoading = false;
    _errorMessage = "";
    getDevices();
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
        title: Text("Remove devices"),
      ),
      body: Builder(
          builder: (context) => Stack(
                children: <Widget>[
                  _showForm(context),
                  _showCircularProgress(),
                ],
              )),
    );
  }

  Widget _showCircularProgress() {
    if (_isLoading) {
      return Center(child: CircularProgressIndicator());
    }
    return Container(
      height: 0.0,
      width: 0.0,
    );
  }

  Widget _showUnusedDevices() {
    return Expanded(
        child: ListView(
      children: devicesList.asMap().entries.map((entry) {
        Device device = entry.value;
        bool addDeviceCheckbox = true;
        DeviceCheckbox currentDeviceCheckbox;
        for (DeviceCheckbox deviceCheckbox in devicesCheckboxStatus) {
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
        devicesToRemove = devicesCheckboxStatus
            .where((device) => device.isChecked == true)
            .map((device) => device.id)
            .toList();
        return Card(
            child: ListTile(
          title: Text(device.name == null ? "" : device.name),
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
    ));
  }

  bool validateAndSave() {
    final form = _formKey.currentState;
    if (form.validate()) {
      form.save();
      return true;
    }
    return false;
  }

  Widget showErrorMessage() {
    if (_errorMessage.length > 0 && _errorMessage != null) {
      return Padding(
          padding: const EdgeInsets.fromLTRB(0.0, 15.0, 0.0, 0.0),
          child: Center(
            child: new Text(
              _errorMessage,
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 13.0,
                  color: Colors.red,
                  height: 1.0,
                  fontWeight: FontWeight.w300),
            ),
          ));
    } else {
      return new Container(
        height: 0.0,
      );
    }
  }

  void validateAndSubmit(BuildContext context) async {
    FocusScope.of(context).unfocus();
    setState(() {
      _errorMessage = "";
      _isLoading = true;
    });
    if (validateAndSave()) {
      await socketService.removeDevices(devicesToRemove);
      setState(() {
        _isLoading = false;
      });
      try {} catch (e) {
        setState(() {
          _isLoading = false;
          _errorMessage = e.message;
        });
      }
      final form = _formKey.currentState;
      if (form.validate()) {
        Navigator.pop(context, true);
      }
    }
  }

  Widget _showForm(BuildContext context) {
    return new Container(
        padding: EdgeInsets.all(16.0),
        child: new Form(
            key: _formKey,
            child: new Column(
              // shrinkWrap: true,
              children: <Widget>[
                _showUnusedDevices(),
                showErrorMessage(),
                _showPrimaryButton(context),
              ],
            )));
  }

  Widget _showPrimaryButton(BuildContext context) {
    return new SizedBox(
      width: double.infinity,
      height: 40.0,
      child: new RaisedButton.icon(
        elevation: 5.0,
        icon: Icon(
          Icons.delete,
          color: Colors.white,
        ),
        shape: new RoundedRectangleBorder(
            borderRadius: new BorderRadius.circular(30.0)),
        color: Colors.red,
        label: new Text("Remove devices",
            style: new TextStyle(fontSize: 20.0, color: Colors.white)),
        onPressed: devicesToRemove.length > 0
            ? () {
                createDialogRemoveDeviceFromRoom(
                        context, devicesToRemove.length)
                    .then((value) => {
                          if (value != null && value == true)
                            {validateAndSubmit(context)}
                        });
              }
            : null,
      ),
    );
  }
}
