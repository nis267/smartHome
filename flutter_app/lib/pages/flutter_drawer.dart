import 'package:flutter_app/models/room.dart';
import 'package:flutter_app/pages/page_1.dart';
import 'package:flutter_app/pages/page_2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_app/services/authentication.dart';
import 'package:flutter_app/services/socket.dart';
import 'package:flutter_simple_dependency_injection/injector.dart';

class Home extends StatefulWidget {
  Home({Key key, this.auth, this.userId, this.logoutCallback})
    : super(key: key);

  final BaseAuth auth;
  final VoidCallback logoutCallback;
  final String userId;

  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  final injector = Injector.getInjector();
  PageController _pageController;
  SocketService socketService;
  int _page = 0;
  GlobalKey<ScaffoldState> _key = new GlobalKey<ScaffoldState>();

  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  List<Room> drawerItems = [];

  @override
  void initState() {
    socketService = injector.get<SocketService>();
    // drawerItems = 
    socketService.getRoomModelData().then((value) => {
          setState(() {
            drawerItems = value;
            print(drawerItems);
          })
        });
    _pageController = PageController(initialPage: 0);
    super.initState();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  _handleDrawer(){
      _key.currentState.openDrawer();

           setState(() {
          ///DO MY API CALLS
          // _counter++;
        });

  }

signOut() async {
    try {
      await widget.auth.signOut();
      widget.logoutCallback();
    } catch (e) {
      print(e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _key,
      appBar: AppBar(
        
        title: Text("SmartHome"),
         leading: new IconButton(icon: new Icon(
          Icons.menu
        ),onPressed:_handleDrawer),
        actions: <Widget>[
            new FlatButton(
                child: new Text('Logout',
                    style: new TextStyle(fontSize: 17.0, color: Colors.white)),
                onPressed: signOut)
          ],
          
        ),
      drawer: Drawer(
        child: ListView(
          children: <Widget>[
            DrawerHeader(
              child: Text(
                "DRAWER HEADER..",
                style: TextStyle(
                  color: Colors.white
                ),
              ),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor,
              ),
            ),

            FutureBuilder(
              future: socketService.getRoomModelData(),
              builder: (context, snapshot) {
                if (snapshot.hasError)
                return Text(snapshot.error);
              if (snapshot.hasData) {
                drawerItems = snapshot.data;
                return ListView.builder(
              physics: NeverScrollableScrollPhysics(),
              shrinkWrap: true,
              itemCount: snapshot.data.length,
              itemBuilder: (BuildContext context, int index) {
                Room item = snapshot.data[index];
                return ListTile(
                  title: Text(
                    item.name,
                    style: TextStyle(
                      color: _page == index
                          ?Theme.of(context).primaryColor
                          :Theme.of(context).textTheme.title.color,
                    ),
                  ),
                  onTap: (){
                    _pageController.jumpToPage(index);
                    Navigator.pop(context);
                  },
                );
              },

            );
              }
            return Center(child: CircularProgressIndicator());
              }
           ),
          ],
        ),
      ),

      body: PageView(
        physics: NeverScrollableScrollPhysics(),
        controller: _pageController,
        onPageChanged: onPageChanged,
        children: _getListRooms(drawerItems)
      ),
    );
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

  void navigationTapped(int page) {
    _pageController.jumpToPage(page);
  }

  void onPageChanged(int page) {
    setState(() {
      _page = page;
    });
  }
}