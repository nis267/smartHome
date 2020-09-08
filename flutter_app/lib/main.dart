import 'package:flutter/material.dart';
import 'package:flutter_app/pages/connect_device_page.dart';
import 'package:flutter_app/pages/create_account_page.dart';
import 'package:flutter_app/services/authentication.dart';
import 'package:flutter_app/pages/root_page.dart';
import 'package:flutter_phoenix/flutter_phoenix.dart';
import 'package:flutter_simple_dependency_injection/injector.dart';
import 'package:flutter_app/services/dependency_injection.dart';
import 'package:flutter_app/services/app_initializer.dart';
import 'globals.dart' as globals;

Injector injector;

void main() async {
  DependencyInjection().initialise(Injector.getInjector());
  injector = Injector.getInjector();
  await AppInitializer().initialise(injector);
  runApp(
    Phoenix(child: new MyApp()),
  );
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    globals.context = context;
    return new MaterialApp(
        title: 'SmartHome',
        debugShowCheckedModeBanner: false,
        theme: new ThemeData(
          primarySwatch: Colors.blue,
        ),
        initialRoute: '/',
        routes: {
          '/': (context) => new RootPage(auth: new Auth()),
          '/connect_device': (context) => ConnectDevicePage(auth: new Auth()),
          '/create_account' : (context) => CreateAccountPage(auth: new Auth())
        },
        );
  }
}
