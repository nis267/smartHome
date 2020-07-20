import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_app/models/drawer_data.dart';
import 'package:flutter_app/models/room.dart';
import 'package:flutter_app/pages/app_drawer.dart';
import 'package:flutter_app/pages/page_1.dart';
import 'package:flutter_app/services/authentication.dart';
import 'package:flutter_app/services/socket.dart';
import 'package:flutter_simple_dependency_injection/injector.dart';

class HomeRoomsPage extends StatefulWidget {
  HomeRoomsPage(
      {Key key, this.auth, this.userId, this.userName, this.logoutCallback})
      : super(key: key);

  static const String routeName = '/homeRooms';
  final BaseAuth auth;
  final VoidCallback logoutCallback;
  final String userId;
  final String userName;

  @override
  _HomeRoomsPageState createState() => _HomeRoomsPageState();
}

class _HomeRoomsPageState extends State<HomeRoomsPage> {
  final injector = Injector.getInjector();
  PageController _pageController;
  SocketService socketService;
  List<Room> roomsList = [];
  List<FocusNode> myFocusNodes = new List<FocusNode>();
  List<bool> _isEditingText = new List<bool>();
  // TextEditingController _editingController;

  @override
  void initState() {
    super.initState();

    print("userName: " + widget.userName);

    socketService = injector.get<SocketService>();
    // drawerItems =
    print("userId: ");
    print(widget.userId);
    // socketService.getRoomModelData().then((value) => {
    //       setState(() {
    //         roomsList = value;
    //         print(roomsList);
    //       })
    //     });
    // _pageController = PageController(initialPage: 0);
    print("roomList: ");
    print(roomsList);
    // _editingController = TextEditingController(text: 'test');
    // _editingController.
    // myFocusNode = FocusNode();
  }

  @override
  void dispose() {
    // Clean up the focus node when the Form is disposed.
    // myFocusNode.dispose();
    print("dispose");
    for (int i = 0; i < roomsList.length; i++) {
      myFocusNodes[i].unfocus();
      myFocusNodes[i].dispose();
    }
    super.dispose();
  }

  int tmpIndex = -1;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () {
          if (tmpIndex > -1) {
            setState(() {
              _isEditingText[tmpIndex] = false;
            });
            tmpIndex = -1;
          }
          FocusScope.of(context).requestFocus(new FocusNode());
        },
        child: Scaffold(
          appBar: AppBar(title: Text("Home")),
          body: FutureBuilder(
                  future: socketService.getRoomModelData(),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) return Text(snapshot.error);
                    if (snapshot.hasData) {
                      roomsList = snapshot.data;
                      for (int i = 0; i < roomsList.length; i++) {
                        myFocusNodes.add(FocusNode());
                        myFocusNodes[i].requestFocus();
                        _isEditingText.add(false);
                      }
                      return ListView.builder(
                          physics: ClampingScrollPhysics(),
                          shrinkWrap: true,
                          itemCount: snapshot.data.length,
                          itemBuilder: (BuildContext context, int index) {
                            Room room = snapshot.data[index];
                            return ListTile(
                              title: TextFormField(
                                // controller: ,
                                initialValue: room.name,
                                focusNode: myFocusNodes[index],
                                enableInteractiveSelection: true,
                                enabled: _isEditingText[index],
                                autofocus: true,
                                onEditingComplete: () {
                                  myFocusNodes[index].unfocus();
                                  setState(() {
                                    _isEditingText[index] = false;
                                  });
                                  tmpIndex = -1;
                                },
                                // room.name,
                                // style: TextStyle(
                                //   color: _page == index
                                //       ? Theme.of(context).primaryColor
                                //       : Theme.of(context).textTheme.headline6.color,
                                // ),
                              ),
                              trailing: Wrap(
                                // spacing: 12,
                                children: [
                                  IconButton(
                                    icon: Icon(Icons.edit),
                                    onPressed: () {
                                      setState(() {
                                        _isEditingText[index] = true;
                                        if (tmpIndex != -1 &&
                                            tmpIndex != index) {
                                          _isEditingText[tmpIndex] = false;
                                          // myFocusNodes[index].unfocus();
                                        }
                                      });
                                      tmpIndex = index;
                                      myFocusNodes[index].requestFocus();
                                    },
                                  ),
                                  IconButton(
                                    icon: Icon(Icons.delete),
                                    onPressed: () {
                                      print("delete button pressed");
                                    },
                                  )
                                ],
                              ),

                              //            trailing: FittedBox(
                              //   fit: BoxFit.fill,
                              //   child: Row(
                              //   children: <Widget>[
                              //     Icon(Icons.flight),
                              //     Icon(Icons.flight_land),
                              //   ],
                              //   ),
                              // ),

                              onTap: () {
                                if (tmpIndex > -1) {
                                  myFocusNodes[tmpIndex].unfocus();
                                  setState(() {
                                    _isEditingText[tmpIndex] = false;
                                  });
                                  tmpIndex = -1;
                                }
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => RoomPage(room: room),
                                  ),
                                );
                              },
                            );
                          });
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
          floatingActionButton: FloatingActionButton(
            onPressed: () {
              print("button pressed");
            },
            tooltip: 'Add room',
            child: Icon(Icons.add),
          ),
        ));
  }

  List<Widget> _getListRooms(List<Room> rooms) {
    List _listRooms = new List<Widget>();
    int i = 0;
    for (i = 0; i < rooms.length; i++) {
      _listRooms.add(
        RoomPage(room: rooms[i]),
      );
    }
    return _listRooms;
  }
}
