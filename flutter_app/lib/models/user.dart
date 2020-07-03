class User {
  String _id;
  String _roomId;
  String _socketId;
  String _username;
  User(this._id, this._roomId, this._username, this._socketId);

  User.map(dynamic obj) {
    this._id = obj["id"];
    this._roomId = obj["room_id"];
    this._socketId = obj["socket_id"];
    this._username = obj["username"];
  }

  String get uid => _id;
  String get roomId => _roomId;
  String get socketId => _socketId;
  String get username => _username;

  Map<String, dynamic> toMap() {
    var map = new Map<String, dynamic>();
    
    map["uid"] = _id;
    map["room_id"] = _roomId;
    map["username"] = _username;
    map["socket_id"] = _socketId;

    return map;
  }
}