import 'package:flutter/material.dart';
import 'package:flutter_app/services/snackBarText.dart';
import 'package:flutter_app/services/socket.dart';
import 'package:flutter_simple_dependency_injection/injector.dart';

class AddRoomPage extends StatefulWidget {
  AddRoomPage({Key key, this.userId}) : super(key: key);

  final int userId;
  @override
  _AddRoomPageState createState() => _AddRoomPageState();
}

class _AddRoomPageState extends State<AddRoomPage> {
  final _formKey = new GlobalKey<FormState>();
  bool _isLoading;
  String _newRoom;
  String _errorMessageNewRoom;
  final injector = Injector.getInjector();
  SocketService socketService;
  SnackbarText _snackbarText = new SnackbarText();
  
  @override
  void initState() {
    _isLoading = false;
    _errorMessageNewRoom = "";
    _newRoom = "";
    socketService = injector.get<SocketService>();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Add a room"),
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
        maxLines: 1,
        keyboardType: TextInputType.text,
        autofocus: false,
        decoration: new InputDecoration(
          labelText: 'Name',
        ),
        validator: (value) =>
          value.isEmpty ? 'Name can\'t be empty' : _errorMessageNewRoom.isNotEmpty ? _errorMessageNewRoom : null,
        onSaved: (value) => {
          _newRoom = value.trim(),
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
      _errorMessageNewRoom = "";
      _isLoading = true;
    });
    if (validateAndSave()) {
      try {
        await socketService.addRoom(_newRoom);
        setState(() {
          _isLoading = false;
        });
      } catch (e) {
        setState(() {
          _isLoading = false;
          _errorMessageNewRoom = e.message;
        });
      }
      final form = _formKey.currentState;
      if (form.validate()) {
        _formKey.currentState.reset();
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