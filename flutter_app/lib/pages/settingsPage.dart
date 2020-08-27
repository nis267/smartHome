import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_app/models/user.dart';
import 'package:flutter_app/pages/app_drawer.dart';
import 'package:flutter_app/pages/unused_devices.dart';
import 'package:flutter_app/services/authentication.dart';
import 'package:flutter_app/services/password_dialog.dart';
import 'package:flutter_app/services/snackBarText.dart';
import 'package:flutter_app/services/socket.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_simple_dependency_injection/injector.dart';
import 'package:settings_ui/settings_ui.dart';
// import 'package:flutter_form_builder/flutter_form_builder.dart';
import '../globals.dart' as globals;

class SettingsPage extends StatefulWidget {
  SettingsPage(
      {Key key, this.auth, this.logoutCallback})
      : super(key: key);

  static const String routeName = '/settings';
  final BaseAuth auth;
  final VoidCallback logoutCallback;

  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final injector = Injector.getInjector();
  SocketService socketService;
  final storage = new FlutterSecureStorage();
  SnackbarText _snackbarText = new SnackbarText();
  final _formKeyNewPassword = new GlobalKey<FormState>();
  final _formKeyNewName = new GlobalKey<FormState>();
  User currentUser;
  String _errorMessage;
  String _actualPassword = "";
  String _newPassword = "";
  String _repeatNewPassword = "";

  String _errorMessageActualPassword = "";
  String _errorMessageNewPassword = "";

  @override
  void initState() {
    socketService = injector.get<SocketService>();
    currentUser = globals.user;
    _errorMessage = "";
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  createDialogGenerateNewPasswordDevice(
      BuildContext contextScafold, String password) async {
    return await showDialog(
        context: contextScafold,
        builder: (BuildContext context) {
          return new AlertDialog(
            title: Text('Device password'),
            content: RichText(
              text: new TextSpan(
                // Note: Styles for TextSpans must be explicitly defined.
                // Child text spans will inherit styles from parent
                style: new TextStyle(
                  // fontSize: 14.0,
                  color: Colors.black,
                ),
                children: <TextSpan>[
                  new TextSpan(text: 'The password for a new device is '),
                  new TextSpan(
                      text: password,
                      style: new TextStyle(fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            // Text('The password for a new device is ' + password),
            actions: <Widget>[
              FlatButton(
                child: Text('Copy password to clipboard'),
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: password));
                  Navigator.of(context).pop(true);
                },
              ),
            ],
          );
        });
  }

  Widget showNameInput() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0.0, 15.0, 0.0, 0.0),
      child: new TextFormField(
        initialValue: currentUser.username,
        maxLines: 1,
        keyboardType: TextInputType.text,
        autofocus: false,
        decoration: new InputDecoration(
          labelText: 'Name',
        ),
        validator: (value) =>
          value.isEmpty ? 'Name can\'t be empty' : _errorMessage.isNotEmpty ? _errorMessage : null,
        onChanged: (value) => {
          currentUser.username = value.trim()
        },
      ),
    );
  }

  Future<User> createDialogUpdateUserName(
      BuildContext contextScafold) async {
    return await showDialog(
        context: contextScafold,
        builder: (BuildContext context) {
          return new AlertDialog(
            title: Text("Update User name"),
            content: new Form(key: _formKeyNewName, child: showNameInput()),
            actions: <Widget>[
              FlatButton(
                child: Text('Cancel'),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
              FlatButton(
                child: Text('Submit'),
                onPressed: () async {
                  final form = _formKeyNewName.currentState;
                  form.validate();
                  if (currentUser.username.isNotEmpty) {
                  try {
                    await socketService.setNewUserName(currentUser.id, currentUser.username);
                    setState(() {
                      _errorMessage = "";
                    _formKeyNewName.currentState.reset();
                    });
                  }
                  catch (e) {
                    setState(() {
                      _errorMessage = e.message;
                    });
                  }
                  final form = _formKeyNewName.currentState;
                  if (form.validate()) {
                    form.save();

                    Navigator.of(contextScafold)
                        .pop(currentUser);
                  }
                  }
                },
              ),
            ],
          );
        });
  }

  Widget showActualPasswordInput() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0.0, 15.0, 0.0, 0.0),
      child: new TextFormField(
        maxLines: 1,
        keyboardType: TextInputType.text,
        autofocus: false,
        decoration: new InputDecoration(
          labelText: 'Actual password',
        ),
        obscureText: true,
        validator: (value) =>
          value.isEmpty ? 'Actual Password can\'t be empty' : _errorMessageActualPassword.isNotEmpty ? _errorMessageActualPassword : null,
        onChanged: (value) => {
          _actualPassword = value.trim()
        },
      ),
    );
  }

  Widget showPasswordInput() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0.0, 15.0, 0.0, 0.0),
      child: new TextFormField(
        maxLines: 1,
        keyboardType: TextInputType.text,
        autofocus: false,
        decoration: new InputDecoration(
          labelText: 'New password',
        ),
        obscureText: true,
        validator: (value) =>
          value.isEmpty ? 'New password can\'t be empty' : _errorMessageNewPassword.isNotEmpty ? _errorMessageNewPassword : null,
        onChanged: (value) => {
          _newPassword = value.trim()
        },
      ),
    );
  }

  Widget showRepeatPasswordInput() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0.0, 15.0, 0.0, 0.0),
      child: new TextFormField(
        maxLines: 1,
        keyboardType: TextInputType.text,
        autofocus: false,
        decoration: new InputDecoration(
          labelText: 'Confirm password',
        ),
        obscureText: true,
        validator: (value) => 
          value.isEmpty ? 'Confirm password can\'t be empty' : _errorMessageNewPassword.isNotEmpty ? _errorMessageNewPassword : null,
        onChanged: (value) => {
          _repeatNewPassword = value.trim()
        },
      ),
    );
  }

  Future<User> createDialogUpdateUserPassword(
      BuildContext contextScafold) async {
            return await showDialog(
        context: contextScafold,
        builder: (BuildContext context) {
          return new AlertDialog(
            title: Text("Update password"),
            content: Column(mainAxisSize: MainAxisSize.min, children: [
                      new StatefulBuilder(
                        builder: (BuildContext context, StateSetter setState) {
                          return SingleChildScrollView(
                              child: ListTileTheme(
                                  child: new Container(
                                      padding: EdgeInsets.all(0.0),
                                      child: new Form(
                                          key: _formKeyNewPassword,
                                          child: new ListBody(
                                            children: <Widget>[
                                              showActualPasswordInput(),
                                              showPasswordInput(),
                                              showRepeatPasswordInput(),
                                            ],
                                          )))));
                        },
                      ),
                    ]),
            actions: <Widget>[
              FlatButton(
                child: Text('Cancel'),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
              FlatButton(
                child: Text('Submit'),
                onPressed: () async {
                  final form = _formKeyNewPassword.currentState;
                  form.validate();
                  if (_actualPassword.isNotEmpty && _newPassword.isNotEmpty && _repeatNewPassword.isNotEmpty) {
                  try {
                    await socketService.setNewUserPassword(currentUser.id, _actualPassword, _newPassword, _repeatNewPassword);
                    setState(() {
                      _errorMessageActualPassword = "";
                      _errorMessageNewPassword = "";
                    });
                  }
                  catch (e) {
                    setState(() {
                      if (e.message["actual_password"]) {
                        _errorMessageActualPassword = e.message["error_msg"];
                        _errorMessageNewPassword = "";
                      }
                      else {
                        _errorMessageNewPassword = e.message["error_msg"];
                        _errorMessageActualPassword = "";
                      }
                      });
                  }
                  if (form.validate()) {
                    form.save();
                    Navigator.of(contextScafold)
                        .pop(currentUser);
                  }
                }
                },
              ),
            ],
          );
        });
  }
  
  @override
  Widget build(BuildContext context) {
    // widget widget = ModalRoute.of(context).settings.arguments;
    return new Scaffold(
        appBar: AppBar(
          title: Text("Settings"),
        ),
        drawer: AppDrawer(
          auth: widget.auth,
          logoutCallback: widget.logoutCallback,
          currentRoute: 'Settings',
        ),
        body: SettingsList(
          sections: [
            SettingsSection(
              title: 'Account',
              tiles: [
                SettingsTile(
                  title: 'Change user name',
                  subtitle: currentUser.username,
                  leading: Icon(Icons.person),
                  onTap: () {
                    createDialogUpdateUserName(context).then((newUserName) async => {
                      globals.user = await widget.auth.getCurrentUser(),
                      currentUser = globals.user,
                      setState(() {
                        }),
                      // _snackbarText.showSnackBarText(
                      //   context, 'User name modified'),
                    });
                  },
                ),
                SettingsTile(
                  title: 'Change password',
                  leading: Icon(Icons.lock),
                  onTap: () {
                    createDialogUpdateUserPassword(context);
                    
                  },
                ),
                SettingsTile(
                  title: 'Email',
                  subtitle: 'test@test.de',
                  leading: Icon(Icons.email),
                  onTap: () {},
                )
              ],
            ),
            SettingsSection(
              title: 'Devices',
              tiles: [
                SettingsTile(
                  title: 'Generate new device password',
                  leading: Icon(Icons.lock),
                  onTap: () async {
                    String password =
                        await socketService.getDeviceNewPassword();
                    createDialogGenerateNewPasswordDevice(context, password).then((value) {
                      // if (value != null && value == true)
                      // {
                      //   _snackbarText.showSnackBarText(context, 'Password copied to clipboard');
                      // }
                    });
                    // _netUtil.post(url)
                  },
                ),
                SettingsTile(
                  title: 'Unused devices',
                  leading: Icon(Icons.devices),
                  onTap: () {
                    Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => UnusedDevicesPage(),
                                  ),
                                );
                  },
                )
              ],
            )
          ],
        ));
  }
}
