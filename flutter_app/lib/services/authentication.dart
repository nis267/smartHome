import 'dart:async';
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_login_demo/models/device.dart';
import 'package:flutter_login_demo/models/user.dart';
import 'package:flutter_login_demo/services/socket.dart';
import 'package:flutter_simple_dependency_injection/injector.dart';
import 'package:flutter_login_demo/services/http_request.dart';


import 'package:flutter_simple_dependency_injection/injector.dart';
import 'package:flutter_login_demo/services/dependency_injection.dart';
import 'package:flutter_login_demo/services/app_initializer.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

Injector injector;

abstract class BaseAuth {
  Future<String> signIn(String host, String username, String password);

  Future<String> signUp(String host, String username);

  Future<User> getCurrentUser();

  Future<void> sendEmailVerification();

  Future<void> signOut();

  Future<bool> isEmailVerified();

  Future<List<Device>> getDeviceModelData();
}

class Auth implements BaseAuth {
  
  final injector = Injector.getInjector();
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  NetworkUtil _netUtil = new NetworkUtil();
  final storage = new FlutterSecureStorage();
  String _host;
  // Injector injector
  // injector = Injector.getInjector();

  Future<dynamic> getJsonFromJWT(String token) async {
    final parts = token.split('.');
    String normalizedSource = base64Url.normalize(parts[1]);
    return json.decode(utf8.decode(base64Url.decode(normalizedSource)));
  }

  Future<String> signIn(String host, String username, String password) async {
    final SocketService socketService = injector.get<SocketService>();
    _host = host;
    final loginUrl = "http://" + host + ":8080/login";

    final jwt = await _netUtil.post(loginUrl, body: {
      // "token": _API_KEY,
      "username": username,
      "password": password
    });
    await storage.write(key: 'token', value: jwt['token']);
    if(jwt["error"]) {
        throw new Exception(jwt["error_msg"]);
      }
    if (jwt != null)
    {
      socketService.createSocketConnection(host, jwt['token']);
    }
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
    final result = await _netUtil.post(loginUrl,
    headers: headers,
    body: body,
    );
    if(result["error"]) {
        print('here error');
        throw new Exception(result["error_msg"]);
      }
    
    return 'user.uid'; // TODO
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
    final result = await _netUtil.post(userUrl,
    headers: headers,
    body: body,
    );
    User user;
    if (result != null) {
      user = new User(result['id'].toString(), result['room_id'], result['name'], result['socket_id']);
    }
    else {
      user = null;
    }
    return user;
  }

  Future<List<Device>> getDeviceModelData() async {
    // var dbClient = await db;
    // String sql;
    // sql = "SELECT * FROM user";
    print("host: ");
    print(_host);
    final userUrl = "http://192.168.0.143:8080/devices";
    final json = await getJsonFromJWT(await storage.read(key: 'token'));
    // var data = {
    //   "id": json['uid'],
    // };
    // String body = jsonEncode(data);
    String token = await storage.read(key: 'token');
    var headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token'
    };
    final result = await _netUtil.post(userUrl,
    headers: headers,
    // body: body,
    );
    print("result: ");
    print(result);
    print("result length: ");
    print(result.length);

    if (result.length == 0) return null;

    print("here\n\n\n\n\n\n\n\n\n");
    List<Device> list = result.map((item) {
      print("item name");
      print(item["name"]);
      item["name"] = "test";
      item["room_id"] = "test";
      // return Device.map(item);
      return item;
    }).toList();
    print("\n\n\n\n\n\n\n\n\n\n\n\nresult: ");
    print(result);
    print("\n\n\n\n\n\n\n\n\n\n\n\nresult: ");
    // print(list);
    return list;
    // Device device = new Device(result['id'], result['room_id'], result['name'], result['socket_id'], result['mac_address'], result['state']);

    // return device;
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
