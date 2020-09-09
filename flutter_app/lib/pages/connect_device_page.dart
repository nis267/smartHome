import 'package:flutter/material.dart';
import 'package:flutter_app/services/authentication.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ConnectDevicePage extends StatefulWidget {
  ConnectDevicePage({this.auth});

  final BaseAuth auth;

  @override
  State<StatefulWidget> createState() => new _ConnectDevicePageState();
}


class _ConnectDevicePageState extends State<ConnectDevicePage> {
  final _formKey = new GlobalKey<FormState>();
  bool rememberDevice = false;
  final _ssidController = TextEditingController();
  final _serverAddressController = TextEditingController();
  final _passwordWifiController = TextEditingController();
  final _passwordDeviceController = TextEditingController();
  String _errorMessage;
  bool _isLoading;
  bool _obscureTextPassword = true;
  bool _obscureTextPasswordWifi = true;

  // Check if form is valid before perform login or signup
  bool validateAndSave() {
    final form = _formKey.currentState;
    if (form.validate()) {
      form.save();
      return true;
    }
    return false;
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
        if (rememberDevice == true) {
          prefs.setStringList('connect_device', [
            _ssidController.text,
            _passwordWifiController.text,
            _serverAddressController.text,
            _passwordDeviceController.text
          ]);
          }
          String deviceMessage = await widget.auth.connectDevice(
              _ssidController.text,
              _passwordWifiController.text,
              _serverAddressController.text,
              _passwordDeviceController.text);
          if (mounted) {
          Navigator.popAndPushNamed(context, '/');
        setState(() {
          _isLoading = false;
        });
          }
      } catch (e) {
        if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = e.message;
          _formKey.currentState.reset();
        });
        }
      }
    }
  }

  void init() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool rememberDeviceTmp = prefs.getBool('rememberDevice');
    if (rememberDeviceTmp != null) {
      rememberDevice = rememberDeviceTmp;
      if (rememberDevice == false) {
        await prefs.remove('connect_device');
      }
    }
    List<String> deviceFormDataList = prefs.getStringList('connect_device');
    print(deviceFormDataList);
    if (deviceFormDataList != null) {
      _ssidController.text = deviceFormDataList[0];
      _passwordWifiController.text = deviceFormDataList[1];
      _serverAddressController.text = deviceFormDataList[2];
      _passwordDeviceController.text = deviceFormDataList[3];
    }
    setState(() {});
  }

  @override
  void initState() {
    init();
    _errorMessage = "";
    _isLoading = false;
    super.initState();
  }

  void resetForm() {
    _formKey.currentState.reset();
    _errorMessage = "";
  }

  void resetTextControllers() {
    _ssidController.clear();
    _serverAddressController.clear();
    _passwordWifiController.clear();
    _passwordDeviceController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
        appBar: new AppBar(
          title: new Text('SmartHome'),
        ),
        body: Builder(builder: (context) => Stack(
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
              showSsidInput(),
              showPasswordWifiInput(),
              showServerAddressInput(),
              showPasswordDeviceInput(),
              showCheckBoxRememberDevice(),
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
    rememberDevice = newValue;
    setState(() {
      prefs.setBool("rememberDevice", rememberDevice);
    });
  }

  Widget showCheckBoxRememberDevice() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0.0, 15.0, 0.0, 0.0),
      child: new CheckboxListTile(
        title: Text("Remember device"),
        value: rememberDevice,
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
        padding: EdgeInsets.fromLTRB(0.0, 30.0, 0.0, 0.0),
        child: CircleAvatar(
          backgroundColor: Colors.transparent,
          radius: 48.0,
          child: Image.asset('assets/flutter-icon.png'),
        ),
      ),
    );
  }

  Widget showSsidInput() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0.0, 100.0, 0.0, 0.0),
      child: new TextFormField(
        controller: _ssidController,
        maxLines: 1,
        keyboardType: TextInputType.text,
        autofocus: false,
        decoration: new InputDecoration(
            hintText: 'SSID',
            icon: new Icon(Icons.wifi,
              color: Colors.grey,
            )),
        validator: (value) => value.isEmpty ?  'SSID can\'t be empty' : null,
      ),
    );
  }

  Widget showServerAddressInput() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0.0, 15.0, 0.0, 0.0),
      child: new TextFormField(
        controller: _serverAddressController,
        maxLines: 1,
        keyboardType: TextInputType.text,
        autofocus: false,
        decoration: new InputDecoration(
            hintText: 'Server address',
            icon: new Icon(Icons.dns,
              color: Colors.grey,
            )),
        validator: (value) => value.isEmpty ? 'Server address can\'t be empty' : null,
      ),
    );
  }

  Widget showPasswordWifiInput() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0.0, 15.0, 0.0, 0.0),
      child: new TextFormField(
        controller: _passwordWifiController,
        maxLines: 1,
        obscureText: _obscureTextPasswordWifi,
        autofocus: false,
        decoration: new InputDecoration(
          suffixIcon: GestureDetector(
            onTap: () {
              setState(() {
                _obscureTextPasswordWifi = !_obscureTextPasswordWifi;
              });
            },
            child: Icon(
              _obscureTextPasswordWifi ? Icons.visibility : Icons.visibility_off,
              semanticLabel: _obscureTextPasswordWifi ? 'show password' : 'hide password',
            ),
          ),
            hintText: 'Password wifi',
            icon: new Icon(
              Icons.lock,
              color: Colors.grey,
            )),
        validator: (value) => value.isEmpty ? 'Password wifi can\'t be empty' : null,
      ),
    );
  }

  Widget showPasswordDeviceInput() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0.0, 15.0, 0.0, 0.0),
      child: new TextFormField(
        controller: _passwordDeviceController,
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
            )
          ),
            hintText: 'Password device',
            icon: new Icon(
              Icons.lock,
              color: Colors.grey,
            )),
        validator: (value) => value.isEmpty ? 'Password device can\'t be empty' : null,
      ),
    );
  }

  Widget showthirdButton(BuildContext context) {
    return new FlatButton(
        child: new Text('Create an account',
            style: new TextStyle(fontSize: 18.0, fontWeight: FontWeight.w300)),
        onPressed: () {
          Navigator.popAndPushNamed(context, '/create_account');
        });
  }

  Widget showSecondaryButton(BuildContext context) {
    return new FlatButton(
        child: new Text('Have an account? Sign in',
            style: new TextStyle(fontSize: 18.0, fontWeight: FontWeight.w300)),
        onPressed: () {
    setState(() {
      _isLoading = false;
    });
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
            child: new Text('Connect device',
                style: new TextStyle(fontSize: 20.0, color: Colors.white)),
            onPressed: () {
              validateAndSubmit(context);
            },
          ),
        ));
  }
}
