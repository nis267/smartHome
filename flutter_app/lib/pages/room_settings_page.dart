import 'package:flutter/material.dart';
import 'package:flutter_app/models/room.dart';
import 'package:flutter_app/services/snackBarText.dart';
import 'package:flutter_app/services/socket.dart';
import 'package:flutter_simple_dependency_injection/injector.dart';

class RoomSettingsPage extends StatefulWidget {
  RoomSettingsPage({Key key, this.userId, this.room}) : super(key: key);

  final int userId;
  final Room room;
  @override
  _RoomSettingsPageState createState() => _RoomSettingsPageState();
}

class _RoomSettingsPageState extends State<RoomSettingsPage> {
  final _formKey = new GlobalKey<FormState>();
  bool _isLoading;
  Room _newRoom;
  String _errorMessageNewRoomSettings;
  final injector = Injector.getInjector();
  SocketService socketService;
  SnackbarText _snackbarText = new SnackbarText();
  
  @override
  void initState() {
    _isLoading = false;
    _newRoom = widget.room;
    _errorMessageNewRoomSettings = "";
    socketService = injector.get<SocketService>();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Room settings"),
      ),
      body: Builder(
        builder: (context) =>
      Stack(
          children: <Widget>[
            _showForm(context),
            _showCircularProgress(),
          ],
      )
    ),
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
              showRoomNameInput(),
              Spacer(),
              showPrimaryButton(context),
            ],
          )
        )
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

  Widget showRoomNameInput() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0.0, 15.0, 0.0, 0.0),
      child: new TextFormField(
        initialValue: _newRoom.name,
        maxLines: 1,
        keyboardType: TextInputType.text,
        autofocus: false,
        decoration: new InputDecoration(
          labelText: 'Room name',
        ),
        validator: (value) =>
          value.isEmpty ? 'Room name can\'t be empty' : _errorMessageNewRoomSettings.isNotEmpty ? _errorMessageNewRoomSettings : null,
        onChanged: (value) => {
          _newRoom.name = value.trim(),
        },
      ),
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
      _errorMessageNewRoomSettings = "";
      _isLoading = true;
    });
    if (validateAndSave()) {
      try {
        await socketService.updateRoom(_newRoom);
        setState(() {
          _isLoading = false;
        });
      } catch (e) {
        setState(() {
          _isLoading = false;
          _errorMessageNewRoomSettings = e.message;
        });
      }
      final form = _formKey.currentState;
      if (form.validate()) {
       _snackbarText.showSnackBarText(context, 'Room updated');
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