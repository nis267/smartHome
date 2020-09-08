import 'package:flutter/material.dart';
import 'package:flutter_app/models/device.dart';
import 'package:flutter_app/models/room.dart';
import 'package:flutter_app/services/snackBarText.dart';
import 'package:flutter_app/services/socket.dart';
import 'package:flutter_simple_dependency_injection/injector.dart';

class DeviceSettingsPage extends StatefulWidget {
  DeviceSettingsPage({Key key, this.device, this.room}) : super(key: key);

  final Device device;
  final Room room;
  @override
  _DeviceSettingsPageState createState() => _DeviceSettingsPageState();
}

class _DeviceSettingsPageState extends State<DeviceSettingsPage> {
  final _formKey = new GlobalKey<FormState>();
  bool _isLoading;
  Device _newDevice;
  String _errorMessageNewDeviceSettings;
  Room currentSelectedRoom;
  List<Room> roomList = List<Room>();
  final injector = Injector.getInjector();
  SocketService socketService;

  Future<void> getRoomList() async {
    roomList = await socketService.getRoomModelData();
    setState(() {
      currentSelectedRoom = getCurrentRoom(widget.room.id, roomList);
    });
  }

  @override
  void initState() {
    socketService = injector.get<SocketService>();
    _isLoading = false;
    _newDevice = widget.device;
    _errorMessageNewDeviceSettings = "";
    getRoomList();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Device settings"),
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

  Widget _showForm(BuildContext context) {
    return new Container(
        padding: EdgeInsets.all(16.0),
        child: new Form(
            key: _formKey,
            child: new Column(
              // shrinkWrap: true,
              children: <Widget>[
                showDeviceMacAddressInput(),
                showDeviceNameInput(),
                showRoomSelect(),
                Spacer(),
                showPrimaryButton(context),
              ],
            )));
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

  Widget showDeviceMacAddressInput() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0.0, 15.0, 0.0, 0.0),
      child: new TextFormField(
        enabled: false,
        initialValue: _newDevice.macAddress,
        maxLines: 1,
        keyboardType: TextInputType.text,
        autofocus: false,
        decoration: new InputDecoration(
          labelText: 'Device mac address',
        ),
      ),
    );
  }

  Widget showDeviceNameInput() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0.0, 15.0, 0.0, 0.0),
      child: new TextFormField(
        initialValue: _newDevice.name,
        maxLines: 1,
        keyboardType: TextInputType.text,
        autofocus: false,
        decoration: new InputDecoration(
          labelText: 'Device name',
        ),
        validator: (value) => value.isEmpty
            ? 'Device name can\'t be empty'
            : _errorMessageNewDeviceSettings.isNotEmpty
                ? _errorMessageNewDeviceSettings
                : null,
        onChanged: (value) => {
          _newDevice.name = value.trim(),
        },
      ),
    );
  }

  Room getCurrentRoom(int roomId, roomList) {
    int i;
    for (i = 0; i < roomList.length; i++) {
      if (roomList[i].id == roomId) {
        return roomList[i];
      }
    }
    return null;
  }


  Widget showRoomSelect() {
    return new Padding(
      padding: const EdgeInsets.fromLTRB(0.0, 15.0, 0.0, 0.0),
      child: new DropdownButtonFormField(
        onTap: () {
          FocusScope.of(context).unfocus();
        },
        decoration: new InputDecoration(
          labelText: 'Select Room',
        ),
        value: currentSelectedRoom,
        onChanged: (Room newValue) {
          setState(() {
            currentSelectedRoom = newValue;
          });
        },
        onSaved: (Room savedValue) {
          _newDevice.roomId = savedValue.id;
        },
        isExpanded: true,
        items: roomList
            .map<DropdownMenuItem<Room>>((value) => DropdownMenuItem<Room>(
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
    );
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
      _errorMessageNewDeviceSettings = "";
      _isLoading = true;
    });
    if (validateAndSave()) {
      setState(() {
          _isLoading = false;
        });
      try {
        await socketService.updateDevice(_newDevice, widget.room.id);
        
      } catch (e) {
        setState(() {
          _isLoading = false;
          _errorMessageNewDeviceSettings = e.message;
        });
      }
      final form = _formKey.currentState;
      if (form.validate()) {
        Navigator.pop(context, true);
      }
    }
  }

  Widget showPrimaryButton(BuildContext context) {
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
        onPressed: () {
          validateAndSubmit(context);
        },
      ),
    );
  }
}
