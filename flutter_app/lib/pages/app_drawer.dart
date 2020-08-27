import 'package:flutter_app/models/user.dart';
import 'package:flutter_app/pages/home_rooms.dart';
import 'package:flutter/material.dart';
import 'package:flutter_app/pages/settingsPage.dart';
import 'package:flutter_app/services/authentication.dart';
import 'package:flutter_app/services/socket.dart';
import 'package:flutter_simple_dependency_injection/injector.dart';
import '../globals.dart' as globals;

class AppDrawer extends StatefulWidget {
  AppDrawer(
      {Key key,
      this.auth,
      this.logoutCallback,
      this.currentRoute})
      : super(key: key);

  final BaseAuth auth;
  final VoidCallback logoutCallback;
  final String currentRoute;

  @override
  _AppDrawerState createState() => _AppDrawerState();
}

class _AppDrawerState extends State<AppDrawer> {
  final injector = Injector.getInjector();
  SocketService socketService;
  
  GlobalKey<ScaffoldState> _key = new GlobalKey<ScaffoldState>();

  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
  }

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
    
    // return Drawer(
    //   child: FutureBuilder(
    //     future: widget.auth.getCurrentUser(),
    //     builder: (context, future) {
    //       if (!future.hasData) {
    //         return new Center(child: CircularProgressIndicator());
    //       }
    //       if (future.hasData)
    //       return ListView(
    //     children: <Widget>[
    //       UserAccountsDrawerHeader(
    //         accountName: Text(globals.user.username),
    //         accountEmail: Text(""),
    //       ),
    //       _createDrawerItem(
    //           icon: Icons.home,
    //           text: 'Home',
    //           onTap: () {
    //             doRoute(
    //                 context,
    //                 'Home',
    //                 HomeRoomsPage(
    //                     auth: widget.auth,
    //                     logoutCallback: widget.logoutCallback));
    //           }),
    //       _createDrawerItem(
    //           icon: Icons.settings,
    //           text: 'Settings',
    //           onTap: () {
    //             doRoute(
    //                 context,
    //                 'Settings',
    //                 SettingsPage(
    //                     auth: widget.auth,
    //                     logoutCallback: widget.logoutCallback));
    //           }),
    //       new Divider(),
    //       _createDrawerItem(
    //           icon: Icons.power_settings_new,
    //           text: 'Logout',
    //           onTap: () => signOut()),
    //     ],
    //   );
    //     }
    //     ));
    print("global user: ");
    print(globals.user);
    
    return Drawer(
      child: ListView(
        children: <Widget>[
          UserAccountsDrawerHeader(
            accountName: Text(globals.user.username),
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
