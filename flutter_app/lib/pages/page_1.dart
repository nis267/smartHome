import 'package:flutter/material.dart';
import 'package:flutter_app/models/device.dart';
import 'package:flutter_app/services/authentication.dart';
import 'dart:async';
import 'dart:convert';

import 'package:flutter_app/services/http_request.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class Page1 extends StatefulWidget {
  Page1({Key key, this.auth})
    : super(key: key);

  final BaseAuth auth;
  @override
  _Page1State createState() => _Page1State();
}
  
// class _Page1State extends State<Page1> {
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: Center(
//         child: Text(
//           "This page is to add Item",
//         ),
//       ),

//       floatingActionButton: FloatingActionButton(
//         child: Icon(
//           Icons.add,
//         ),
//         onPressed: (){},
//       ),
//     );
//   }
// }

class _Page1State extends State<Page1> {
 @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Fetching data from DB - ListView'),
      ),
      body: FutureBuilder<List<Device>>(
        future: widget.auth.getDeviceModelData(),
        builder: (context, snapshot) {
          print("snapshot: ");
          print(snapshot.hasData);
          if (!snapshot.hasData) return Center(child: CircularProgressIndicator());

          return ListView(
            children: snapshot.data
                .map((device) => ListTile(
                      title: Text(device.name == null ? "" : device.name),
                      subtitle: Text(device.macAddress),
                      leading: CircleAvatar(
                        backgroundColor: Colors.red,
                        child: Text(device.name == null ? "" : device.name,
                            style: TextStyle(
                              fontSize: 18.0,
                              color: Colors.white,
                            )),
                      ),
                    ))
                .toList(),
          );
        },
      ),
    );
  }
}