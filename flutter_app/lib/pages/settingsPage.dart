import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_app/pages/app_drawer.dart';
import 'package:flutter_app/services/authentication.dart';
import 'package:flutter_app/services/http_request.dart';
import 'package:flutter_app/services/socket.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_simple_dependency_injection/injector.dart';
import 'package:settings_ui/settings_ui.dart';

class SettingsPage extends StatefulWidget {
  SettingsPage(
      {Key key, this.auth, this.userId, this.userName, this.logoutCallback})
      : super(key: key);

  static const String routeName = '/settings';
  final BaseAuth auth;
  final VoidCallback logoutCallback;
  final int userId;
  final String userName;

  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final injector = Injector.getInjector();
  SocketService socketService;
  final storage = new FlutterSecureStorage();

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
                  Navigator.of(context).pop();
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
          userId: widget.userId,
          userName: widget.userName,
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
                  title: 'Change account name',
                  leading: Icon(Icons.person),
                  onTap: () {},
                ),
                SettingsTile(
                  title: 'Change password',
                  leading: Icon(Icons.lock),
                  onTap: () {},
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
                    print("test");
                    String password =
                        await socketService.getDeviceNewPassword();
                    print("password: ");
                    print(password);
                    createDialogGenerateNewPasswordDevice(context, password);
                    // _netUtil.post(url)
                  },
                ),
                SettingsTile(
                  title: 'Unused devices',
                  leading: Icon(Icons.devices),
                  onTap: () {},
                )
              ],
            )
          ],
        ));
  }
}
