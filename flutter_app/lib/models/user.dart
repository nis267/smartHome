class User {
  int id;
  int roomId;
  String socketId;
  String username;
  int passwordChanged;
  int emailEntered;
  String email;
  User({this.id, this.roomId, this.username, this.socketId, this.passwordChanged, this.emailEntered, this.email});

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
      passwordChanged: json['password_changed'] as int,
      emailEntered: json['email_entered'] as int,
      email: json['email'] as String
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