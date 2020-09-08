import 'package:flutter/material.dart';
import 'package:flutter_app/models/device.dart';
import 'package:flutter_app/models/room.dart';
import 'package:flutter_app/services/snackBarText.dart';
import 'package:flutter_app/services/socket.dart';
import 'package:flutter_simple_dependency_injection/injector.dart';

class AddDevicesPage extends StatefulWidget {
  AddDevicesPage({Key key, this.room}) : super(key: key);

  final Room room;
  @override
  _AddDevicesPagePageState createState() => _AddDevicesPagePageState();
}

class DeviceCheckbox {
  int id;
  bool isChecked;

  DeviceCheckbox({
    this.id,
    this.isChecked = false,
  });
}

class _AddDevicesPagePageState extends State<AddDevicesPage> {
  var devicesCheckboxStatus = List<DeviceCheckbox>.empty(growable: true);
  List<int> devicesToAdd = List<int>();
  final injector = Injector.getInjector();
  SocketService socketService;
  final _formKey = new GlobalKey<FormState>();
  bool _isLoading;
  String _errorMessageAddDevices;
  Room currentSelectedRoom;
  List<Device> devicesList = List<Device>();

  Future<void> getDevices() async {
    devicesList = await socketService.getUnusedDevices();
    setState(() {});
  }

  @override
  void initState() {
    socketService = injector.get<SocketService>();
    _isLoading = false;
    _errorMessageAddDevices = "";
    getDevices();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Add devices to " + widget.room.name),
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

  Widget _showDevices() {
    return Expanded(
        child: ListView(
      children: devicesList.asMap().entries.map((entry) {
        int index = entry.key;
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
        devicesToAdd = devicesCheckboxStatus
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

  Widget _showForm(BuildContext context) {
    return new Container(
        padding: EdgeInsets.all(16.0),
        child: new Form(
            key: _formKey,
            child: new Column(
              // shrinkWrap: true,
              children: <Widget>[
                _showDevices(),
                _showPrimaryButton(context),
              ],
            )));
  }

  bool validateAndSave() {
    final form = _formKey.currentState;
    if (form.validate()) {
      form.save();
      return true;
    }
    return false;
  }

  void validateAndSubmit(BuildContext context) async {
    FocusScope.of(context).unfocus();
    setState(() {
      _errorMessageAddDevices = "";
      _isLoading = true;
    });
    if (validateAndSave()) {
     await  socketService.addDevicesToRoom(widget.room.id, devicesToAdd);
      setState(() {
        _isLoading = false;
      });
      try {
        
      } catch (e) {
        setState(() {
          _isLoading = false;
          _errorMessageAddDevices = e.message;
        });
      }
      final form = _formKey.currentState;
      if (form.validate()) {
        Navigator.pop(context, true);
      }
    }
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
        child: new Text("Submit",
            style: new TextStyle(fontSize: 20.0, color: Colors.white)),
        onPressed: devicesToAdd.length > 0 ? () {validateAndSubmit(context);} : null,
      ),
    );
  }
}
