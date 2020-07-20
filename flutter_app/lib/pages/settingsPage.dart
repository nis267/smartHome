import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_app/models/drawer_data.dart';
import 'package:flutter_app/pages/app_drawer.dart';
import 'package:flutter_app/services/authentication.dart';


class SettingsPage extends StatefulWidget {
  SettingsPage({Key key, this.auth, this.userId, this.userName, this.logoutCallback})
      : super(key: key);
  
  static const String routeName = '/settings';
  final BaseAuth auth;
  final VoidCallback logoutCallback;
  final String userId;
  final String userName;

  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {

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
        body: Center(child: Text("Settings")));
  }
}