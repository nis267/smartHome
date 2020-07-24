class User {
  int id;
  int roomId;
  String socketId;
  String username;
  User({this.id, this.roomId, this.username, this.socketId});

  // User.map(dynamic obj) {
  //   this._id = obj["id"];
  //   this._roomId = obj["room_id"];
  //   this._socketId = obj["socket_id"];
  //   this._username = obj["username"];
  // }

  // int get uid => id;
  // int get roomId => _roomId;
  // String get socketId => _socketId;
  // String get username => _username;

  factory User.fromJson(Map<String, dynamic> json) {

    return User(
      id: json['id'] as int,
      roomId: json['room_id'] as int,
      username: json['name'] as String,
      socketId: json['socket_id'] as String,
    );
  }

  // Map<String, dynamic> toMap() {
  //   var map = new Map<String, dynamic>();
    
  //   map["uid"] = _id;
  //   map["room_id"] = _roomId;
  //   map["username"] = _username;
  //   map["socket_id"] = _socketId;

  //   return map;
  // }
}