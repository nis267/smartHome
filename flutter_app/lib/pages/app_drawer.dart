import 'package:flutter_app/Routes/routes.dart';
import 'package:flutter_app/models/drawer_data.dart';
import 'package:flutter_app/models/room.dart';
import 'package:flutter_app/pages/home_rooms.dart';
import 'package:flutter_app/pages/page_1.dart';
import 'package:flutter_app/pages/page_2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_app/pages/settingsPage.dart';
import 'package:flutter_app/services/authentication.dart';
import 'package:flutter_app/services/socket.dart';
import 'package:flutter_simple_dependency_injection/injector.dart';

class AppDrawer extends StatefulWidget {
  AppDrawer(
      {Key key, this.auth, this.userId, this.userName, this.logoutCallback, this.currentRoute})
      : super(key: key);

  final BaseAuth auth;
  final VoidCallback logoutCallback;
  final String userId;
  final String userName;
  final String currentRoute;

  @override
  _AppDrawerState createState() => _AppDrawerState();
}

class _AppDrawerState extends State<AppDrawer> {
  GlobalKey<ScaffoldState> _key = new GlobalKey<ScaffoldState>();

  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  // List<Room> drawerItems = [];

  // @override
  // void initState() {
  // print("userName: " + widget.userName);

  //   // socketService = injector.get<SocketService>();
  //   // // drawerItems =
  //   // print("userId: ");
  //   // print(widget.userId);
  //   // socketService.getRoomModelData().then((value) => {
  //   //       setState(() {
  //   //         drawerItems = value;
  //   //         print(drawerItems);
  //   //       })
  //   //     });
  //   // _pageController = PageController(initialPage: 0);
  //   super.initState();
  // }

  // @override
  // void dispose() {
  //   // _pageController.dispose();
  //   super.dispose();
  // }

  // _handleDrawer() {
  //   _key.currentState.openDrawer();

  //   setState(() {
  //     ///DO MY API CALLS
  //     // _counter++;
  //   });
  // }

  signOut() async {
    try {
      await widget.auth.signOut();
      widget.logoutCallback();
    } catch (e) {
      print(e);
    }
  }

  Widget _createDrawerItem(
      {IconData icon, String text, GestureTapCallback onTap}) {
    return ListTile(
      title: Row(
        children: <Widget>[
          Icon(icon),
          Padding(
            padding: EdgeInsets.only(left: 8.0),
            child: Text(text),
          )
        ],
      ),
      onTap: onTap,
    );
  }

  @override
  Widget build(BuildContext context) {
    print("username app drawer: ");
    print(widget.userName);
    // return Scaffold(
    //   key: _key,
    //   appBar: AppBar(
    //     title: Text("SmartHome"),
    // leading: new IconButton(
    //     icon: new Icon(Icons.menu), onPressed: _handleDrawer),
    // actions: <Widget>[
    //   new FlatButton(
    //       child: new Text('Logout',
    //           style: new TextStyle(fontSize: 17.0, color: Colors.white)),
    //       onPressed: signOut)
    // ],
    // ),
    // drawer:
    return Drawer(
      child: ListView(
        children: <Widget>[
          UserAccountsDrawerHeader(
            accountName: Text(widget.userName),
            accountEmail: Text(""),
          ),
          _createDrawerItem(
              icon: Icons.home,
              text: 'Home',
              onTap: () {
                doRoute(
                    context,
                    'Home',
                    HomeRoomsPage(
                        auth: widget.auth,
                        userId: widget.userId,
                        userName: widget.userName,
                        logoutCallback: widget.logoutCallback));
              }
              // onTap: () => doRoute(context, Routes.homeRooms, DrawerData(widget.auth, widget.userId, widget.userName, widget.logoutCallback)),

              ),
          _createDrawerItem(
              icon: Icons.settings,
              text: 'Settings',
              onTap: () {
                doRoute(
                    context,
                    'Settings',
                    SettingsPage(
                        auth: widget.auth,
                        userId: widget.userId,
                        userName: widget.userName,
                        logoutCallback: widget.logoutCallback));
              }
              ),
          new Divider(),
          _createDrawerItem(
              icon: Icons.power_settings_new,
              text: 'Logout',
              onTap: () => signOut()),

          //   FutureBuilder(
          //     future: socketService.getRoomModelData(),
          //     builder: (context, snapshot) {
          //       if (snapshot.hasError)
          //       return Text(snapshot.error);
          //     if (snapshot.hasData) {
          //       drawerItems = snapshot.data;
          //       return ListView.builder(
          //     physics: NeverScrollableScrollPhysics(),
          //     shrinkWrap: true,
          //     itemCount: snapshot.data.length,
          //     itemBuilder: (BuildContext context, int index) {
          //       Room item = snapshot.data[index];
          //       return ListTile(
          //         title: Text(
          //           item.name,
          //           style: TextStyle(
          //             color: _page == index
          //                 ?Theme.of(context).primaryColor
          //                 :Theme.of(context).textTheme.title.color,
          //           ),
          //         ),
          //         onTap: (){
          //           _pageController.jumpToPage(index);
          //           Navigator.pop(context);
          //         },
          //       );
          //     },

          //   );
          //     }
          //   return Center(child: CircularProgressIndicator());
          //     }
          //  ),
        ],
      ),
    );

    //   body: PageView(
    //     physics: NeverScrollableScrollPhysics(),
    //     controller: _pageController,
    //     onPageChanged: onPageChanged,
    //     children: _getListRooms(drawerItems)
    //   ),
    // );
  }

  void doRoute(BuildContext context, String name, dynamic function) {

    if (widget.currentRoute != name) {
      Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => function));
    }
    else {
      Navigator.pop(context);
    }
  }

  // void navigationTapped(int page) {
  //   _pageController.jumpToPage(page);
  // }

  // void onPageChanged(int page) {
  //   setState(() {
  //     _page = page;
  //   });
  // }
}
