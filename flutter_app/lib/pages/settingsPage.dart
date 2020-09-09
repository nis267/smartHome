import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_app/pages/app_drawer.dart';
import 'package:flutter_app/pages/change_email_page.dart';
import 'package:flutter_app/pages/change_password_page.dart';
import 'package:flutter_app/pages/change_username_page.dart';
import 'package:flutter_app/pages/remove_account.dart';
import 'package:flutter_app/pages/remove_devices.dart';
import 'package:flutter_app/services/authentication.dart';
import 'package:flutter_app/services/snackBarText.dart';
import 'package:flutter_app/services/socket.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_simple_dependency_injection/injector.dart';
import 'package:settings_ui/settings_ui.dart';
import '../globals.dart' as globals;

class SettingsPage extends StatefulWidget {
  SettingsPage({Key key, this.auth, this.logoutCallback}) : super(key: key);

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

  @override
  void initState() {
    socketService = injector.get<SocketService>();
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
        body: Builder(
            builder: (context) => SettingsList(
                  sections: [
                    SettingsSection(
                      title: 'Account',
                      tiles: [
                        SettingsTile(
                          title: 'Change user name',
                          subtitle: globals.user.username,
                          leading: Icon(Icons.person),
                          onTap: () {
                            Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => ChangeUsernamePage(
                                          userId: globals.user.id,
                                          username: globals.user.username,
                                        ))).then((value) => {
                              if (value != null && value == true)
                              {
                                setState(() {}),
                                _snackbarText.showSnackBarText(context, 'Username updated'),
                              },
                              });
                          },
                        ),
                        SettingsTile(
                          title: 'Change password',
                          leading: Icon(Icons.lock),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => ChangePasswordPage(
                                      userId: globals.user.id)),
                            ).then((value) => {
                              if (value != null && value == true)
                              {
                                setState(() {}),
                                _snackbarText.showSnackBarText(context, 'Password updated'),
                              },
                              });;
                          },
                        ),
                        SettingsTile(
                          title: 'Change email',
                          subtitle: globals.user.email,
                          leading: Icon(Icons.email),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ChangeEmailPage(
                                  userId: globals.user.id,
                                  email: globals.user.email,
                                ),
                              ),
                            ).then((value) => {
                              if (value != null && value == true)
                              {
                                setState(() {}),
                                _snackbarText.showSnackBarText(context, 'Email updated'),
                              },
                              });
                          },
                        ),
                        SettingsTile(
                          title: 'Remove account',
                          leading: Icon(Icons.delete, color: Colors.red,),
                          onTap: () {
                            Navigator.push(context, MaterialPageRoute(builder: (context) => RemoveAccountPage(user: globals.user, logoutCallback: widget.logoutCallback,)));
                          },
                        ),
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
                            createDialogGenerateNewPasswordDevice(
                                    context, password)
                                .then((value) {
                              if (value != null && value == true) {
                                _snackbarText.showSnackBarText(
                                    context, 'Password copied to clipboard');
                              }
                            });
                          },
                        ),
                        SettingsTile(
                          title: 'Remove devices',
                          leading: Icon(Icons.devices),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => RemoveDevicesPage(),
                              ),
                            ).then((value) => {
                              if (value != null && value == true) {
                                _snackbarText.showSnackBarText(context, "Devices removed")
                              }
                            });
                          },
                        )
                      ],
                    )
                  ],
                )));
  }
}
