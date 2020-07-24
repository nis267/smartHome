import 'package:flutter_app/pages/home_rooms.dart';
import 'package:flutter/material.dart';
import 'package:flutter_app/pages/settingsPage.dart';
import 'package:flutter_app/services/authentication.dart';

class AppDrawer extends StatefulWidget {
  AppDrawer(
      {Key key,
      this.auth,
      this.userId,
      this.userName,
      this.logoutCallback,
      this.currentRoute})
      : super(key: key);

  final BaseAuth auth;
  final VoidCallback logoutCallback;
  final int userId;
  final String userName;
  final String currentRoute;

  @override
  _AppDrawerState createState() => _AppDrawerState();
}

class _AppDrawerState extends State<AppDrawer> {
  GlobalKey<ScaffoldState> _key = new GlobalKey<ScaffoldState>();

  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  signOut() async {
    try {
      await widget.auth.signOut();
      widget.logoutCallback();
    } catch (e) {
      print(e);
    }
  }

  Widget _createDrawerItem(
      {IconData icon, String text, GestureTapCallback onTap}) {
    return ListTile(
      title: Row(
        children: <Widget>[
          Icon(icon),
          Padding(
            padding: EdgeInsets.only(left: 8.0),
            child: Text(text),
          )
        ],
      ),
      onTap: onTap,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        children: <Widget>[
          UserAccountsDrawerHeader(
            accountName: Text(widget.userName),
            accountEmail: Text(""),
          ),
          _createDrawerItem(
              icon: Icons.home,
              text: 'Home',
              onTap: () {
                doRoute(
                    context,
                    'Home',
                    HomeRoomsPage(
                        auth: widget.auth,
                        userId: widget.userId,
                        userName: widget.userName,
                        logoutCallback: widget.logoutCallback));
              }),
          _createDrawerItem(
              icon: Icons.settings,
              text: 'Settings',
              onTap: () {
                doRoute(
                    context,
                    'Settings',
                    SettingsPage(
                        auth: widget.auth,
                        userId: widget.userId,
                        userName: widget.userName,
                        logoutCallback: widget.logoutCallback));
              }),
          new Divider(),
          _createDrawerItem(
              icon: Icons.power_settings_new,
              text: 'Logout',
              onTap: () => signOut()),
        ],
      ),
    );
  }

  void doRoute(BuildContext context, String name, dynamic function) {
    if (widget.currentRoute != name) {
      Navigator.push(
          context, MaterialPageRoute(builder: (context) => function));
    } else {
      Navigator.pop(context);
    }
  }
}
