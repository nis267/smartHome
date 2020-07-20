import 'package:flutter/material.dart';
import 'package:flutter_app/services/authentication.dart';

class DrawerData {
  // Key key;
  BaseAuth auth;
  String userId;
  String userName;
  void Function() logoutCallback;

  DrawerData(this.auth, this.userId, this.userName, this.logoutCallback);
}