import 'package:flutter/material.dart';
import 'package:flutter_app/services/authentication.dart';
import 'package:flutter_app/services/snackBarText.dart';

class ForgotPasswordPage extends StatefulWidget {
  ForgotPasswordPage({this.auth, this.host, this.username});

  final BaseAuth auth;
  final String host;
  final String username;

  @override
  State<StatefulWidget> createState() => new _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _formKey = new GlobalKey<FormState>();
  SnackbarText _snackbarText = new SnackbarText();
  bool _isLoading;
  String _errorMessageForgotPassword;
  String _host;
  String _username;

  @override
  void initState() {
    _host = widget.host;
    _username = widget.username;
    _isLoading = false;
    _errorMessageForgotPassword = "";
    super.initState();
  }

  Widget showHostInputForgotPassword() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0.0, 15.0, 0.0, 0.0),
      child: new TextFormField(
        initialValue: _host,
        maxLines: 1,
        keyboardType: TextInputType.text,
        autofocus: false,
        decoration: new InputDecoration(
            hintText: 'Host',
            icon: new Icon(
              Icons.dns,
              color: Colors.grey,
            )),
        validator: (value) => value.isEmpty ? 'Host can\'t be empty' : null,
        onChanged: (value) => {
          _host = value.trim()
        },
      ),
    );
  }

  Widget showUsernameInputForgotPassword() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0.0, 15.0, 0.0, 0.0),
      child: new TextFormField(
        initialValue: _username,
        maxLines: 1,
        keyboardType: TextInputType.text,
        autofocus: false,
        decoration: new InputDecoration(
            hintText: 'Username',
            icon: new Icon(
              Icons.person,
              color: Colors.grey,
            )),
        validator: (value) => value.isEmpty ? 'Username can\'t be empty' : null,
        onChanged: (value) => {
          _username = value.trim()
        },
      ),
    );
  }

  Widget showErrorMessageForgotPassword() {
    if (_errorMessageForgotPassword != null && _errorMessageForgotPassword.length > 0) {
      return Padding(
      padding: const EdgeInsets.fromLTRB(0.0, 15.0, 0.0, 0.0),
      child: new Text(
        _errorMessageForgotPassword,
        style: TextStyle(
            fontSize: 13.0,
            color: Colors.red,
            height: 1.0,
            fontWeight: FontWeight.w300),
      )
      );
    } else {
      return new Container(
        height: 0.0,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text("Forgot your password"),
        ),
        body: Builder(
          builder: (context) =>
          Stack(
          children: <Widget>[
            _showForm(context),
            _showCircularProgress(),
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

  Widget _showForm(BuildContext context) {
    return new Container(
        padding: EdgeInsets.all(16.0),
        child: new Form(
            key: _formKey,
            child: new Column(
              // shrinkWrap: true,
              children: <Widget>[
                showHostInputForgotPassword(),
                showUsernameInputForgotPassword(),
                showErrorMessageForgotPassword(),
                Spacer(),
                showPrimaryButton(context),
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
      _errorMessageForgotPassword = "";
      _isLoading = true;
    });
    if (validateAndSave()) {
      try {
        await widget.auth.forgotPassword(_host, _username);
        setState(() {
          _isLoading = false;
        });
        _snackbarText.showSnackBarText(context, 'New password sent to your email');
      } catch (e) {
        setState(() {
          _isLoading = false;
          _errorMessageForgotPassword = e.message;
        });
      }
      final form = _formKey.currentState;
      if (form.validate()) {
        _formKey.currentState.reset();
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
            child: new Text("Create a password",
                // _isLoginForm ? 'Login' : 'Create account',
                style: new TextStyle(fontSize: 20.0, color: Colors.white)),
            onPressed: () {
              validateAndSubmit(context);
            },
          ),
        );
  }
}
