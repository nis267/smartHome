import 'package:flutter/material.dart';
import 'package:flutter_app/services/snackBarText.dart';
import 'package:flutter_app/services/socket.dart';
import 'package:flutter_simple_dependency_injection/injector.dart';
import '../globals.dart' as globals;

class ChangeUsernamePage extends StatefulWidget {
  ChangeUsernamePage({Key key, this.userId, this.username}) : super(key: key);

  final int userId;
  final String username;
  @override
  _ChangeUsernamePageState createState() => _ChangeUsernamePageState();
}

class _ChangeUsernamePageState extends State<ChangeUsernamePage> {
  final _formKey = new GlobalKey<FormState>();
  bool _isLoading;
  String _newUsername;
  String _errorMessageNewUsername;
  final injector = Injector.getInjector();
  SocketService socketService;
  SnackbarText _snackbarText = new SnackbarText();
  
  @override
  void initState() {
    _isLoading = false;
    _newUsername = widget.username;
    _errorMessageNewUsername = "";
    socketService = injector.get<SocketService>();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Update your username"),
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
              showEmailInput(),
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

  Widget showEmailInput() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0.0, 15.0, 0.0, 0.0),
      child: new TextFormField(
        initialValue: _newUsername,
        maxLines: 1,
        keyboardType: TextInputType.text,
        autofocus: false,
        decoration: new InputDecoration(
          labelText: 'Enter username',
        ),
        validator: (value) =>
          value.isEmpty ? 'Username can\'t be empty' : _errorMessageNewUsername.isNotEmpty ? _errorMessageNewUsername : null,
        onChanged: (value) => {
          _newUsername = value.trim(),
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
      _errorMessageNewUsername = "";
      _isLoading = true;
    });
    if (validateAndSave()) {
      try {
        await socketService.setNewUserName(widget.userId, _newUsername);
        _snackbarText.showSnackBarText(context, 'Username updated');
        setState(() {
          _isLoading = false;
        });
      } catch (e) {
        setState(() {
          _isLoading = false;
          _errorMessageNewUsername = e.message;
        });
      }
      final form = _formKey.currentState;
      if (form.validate()) {
        _formKey.currentState.reset();
        globals.user.username = _newUsername;
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