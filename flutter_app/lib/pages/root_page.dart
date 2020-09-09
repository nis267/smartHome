import 'package:flutter/material.dart';
import 'package:flutter_app/models/user.dart';
import 'package:flutter_app/pages/choose_email_page.dart';
import 'package:flutter_app/pages/choose_password_page.dart';
import 'package:flutter_app/pages/home_rooms.dart';
import 'package:flutter_app/pages/login_signup_page.dart';
import 'package:flutter_app/services/authentication.dart';
import 'package:flutter_app/services/socket.dart';
import 'package:flutter_simple_dependency_injection/injector.dart';
import '../globals.dart' as globals;

enum AuthStatus {
  NOT_DETERMINED,
  NOT_LOGGED_IN,
  LOGGED_IN,
}

class RootPage extends StatefulWidget {
  RootPage({this.auth});

  final BaseAuth auth;

  @override
  State<StatefulWidget> createState() => new _RootPageState();
}

class _RootPageState extends State<RootPage> {
  final injector = Injector.getInjector();
  SocketService socketService;
  AuthStatus authStatus = AuthStatus.NOT_DETERMINED;

  @override
  void initState() {
    socketService = injector.get<SocketService>();
    widget.auth.getCurrentUser().then((user) {
      setState(() {
        if (user != null) {
          globals.user = user;
          print(globals.user);
        }
        print("user here:");
          print(user);
        authStatus =
            user?.id == null ? AuthStatus.NOT_LOGGED_IN : AuthStatus.LOGGED_IN;
      });
    });
    super.initState();
  }

  void loginCallback() {
    widget.auth.getCurrentUser().then((user) {
      setState(() {
        globals.user = user;
      });
      print("user here callback:");
      print(user.passwordChanged);
    });
    setState(() {
      authStatus = AuthStatus.LOGGED_IN;
    });
  }

  void logoutCallback() async {
    setState(() {
      authStatus = AuthStatus.NOT_LOGGED_IN;
      globals.user = null;
    });
    await widget.auth.signOut();
  }

  Widget buildWaitingScreen() {
    return Scaffold(
      body: Container(
        alignment: Alignment.center,
        child: CircularProgressIndicator(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    switch (authStatus) {
      case AuthStatus.NOT_DETERMINED:
        return buildWaitingScreen();
        break;
      case AuthStatus.NOT_LOGGED_IN:
        return new LoginSignupPage(
          auth: widget.auth,
          loginCallback: loginCallback,
        );
        break;
      case AuthStatus.LOGGED_IN:
        if (globals.user != null && globals.user.id != 0) {
          if (globals.user.passwordChanged == 0) {
            return ChoosePasswordPage(
              userId: globals.user.id,
              loginCallback: loginCallback
              );
          }
          if (globals.user.emailEntered == 0) {
            return ChooseEmailPage(
              userId: globals.user.id,
              loginCallback: loginCallback
            );
          }
          return new HomeRoomsPage(
            auth: widget.auth,
            logoutCallback: logoutCallback,
            );
        } else
          return buildWaitingScreen();
        break;
      default:
        return buildWaitingScreen();
    }
  }
}
