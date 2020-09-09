import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_app/models/room.dart';
import 'package:flutter_app/pages/add_room_page.dart';
import 'package:flutter_app/pages/app_drawer.dart';
import 'package:flutter_app/pages/room_page.dart';
import 'package:flutter_app/pages/room_settings_page.dart';
import 'package:flutter_app/services/authentication.dart';
import 'package:flutter_app/services/socket.dart';
import 'package:flutter_simple_dependency_injection/injector.dart';
import 'package:flutter_app/services/snackBarText.dart';

class HomeRoomsPage extends StatefulWidget {
  HomeRoomsPage({Key key, this.auth, this.logoutCallback}) : super(key: key);

  static const String routeName = '/homeRooms';
  final BaseAuth auth;
  final VoidCallback logoutCallback;

  @override
  _HomeRoomsPageState createState() => _HomeRoomsPageState();
}

class _HomeRoomsPageState extends State<HomeRoomsPage> {
  SnackbarText _snackbarText = new SnackbarText();
  final injector = Injector.getInjector();
  SocketService socketService;
  List<Room> roomsList = [];
  final _formKey = new GlobalKey<FormState>();
  String currentSelectedName;
  bool enabled = false;

  @override
  void initState() {
    super.initState();
    socketService = injector.get<SocketService>();
    socketService.getRoomModelDataStream();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<Room> createDialogRemoveRoom(
      BuildContext contextScafold, Room room) async {
    return await showDialog(
        context: contextScafold,
        builder: (BuildContext context) {
          return new AlertDialog(
            title: Text("Delete room"),
            content: Text('You really want to delete ' + room.name + ' ?'),
            actions: <Widget>[
              FlatButton(
                child: Text('No'),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
              FlatButton(
                  child: Text('Yes'),
                  onPressed: () {
                    _snackbarText.showSnackBarText(
                        contextScafold, room.name + ' deleted');
                    Navigator.of(context).pop(room);
                  }),
            ],
          );
        });
  }

  createDialogRoomBusy(BuildContext contextScafold, Room room) async {
    return await showDialog(
        context: contextScafold,
        builder: (BuildContext context) {
          return new AlertDialog(
            title: Text("Delete room"),
            content: Text('Room ' + room.name + ' is busy'),
            actions: <Widget>[
              FlatButton(
                child: Text('Ok'),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ],
          );
        });
  }

  Widget _showRooms() {
    return Expanded(
      child: StreamBuilder(
          stream: socketService.streamRooms,
          builder: (context, snapshot) {
            if (snapshot.hasError) return Text(snapshot.error);
            if (snapshot.hasData) {
              roomsList = snapshot.data;
              return AbsorbPointer(
                  absorbing: enabled,
                  child: Column(children: [
                    Expanded(
                        child: ListView.builder(
                            physics: ClampingScrollPhysics(),
                            shrinkWrap: true,
                            itemCount: snapshot.data.length,
                            itemBuilder: (BuildContext context, int index) {
                              Room room = snapshot.data[index];
                              // AbsorbPointer(
                              // absorbing: true,
                              return Card(
                                  child: ListTile(
                                title: Text(room.name),
                                trailing: Wrap(
                                  // spacing: 12,
                                  children: [
                                    IconButton(
                                      icon: Icon(Icons.edit),
                                      onPressed: () async {
                                        bool roomExist = await socketService
                                            .checkRoomExist(room.id);
                                        if (roomExist) {
                                          Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                  builder: (context) =>
                                                      RoomSettingsPage(
                                                          room: room))).then((value) => {
                                                            if (value != null && value == true) {
                                                              _snackbarText.showSnackBarText(context, 'Room updated')
                                                            }
                                                          });
                                        } else {
                                          _snackbarText.showSnackBarText(
                                              context,
                                              room.name + ' not available');
                                        }
                                      },
                                    ),
                                    IconButton(
                                      icon: Icon(Icons.delete),
                                      onPressed: () async {
                                        bool roomEmpty = await socketService
                                            .checkRoomEmpty(room.id);
                                        if (roomEmpty) {
                                          createDialogRemoveRoom(context, room)
                                              .then((value) => {
                                                    if (value != null)
                                                      {
                                                        socketService
                                                            .deleteRoom(
                                                                value.id)
                                                      }
                                                  });
                                        } else {
                                          _snackbarText.showSnackBarText(
                                              context,
                                              'Room ' + room.name + ' is busy');
                                        }
                                      },
                                    )
                                  ],
                                ),
                                onTap: () async {
                                  bool roomExist = await socketService
                                      .checkRoomExist(room.id);
                                  if (roomExist) {
                                    widget.auth
                                        .getCurrentUser()
                                        .then((user) => {
                                              if (user.roomId == null &&
                                                  enabled == false)
                                                {
                                                  setState(() {
                                                    enabled = true;
                                                  }),
                                                  Navigator.push(
                                                    context,
                                                    MaterialPageRoute(
                                                      builder: (context) =>
                                                          RoomPage(room: room),
                                                    ),
                                                  ).then((value) => {
                                                        setState(() {
                                                          enabled = false;
                                                        })
                                                      }),
                                                }
                                            });
                                  } else {
                                    _snackbarText.showSnackBarText(
                                        context, room.name + ' not available');
                                  }
                                },
                              ));
                            })),
                    
                  ]));
            }
            return Center(child: CircularProgressIndicator());
          })
    );
  }

  Widget _showForm(BuildContext context) {
    return new Container(
        padding: EdgeInsets.all(16.0),
        child: new Form(
          key: _formKey,
          child: new Column(
            // shrinkWrap: true,
            children: <Widget>[
              _showRooms(),
              _showPrimaryButton(context),
            ],
          )
        )
    );
  }

  Widget _showPrimaryButton(BuildContext context) {
    return new SizedBox(
      width: double.infinity,
      height: 40.0,
      child: new RaisedButton(
        elevation: 5.0,
        shape: new RoundedRectangleBorder(
            borderRadius: new BorderRadius.circular(30.0)),
        color: Colors.blue,
        child: new Text('Add a room',
            style: new TextStyle(fontSize: 20.0, color: Colors.white)),
        onPressed: () {
          Navigator.push(context, MaterialPageRoute(builder: (context) => AddRoomPage())).then((value) => {
                                  if (value != null && value == true) {
                                    _snackbarText.showSnackBarText(context, 'Room added'),
                                  }
                                });
        }
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Home")),
      body: Builder(
        builder: (context) => Stack(
          children: <Widget>[
      _showForm(context),
          ],
        ),
      ),
      drawer: AppDrawer(
        auth: widget.auth,
        logoutCallback: widget.logoutCallback,
        currentRoute: 'Home',
      ),
    );
  }
}