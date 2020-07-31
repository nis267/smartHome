import 'dart:async';
import 'dart:convert';
// import 'dart:html';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_app/models/device.dart';
import 'package:flutter_app/models/user.dart';
import 'package:flutter_app/services/socket.dart';
import 'package:flutter_simple_dependency_injection/injector.dart';
import 'package:flutter_app/services/http_request.dart';
import 'package:flutter_simple_dependency_injection/injector.dart';
import 'package:flutter_app/services/dependency_injection.dart';
import 'package:flutter_app/services/app_initializer.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

Injector injector;

abstract class BaseAuth {
  Future<String> signIn(String host, String username, String password);

  Future<String> signUp(String host, String username);

  Future<String> connectDevice(String ssid, String passwordWifi, String serverAddress, String passwordServer);

  Future<User> getCurrentUser();

  Future<void> sendEmailVerification();

  Future<void> signOut();

  Future<bool> isEmailVerified();

  // Future<List<Device>> getDeviceModelData();

  Future<void> sendAction(String socketId, int state);
}

Future<dynamic> getJsonFromJWT(String token) async {
  final parts = token.split('.');
  String normalizedSource = base64Url.normalize(parts[1]);
  return json.decode(utf8.decode(base64Url.decode(normalizedSource)));
}

List<Device> parsedDevices(dynamic response) {
  final parsed = response.cast<Map<String, dynamic>>();

  return parsed.map<Device>((json) => Device.fromJson(json)).toList();
}

Future<List<Device>> isolateDevices(dynamic response) async {
  return compute(parsedDevices, response);
}

List<User> parsedUsers(dynamic response) {
  final parsed = response.cast<Map<String, dynamic>>();

  return parsed.map<User>((json) => User.fromJson(json)).toList();
}

Future<List<User>> isolateUsers(dynamic response) async {
  return compute(parsedUsers, response);
}

class Auth implements BaseAuth {
  final injector = Injector.getInjector();
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  NetworkUtil _netUtil = new NetworkUtil();
  final storage = new FlutterSecureStorage();
  String _host;
  // Injector injector
  // injector = Injector.getInjector();
  Future<String> signIn(String host, String username, String password) async {
    final SocketService socketService = injector.get<SocketService>();
    _host = host;
    final loginUrl = "http://" + host + ":8080/login";

    String basicAuth = 'Basic ' + base64Encode(utf8.encode('$username:$password'));
    Map<String, String> headers = {
      'content-type': 'application/json',
      'accept': 'application/json',
      'authorization': basicAuth
    };

    final jwt = await _netUtil.post(loginUrl, headers: headers,
    );
      print("there");

      print("token: ");
      print(jwt);
    print("after");
    if (jwt["error"]) {
      throw new Exception(jwt["error_msg"]);
    }
    if (jwt != null) {
      socketService.createSocketConnection(host, jwt['token']);
    }
    await storage.write(key: 'token', value: jwt['token']);
    final result = await getJsonFromJWT(await storage.read(key: 'token'));
    return result['uid'].toString();
  }

  Future<String> signUp(String host, String username) async {
    _host = host;
    final loginUrl = "http://" + host + ":8080/signup";

    var data = {
      "username": username,
    };

    String body = jsonEncode(data);

    var headers = {
      'Content-Type': 'application/json',
    };
    final result = await _netUtil.post(
      loginUrl,
      headers: headers,
      body: body,
    );
    if (result["error"]) {
      print('here error');
      throw new Exception(result["error_msg"]);
    }

    return 'user.uid'; // TODO
  }

  Future<String> connectDevice(String ssid, String passwordWifi, String serverAddress, String passwordServer) async {
    final loginUrl = "http://192.168.4.1:80/";

    var data = {
      "ssid": ssid,
      "password_wifi": passwordWifi,
      "server_address": serverAddress,
      "password_server": passwordServer
    };

    String body = jsonEncode(data);

    var headers = {
      'Content-Type': 'application/json',
    };
    final result = await _netUtil.post(
      loginUrl,
      headers: headers,
      body: body,
    );


    if (result["error"]) {
      print('here error:');
      print(result["error_msg"]);
      throw new Exception(result["error_msg"]);
    }

    return result["success"];
  }
  

  Future<User> getCurrentUser() async {
    if (_host == null) {
      return null;
    }
    final userUrl = "http://" + _host + ":8080/user";
    final json = await getJsonFromJWT(await storage.read(key: 'token'));
    var data = {
      "id": json['uid'],
    };
    String body = jsonEncode(data);
    String token = await storage.read(key: 'token');
    var headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token'
    };
    final result = await _netUtil.post(
      userUrl,
      headers: headers,
      body: body,
    );
    List<User> users;
    if (result != null) {
      users = await isolateUsers(result);
      print("user authentification");
      print(users[0].id);
      // user = new User(result['id'], result['room_id'] == null ? 0 : result['room_id'], result['name'], result['socket_id']);
    } else {
      users = null;
    }
    return users[0];
  }

  Future<void> sendAction(String socketId, int state) async {
    final SocketService socketService = injector.get<SocketService>();

    socketService.sendAction(socketId, state);
  }

  Future<void> signOut() async {
    final SocketService socketService = injector.get<SocketService>();
    storage.delete(key: 'token');
    socketService.closeSocketConnection();
    // return _firebaseAuth.signOut();
  }

  Future<void> sendEmailVerification() async {
    FirebaseUser user = await _firebaseAuth.currentUser();
    user.sendEmailVerification();
  }

  Future<bool> isEmailVerified() async {
    FirebaseUser user = await _firebaseAuth.currentUser();
    return user.isEmailVerified;
  }
}
