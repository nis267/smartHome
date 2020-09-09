import 'package:flutter/material.dart';
import 'package:flutter_app/pages/forgot_password_page.dart';
import 'package:flutter_app/services/authentication.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LoginSignupPage extends StatefulWidget {
  LoginSignupPage({this.auth, this.loginCallback});

  final BaseAuth auth;
  final VoidCallback loginCallback;

  @override
  State<StatefulWidget> createState() => new _LoginSignupPageState();
}

class _LoginSignupPageState extends State<LoginSignupPage> {
  final _formKey = new GlobalKey<FormState>();
  bool rememberMe = false;
  final _hostController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  String _errorMessage;
  bool _isLoading;
  bool _obscureTextPassword = true;

  // Check if form is valid before perform login or signup
  bool validateAndSave() {
    final form = _formKey.currentState;
    if (form.validate()) {
      form.save();
      return true;
    }
    return false;
  }

  createDialogGenerateNewPasswordDevice(
      BuildContext contextScafold, String msg) async {
    return await showDialog(
        context: contextScafold,
        builder: (BuildContext context) {
          return new AlertDialog(
            title: Text('Device info'),
            content: Text(msg),
            actions: <Widget>[
              FlatButton(
                child: Text('Ok'),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ],
          );
        });
  }

  // Perform login or signup
  void validateAndSubmit() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _errorMessage = "";
      _isLoading = true;
    });
    if (validateAndSave()) {
      String userId = "";
      try {
        if (rememberMe == true) {
          prefs.setStringList('login', [
            _hostController.text,
            _usernameController.text,
            _passwordController.text
          ]);
        }
        userId = await widget.auth.signIn(_hostController.text,
            _usernameController.text, _passwordController.text);
        setState(() {
          _isLoading = false;
        });
        if (userId.length > 0 && userId != null) {
          widget.loginCallback();
        }
      } catch (e) {
        setState(() {
          _isLoading = false;
          _errorMessage = e.message;
          _formKey.currentState.reset();
        });
      }
    }
  }

  void initLoginCredentials() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool rememberMeTmp = prefs.getBool('rememberMe');
    if (rememberMeTmp != null) {
      rememberMe = rememberMeTmp;
      if (rememberMe == false) {
        await prefs.remove('login');
      }
    }
    List<String> loginList = prefs.getStringList('login');
    if (loginList != null) {
      _hostController.text = loginList[0];
      _usernameController.text = loginList[1];
      _passwordController.text = loginList[2];
    }
    setState(() {});
  }

  @override
  void initState() {
    initLoginCredentials();
    _errorMessage = "";
    _isLoading = false;
    super.initState();
  }

  void resetForm() {
    _formKey.currentState.reset();
    _errorMessage = "";
  }

  void resetTextControllers() {
    _hostController.clear();
    _usernameController.clear();
    _passwordController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
        appBar: new AppBar(
          title: new Text('SmartHome'),
        ),
        body: Stack(
          children: <Widget>[
            _showForm(context),
            _showCircularProgress(),
          ],
        ));
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

//  void _showVerifyEmailSentDialog() {
//    showDialog(
//      context: context,
//      builder: (BuildContext context) {
//        // return object of type Dialog
//        return AlertDialog(
//          title: new Text("Verify your account"),
//          content:
//              new Text("Link to verify account has been sent to your email"),
//          actions: <Widget>[
//            new FlatButton(
//              child: new Text("Dismiss"),
//              onPressed: () {
//                toggleFormMode();
//                Navigator.of(context).pop();
//              },
//            ),
//          ],
//        );
//      },
//    );
//  }

  Widget _showForm(BuildContext context) {
    return new Container(
        padding: EdgeInsets.all(16.0),
        child: new Form(
          key: _formKey,
          child: new ListView(
            shrinkWrap: true,
            children: <Widget>[
              showLogo(),
              showHostInput(),
              showUsernameInput(),
              showPasswordInput(),
              showErrorMessage(),
              showForgotPassword(context),
              showCheckBoxRememberMe(),
              // if (_primaryButton == 'Connect device') showConnectDevice(),
              showPrimaryButton(context),
              showSecondaryButton(context),
              showthirdButton(context),
            ],
          ),
        ));
  }

  void _onChangedCheckBoxRememberMe(bool newValue) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    rememberMe = newValue;
    setState(() {
      prefs.setBool("rememberMe", rememberMe);
    });
  }

  Widget showCheckBoxRememberMe() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0.0, 0.0, 0.0, 0.0),
      child: new CheckboxListTile(
        title: Text("Remember me"),
        value: rememberMe,
        onChanged: _onChangedCheckBoxRememberMe,
        controlAffinity: ListTileControlAffinity.leading,
      ),
    );
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
      )
      );
    } else {
      return new Container(
        height: 0.0,
      );
    }
  }

  Widget showLogo() {
    return new Hero(
      tag: 'hero',
      child: Padding(
        padding: EdgeInsets.fromLTRB(0.0, 30.0, 0.0, 0.0),
        child: CircleAvatar(
          backgroundColor: Colors.transparent,
          radius: 48.0,
          child: Image.asset('assets/flutter-icon.png'),
        ),
      ),
    );
  }

  Widget showForgotPassword(BuildContext context) {
    return FlatButton(
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ForgotPasswordPage(
                auth: widget.auth,
                host: _hostController.text,
                username: _usernameController.text),
          ),
        );
      },
      textColor: Colors.blue,
      child: Text('Forgot Password'),
    );
  }

  Widget showHostInput() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0.0, 100.0, 0.0, 0.0),
      child: new TextFormField(
        controller: _hostController,
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
      ),
    );
  }

  Widget showUsernameInput() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0.0, 15.0, 0.0, 0.0),
      child: new TextFormField(
        controller: _usernameController,
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
      ),
    );
  }

  Widget showPasswordInput() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0.0, 15.0, 0.0, 0.0),
      child: new TextFormField(
        controller: _passwordController,
        maxLines: 1,
        obscureText: _obscureTextPassword,
        autofocus: false,
        decoration: new InputDecoration(
          suffixIcon: GestureDetector(
            onTap: () {
              setState(() {
                _obscureTextPassword = !_obscureTextPassword;
              });
            },
            child: Icon(
              _obscureTextPassword ? Icons.visibility : Icons.visibility_off,
              semanticLabel: _obscureTextPassword ? 'show password' : 'hide password',
            ),
          ),
            hintText: 'Password',
            icon: new Icon(
              Icons.lock,
              color: Colors.grey,
            )),
        validator: (value) => value.isEmpty ? 'Password can\'t be empty' : null,
      ),
    );
  }

  Widget showthirdButton(BuildContext context) {
    return new FlatButton(
        child: new Text('Connect to device',
            style: new TextStyle(fontSize: 18.0, fontWeight: FontWeight.w300)),
        onPressed: () {
          Navigator.popAndPushNamed(context, '/connect_device');
        });
  }

  Widget showSecondaryButton(BuildContext context) {
    return new FlatButton(
        child: new Text('Create an account',
            style: new TextStyle(fontSize: 18.0, fontWeight: FontWeight.w300)),
        onPressed: () {
          Navigator.popAndPushNamed(context, '/create_account');
        });
  }

  Widget showPrimaryButton(BuildContext context) {
    return new Padding(
        padding: EdgeInsets.fromLTRB(0.0, 45.0, 0.0, 0.0),
        child: SizedBox(
          height: 40.0,
          child: new RaisedButton(
            elevation: 5.0,
            shape: new RoundedRectangleBorder(
                borderRadius: new BorderRadius.circular(30.0)),
            color: Colors.blue,
            child: new Text('Login',
                style: new TextStyle(fontSize: 20.0, color: Colors.white)),
            onPressed: () {
              validateAndSubmit();
            },
          ),
        ));
  }
}
