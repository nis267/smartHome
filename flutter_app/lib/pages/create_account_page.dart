import 'package:flutter/material.dart';
import 'package:flutter_app/services/authentication.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CreateAccountPage extends StatefulWidget {
  CreateAccountPage({this.auth});

  final BaseAuth auth;

  @override
  State<StatefulWidget> createState() => new _CreateAccountPageState();
}

class _CreateAccountPageState extends State<CreateAccountPage> {
  final _formKey = new GlobalKey<FormState>();
  final _hostController = TextEditingController();
  final _usernameController = TextEditingController();
  String _errorMessage;
  bool _isLoading;
  bool rememberMe = false;

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
  void validateAndSubmit(BuildContext context) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _errorMessage = "";
      _isLoading = true;
    });
    if (validateAndSave()) {
      try {
        if (rememberMe == true) {
          prefs.setStringList('createAccount', [
            _hostController.text,
            _usernameController.text,
          ]);
        }
        await widget.auth.signUp(_hostController.text, _usernameController.text);
        if (mounted) {
        setState(() {
          _isLoading = false;
        });
        Navigator.popAndPushNamed(context, '/');
        }
      } catch (e) {
        if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = e.message;
        });
        }
      }
    }
  }

  @override
  void initState() {
    initCreateAccountCredentials();
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
  }

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
        appBar: new AppBar(
          title: new Text('SmartHome'),
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
          child: new ListView(
            shrinkWrap: true,
            children: <Widget>[
              showLogo(),
              showHostInput(),
              showUsernameInput(),
              showErrorMessage(),
              showCheckBoxRememberMe(),
              showPrimaryButton(context),
              showSecondaryButton(context),
              showthirdButton(context),
            ],
          ),
        ));
  }

   void initCreateAccountCredentials() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool rememberMeTmp = prefs.getBool('rememberMeCreateAccount');
    if (rememberMeTmp != null) {
      rememberMe = rememberMeTmp;
      if (rememberMe == false) {
        await prefs.remove('createAccount');
      }
    }
    List<String> loginList = prefs.getStringList('createAccount');
    if (loginList != null) {
      _hostController.text = loginList[0];
      _usernameController.text = loginList[1];
    }
    setState(() {});
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

  void _onChangedCheckBoxRememberMe(bool newValue) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    rememberMe = newValue;
    setState(() {
      prefs.setBool("rememberMeCreateAccount", rememberMe);
    });
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
            icon: new Icon(Icons.dns,
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
        child: new Text('Have an account? Sign in',
            style: new TextStyle(fontSize: 18.0, fontWeight: FontWeight.w300)),
        onPressed: () {
          Navigator.popAndPushNamed(context, '/');
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
            child: new Text('Create account',
                style: new TextStyle(fontSize: 20.0, color: Colors.white)),
            onPressed: () {
              validateAndSubmit(context);
            },
          ),
        ));
  }
}
