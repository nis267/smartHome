import 'package:flutter/material.dart';
import 'package:flutter_app/services/socket.dart';
import 'package:flutter_simple_dependency_injection/injector.dart';

class ChoosePasswordPage extends StatefulWidget {
  ChoosePasswordPage({Key key, this.userId, this.loginCallback}) : super(key: key);

  final VoidCallback loginCallback;
  final int userId;
  @override
  _ChoosePasswordPageState createState() => _ChoosePasswordPageState();
}

class _ChoosePasswordPageState extends State<ChoosePasswordPage> {
  final _formKey = new GlobalKey<FormState>();
  bool _isLoading;
  String _newPassword;
  String _confirmPassword;
  String _errorMessageNewPassword;
  final injector = Injector.getInjector();
  SocketService socketService;
  bool _obscureTextPassword = true;
  bool _obscureTextPasswordConfirm = true;

  @override
  void initState() {
    _isLoading = false;
    _newPassword = "";
    _confirmPassword = "";
    _errorMessageNewPassword = "";
    socketService = injector.get<SocketService>();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Choose a password"),
      ),
      body: Stack(
          children: <Widget>[
            _showForm(context),
            _showCircularProgress(),
          ],
      )
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
              showPasswordInput(),
              showPasswordConfirmInput(),
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

  Widget showPasswordInput() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0.0, 15.0, 0.0, 0.0),
      child: new TextFormField(
        maxLines: 1,
        obscureText: _obscureTextPassword,
        keyboardType: TextInputType.text,
        autofocus: false,
        decoration: new InputDecoration(
          labelText: 'New password',
          suffixIcon:  GestureDetector(
            onTap: () {
              setState(() {
                _obscureTextPassword = !_obscureTextPassword;
              });
            },
            child: Icon(
              _obscureTextPassword ? Icons.visibility : Icons.visibility_off,
              semanticLabel: _obscureTextPassword ? 'show password' : 'hide password',
            ),
          )
        ),
        validator: (value) =>
          value.isEmpty ? 'New password can\'t be empty' : null,
        onChanged: (value) => {
          _newPassword = value.trim()
        },
      ),
    );
  }

  Widget showPasswordConfirmInput() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0.0, 15.0, 0.0, 0.0),
      child: new TextFormField(
        maxLines: 1,
        keyboardType: TextInputType.text,
        autofocus: false,
        decoration: new InputDecoration(
          labelText: 'Confirm password',
          suffixIcon: GestureDetector(
            onTap: () {
              setState(() {
                _obscureTextPasswordConfirm = !_obscureTextPasswordConfirm;
              });
            },
            child: Icon(
              _obscureTextPasswordConfirm ? Icons.visibility : Icons.visibility_off,
              semanticLabel: _obscureTextPasswordConfirm ? 'show password' : 'hide password',
            )
          )
        ),
        obscureText: _obscureTextPasswordConfirm,
        validator: (value) => 
          value.isEmpty ? 'Confirm password can\'t be empty' : _errorMessageNewPassword.isNotEmpty ? _errorMessageNewPassword : null,
        onChanged: (value) => {
          _confirmPassword = value.trim()
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
      _errorMessageNewPassword = "";
      _isLoading = true;
    });
    if (validateAndSave()) {
      try {
        await socketService.chooseNewUserPassword(widget.userId, _newPassword, _confirmPassword);
        setState(() {
          _isLoading = false;
        });
      } catch (e) {
        setState(() {
          _isLoading = false;
          _errorMessageNewPassword = e.message;
        });
      }
      final form = _formKey.currentState;
      if (form.validate()) {
        _formKey.currentState.reset();
        widget.loginCallback();
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
            child: new Text("Continue",
                style: new TextStyle(fontSize: 20.0, color: Colors.white)),
            onPressed: () {
              validateAndSubmit(context);
            },
          ),
        );
  }

}