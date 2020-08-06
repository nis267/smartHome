import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_app/models/room.dart';
import 'package:flutter_app/models/user.dart';
import 'package:flutter_app/pages/app_drawer.dart';
import 'package:flutter_app/pages/room_page.dart';
import 'package:flutter_app/services/authentication.dart';
import 'package:flutter_app/services/socket.dart';
import 'package:flutter_simple_dependency_injection/injector.dart';
import 'package:flutter_app/services/snackBarText.dart';

class HomeRoomsPage extends StatefulWidget {
  HomeRoomsPage(
      {Key key, this.auth, this.userId, this.userName, this.logoutCallback})
      : super(key: key);

  static const String routeName = '/homeRooms';
  final BaseAuth auth;
  final VoidCallback logoutCallback;
  final int userId;
  final String userName;

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

  Widget showNameInput() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0.0, 15.0, 0.0, 0.0),
      child: new TextFormField(
        initialValue: currentSelectedName,
        maxLines: 1,
        keyboardType: TextInputType.text,
        autofocus: false,
        decoration: new InputDecoration(
          labelText: 'Name',
        ),
        validator: (value) => value.isEmpty ? 'Name can\'t be empty' : null,
        onSaved: (value) => {
          currentSelectedName = value.trim(),
        },
      ),
    );
  }

  // void _snackbarText.showSnackBarText(BuildContext context, String text) {
  //   final snackBar =
  //       SnackBar(content: Text(text), duration: Duration(milliseconds: 2000));
  //   Scaffold.of(context).removeCurrentSnackBar();
  //   Scaffold.of(context).showSnackBar(snackBar);
  // }

  Future<Room> createDialogUpdateRoom(
      BuildContext contextScafold, Room room) async {
    currentSelectedName = room.name;
    return await showDialog(
        context: contextScafold,
        builder: (BuildContext context) {
          return new AlertDialog(
            title: Text("Room settings"),
            content: new Form(key: _formKey, child: showNameInput()),
            actions: <Widget>[
              FlatButton(
                child: Text('Cancel'),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
              FlatButton(
                child: Text('Submit'),
                onPressed: () {
                  final form = _formKey.currentState;
                  if (form.validate()) {
                    form.save();
                    _snackbarText.showSnackBarText(
                        contextScafold, room.name + ' is modified');
                    Navigator.of(context)
                        .pop(new Room(id: room.id, name: currentSelectedName));
                  }
                },
              ),
            ],
          );
        });
  }

  Future<String> createDialogAddRoom(BuildContext contextScafold) async {
    currentSelectedName = null;
    return await showDialog(
        context: contextScafold,
        builder: (BuildContext context) {
          return new AlertDialog(
            title: Text("Add room"),
            content: new Form(key: _formKey, child: showNameInput()),
            actions: <Widget>[
              FlatButton(
                child: Text('Cancel'),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
              FlatButton(
                child: Text('Submit'),
                onPressed: () {
                  final form = _formKey.currentState;
                  if (form.validate()) {
                    form.save();
                    _snackbarText.showSnackBarText(
                        contextScafold, currentSelectedName + ' is added');
                    Navigator.of(context).pop(currentSelectedName);
                  }
                },
              ),
            ],
          );
        });
  }

  Future<Room> createDialogRemoveRoom(BuildContext contextScafold, Room room) async {
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
                    _snackbarText.showSnackBarText(contextScafold, room.name + ' is deleted');
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Home")),
      body: StreamBuilder(
          stream: socketService.streamRooms,
          builder: (context, snapshot) {
            if (snapshot.hasError) return Text(snapshot.error);
            print("data: ");
            print(snapshot.data);
            if (snapshot.hasData) {
              roomsList = snapshot.data;
              return AbsorbPointer(
              absorbing: enabled,
              child: 
               Column(children: [

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
                                    bool roomExist = await socketService.checkRoomExist(room.id);
                                    if (roomExist) {
                                    createDialogUpdateRoom(context, room)
                                        .then((onValue) {
                                      if (onValue != null)
                                        socketService.updateRoomName(onValue);
                                    });
                                    }
                                    else {
                                      _snackbarText.showSnackBarText(context, room.name + ' not available');
                                    }
                                  },
                                ),
                                IconButton(
                                  icon: Icon(Icons.delete),
                                  onPressed: () async {
                                    bool roomEmpty = await socketService.checkRoomEmpty(room.id);
                                    print("roomEmpty: ");
                                    print(roomEmpty);
                                    if (roomEmpty) {
                                    createDialogRemoveRoom(context, room)
                                        .then((value) => {
                                              if (value != null)
                                              {
                                                socketService.deleteRoom(value.id)
                                              }
                                            });
                                    }
                                    else {
                                      _snackbarText.showSnackBarText(context, 'Room ' + room.name + ' is busy');
                                    }
                                  },
                                )
                              ],
                            ),
                            onTap: () async {
                              bool roomExist = await socketService.checkRoomExist(room.id);
                              if (roomExist) {
                              widget.auth.getCurrentUser().then((user) => {
                                if (user.roomId == null && enabled == false) {
                                setState(() {
                                  enabled = true;
                                }),
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => RoomPage(room: room),
                                  ),
                                ).then((value) => {
                                  setState(() {
                                  enabled = false;
                                })
                                }),
                              }
                              });
                              } else {
                                _snackbarText.showSnackBarText(context, room.name + ' not available');
                              }
                            },
                          )
                          );
                        })
                        ),
                Padding(
                    padding: const EdgeInsets.fromLTRB(0.0, 15.0, 0.0, 15.0),
                    child: SizedBox(
                        height: 40.0,
                        child: RaisedButton.icon(
                          elevation: 5.0,
                          icon: Icon(
                            Icons.add,
                            color: Colors.white,
                          ),
                          onPressed: () {
                            createDialogAddRoom(context).then((value) => {
                                  if (value != null)
                                    {socketService.addRoom(value)}
                                });
                          },
                          label: Text('Add a room',
                              style: new TextStyle(
                                  fontSize: 20.0, color: Colors.white)),
                          color: Colors.blue,
                          shape: new RoundedRectangleBorder(
                              borderRadius: new BorderRadius.circular(30.0)),
                        )))
              ])
      );
            }
            return Center(child: CircularProgressIndicator());
          }),
      // ),

      drawer: AppDrawer(
        userId: widget.userId,
        userName: widget.userName,
        auth: widget.auth,
        logoutCallback: widget.logoutCallback,
        currentRoute: 'Home',
      ),
    );
  }
}
