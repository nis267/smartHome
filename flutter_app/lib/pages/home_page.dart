import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_app/models/drawer_data.dart';
import 'package:flutter_app/pages/app_drawer.dart';
import 'package:flutter_app/services/authentication.dart';

class HomePage extends StatefulWidget {
  HomePage({Key key, this.auth, this.userId, this.userName, this.logoutCallback})
      : super(key: key);

  static const String routeName = '/home';
  final BaseAuth auth;
  final VoidCallback logoutCallback;
  final String userId;
  final String userName;

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  Widget build(BuildContext context) {
    print("username: ");
    print(widget.userName);
    // DrawerData drawerData = ModalRoute.of(context).settings.arguments;
    return Scaffold(
      appBar: AppBar(title: Text("SmartHome")),
      body: Container(color: Colors.blue.withOpacity(0.5)),
      // drawer: AppDrawer(),
      // drawer: buildDrawer(context)
      drawer: AppDrawer(
        // key: drawerData.key,
        userId: widget.userId,
        userName: widget.userName,
        auth: widget.auth,
        logoutCallback: widget.logoutCallback,
      ),
    );
  }
}
