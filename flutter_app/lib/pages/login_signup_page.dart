import 'package:flutter/material.dart';
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
  final _serverAddressController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _passwordServerController = TextEditingController();
  String _errorMessage;

  // int _button = 1;
  // bool _isLoginForm;
  bool _isLoading;

  String _primaryButton = 'Login';
  String _secondaryButton = 'Create an account';
  String _thirdButton = 'Connect to device';

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
            // Text('The password for a new device is ' + password),
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
  void validateAndSubmit(BuildContext context) async {
    FocusScope.of(context).unfocus();
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _errorMessage = "";
      _isLoading = true;
    });
    if (validateAndSave()) {
      String userId = "";
      try {
        if (_primaryButton == 'Login') {
          if (rememberMe == true) {
          prefs.setStringList('login', [
            _hostController.text,
            _usernameController.text,
            _passwordController.text
          ]);
          }
          userId = await widget.auth.signIn(_hostController.text,
              _usernameController.text, _passwordController.text);
          print('Signed in: $userId');
        } else if (_primaryButton == 'Create account') {
          userId = await widget.auth
              .signUp(_hostController.text, _usernameController.text);
          print('Signed up user: $userId');
        } else if (_primaryButton == 'Connect device') {
          print('Connect device');
          String device_message = await widget.auth.connectDevice(
              _hostController.text,
              _passwordController.text,
              _serverAddressController.text,
              _passwordServerController.text);
          createDialogGenerateNewPasswordDevice(context, device_message);
          print("userId");
          print(userId);
        }
        setState(() {
          _isLoading = false;
        });
        if (userId.length > 0 && userId != null && _primaryButton == 'Login') {
          widget.loginCallback();
        }
      } catch (e) {
        print('Error: $e');
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
    print("loginList: ");
    print(loginList);
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
    // _isLoginForm = true;
    super.initState();
  }

  void resetForm() {
    _formKey.currentState.reset();
    _errorMessage = "";
  }

  void resetTextControllers() {
    _hostController.clear();
    _usernameController.clear();
    _serverAddressController.clear();
    _passwordController.clear();
    _passwordServerController.clear();
  }

  void toggleFormMode(BuildContext context, int button) {
    FocusScope.of(context).unfocus();
    resetForm();
    setState(() {
      if (button == 3 && _thirdButton == 'Connect to device') {
        _primaryButton = 'Connect device';
        _secondaryButton = 'Have an account ? Sign in';
        _thirdButton = 'Create an account';
      } else if ((button == 3 && _thirdButton == 'Create an account') ||
          (button == 2 && _secondaryButton == 'Create an account')) {
        _primaryButton = 'Create account';
        _secondaryButton = 'Have an account ? Sign in';
        _thirdButton = 'Connect to device';
      } else if (button == 2 &&
          _secondaryButton == 'Have an account ? Sign in') {
        _primaryButton = 'Login';
        _secondaryButton = 'Create an account';
        _thirdButton = 'Connect to device';
      }
      // _isLoginForm = !_isLoginForm;
      resetTextControllers();
      if (_primaryButton == 'Login') {
        initLoginCredentials();
      }
    });
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
              showHostInput(
                  _primaryButton == 'Connect device' ? 'SSID' : 'Host'),
              if (_primaryButton != 'Connect device') showUsernameInput(),
              if (_primaryButton != 'Create account')
                showPasswordInput(_primaryButton == 'Connect device'
                    ? 'Password wifi'
                    : 'Password'),
              if (_primaryButton == 'Connect device')
                showHostInput('Server address'),
              if (_primaryButton == 'Connect device')
                showPasswordInput('Password device'),
              if (_primaryButton == 'Login') showCheckBoxRememberMe(),
              // if (_primaryButton == 'Connect device') showConnectDevice(),
              showPrimaryButton(context),
              showSecondaryButton(context),
              showthirdButton(context),
              showErrorMessage(),
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
      padding: const EdgeInsets.fromLTRB(0.0, 15.0, 0.0, 0.0),
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
      return new Text(
        _errorMessage,
        style: TextStyle(
            fontSize: 13.0,
            color: Colors.red,
            height: 1.0,
            fontWeight: FontWeight.w300),
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
        padding: EdgeInsets.fromLTRB(0.0, 70.0, 0.0, 0.0),
        child: CircleAvatar(
          backgroundColor: Colors.transparent,
          radius: 48.0,
          child: Image.asset('assets/flutter-icon.png'),
        ),
      ),
    );
  }

  Widget showHostInput(String text) {
    return Padding(
      padding: text == 'Server address'
          ? const EdgeInsets.fromLTRB(0.0, 15.0, 0.0, 0.0)
          : const EdgeInsets.fromLTRB(0.0, 100.0, 0.0, 0.0),
      child: new TextFormField(
        controller: text == 'Server address'
            ? _serverAddressController
            : _hostController,
        maxLines: 1,
        keyboardType: TextInputType.text,
        autofocus: false,
        decoration: new InputDecoration(
            hintText: text,
            icon: new Icon(
              text == 'SSID' ? Icons.wifi : Icons.dns,
              color: Colors.grey,
            )),
        validator: (value) => value.isEmpty ? text + ' can\'t be empty' : null,
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

  Widget showPasswordInput(String text) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0.0, 15.0, 0.0, 0.0),
      child: new TextFormField(
        controller: text == 'Password device'
            ? _passwordServerController
            : _passwordController,
        maxLines: 1,
        obscureText: true,
        autofocus: false,
        decoration: new InputDecoration(
            hintText: text,
            icon: new Icon(
              Icons.lock,
              color: Colors.grey,
            )),
        validator: (value) => value.isEmpty ? text + ' can\'t be empty' : null,
      ),
    );
  }

  Widget showthirdButton(BuildContext context) {
    return new FlatButton(
        child: new Text(_thirdButton,
            // 'Connect to device',
            style: new TextStyle(fontSize: 18.0, fontWeight: FontWeight.w300)),
        onPressed: () {
          toggleFormMode(context, 3);
        });
  }

  Widget showSecondaryButton(BuildContext context) {
    return new FlatButton(
        child: new Text(_secondaryButton,
            // _isLoginForm ? 'Create an account' : 'Have an account? Sign in',
            style: new TextStyle(fontSize: 18.0, fontWeight: FontWeight.w300)),
        onPressed: () {
          toggleFormMode(context, 2);
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
            child: new Text(_primaryButton,
                // _isLoginForm ? 'Login' : 'Create account',
                style: new TextStyle(fontSize: 20.0, color: Colors.white)),
            onPressed: () {
              validateAndSubmit(context);
            },
          ),
        ));
  }
}
