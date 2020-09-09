import 'package:flutter/material.dart';
import 'package:flutter_app/models/user.dart';
import 'package:flutter_app/services/snackBarText.dart';
import 'package:flutter_app/services/socket.dart';
import 'package:flutter_simple_dependency_injection/injector.dart';

class RemoveAccountPage extends StatefulWidget {
  RemoveAccountPage({Key key, this.user, this.logoutCallback}) : super(key: key);

  final User user;
  final VoidCallback logoutCallback;
  @override
  _RemoveAccountPageState createState() => _RemoveAccountPageState();
}

class _RemoveAccountPageState extends State<RemoveAccountPage> {
  final _formKey = new GlobalKey<FormState>();
  bool _isLoading;
  String _errorMessageRemoveAccount;
  final injector = Injector.getInjector();
  SocketService socketService;
  SnackbarText _snackbarText = new SnackbarText();
  bool _obscureTextPasswordActual = true;
  String _actualPassword;
  
  @override
  void initState() {
    _isLoading = false;
    _errorMessageRemoveAccount = "";
    _actualPassword = "";
    socketService = injector.get<SocketService>();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Remove your account"),
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
              showPasswordActualInput(),
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

  Widget showPasswordActualInput() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0.0, 15.0, 0.0, 0.0),
      child: new TextFormField(
        maxLines: 1,
        obscureText: _obscureTextPasswordActual,
        keyboardType: TextInputType.text,
        autofocus: false,
        decoration: new InputDecoration(
          labelText: 'Password',
          suffixIcon:  GestureDetector(
            onTap: () {
              setState(() {
                _obscureTextPasswordActual = !_obscureTextPasswordActual;
              });
            },
            child: Icon(
              _obscureTextPasswordActual ? Icons.visibility : Icons.visibility_off,
              semanticLabel: _obscureTextPasswordActual ? 'show password' : 'hide password',
            ),
          )
        ),
        validator: (value) =>
          value.isEmpty ? 'Password can\'t be empty' : _errorMessageRemoveAccount.isNotEmpty ? _errorMessageRemoveAccount : null,
        onChanged: (value) => {
          _actualPassword = value.trim()
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
      _errorMessageRemoveAccount = "";
      _isLoading = true;
    });
    if (validateAndSave()) {
      try {
        await socketService.removeAccount(widget.user.id, _actualPassword);
        setState(() {
          _isLoading = false;
        });
      } catch (e) {
        setState(() {
          _isLoading = false;
          _errorMessageRemoveAccount = e.message;
        });
      }
      final form = _formKey.currentState;
      if (form.validate()) {
        _formKey.currentState.reset();
        widget.logoutCallback();
        // Navigator.pop(context, true);
      }
    }
  }

  Widget showPrimaryButton(BuildContext context) {
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
            label: new Text("Remove account",
                style: new TextStyle(fontSize: 20.0, color: Colors.white)),
            onPressed: () {
              validateAndSubmit(context);
            },
          ),
        );
  }

}