class Device {
  String  _id;
  String  _roomId;
  String  _socketId;
  String  _name;
  String  _macAddress;
  String    _state;
  Device(this._id, this._roomId, this._name, this._socketId, this._macAddress, this._state);

  Device.map(dynamic obj) {
    print("obj: ");
    print(obj);
    this._id = obj["id"].toString();
    print("id");
    print(this._id);
    this._roomId = obj["room_id"];
    print("_roomId");
    print(this._roomId);
    this._socketId = obj["socket_id"];
    print("_socketId");
    print(this._socketId);
    this._name = obj["name"];
     print("_name");
    print(this._name);
    this._macAddress = obj["mac_address"];
    print("_macAddress");
    print(this._macAddress);
    this._state = obj["state"].toString();
    print("_state");
    print(this._state);

    
        
        
       
        
        
  }

  String get uid => _id;
  String get roomId => _roomId;
  String get socketId => _socketId;
  String get name => _name;
  String get macAddress => _macAddress;
  String get state => _state;

  Map<String, dynamic> toMap() {
    var map = new Map<String, dynamic>();
    
    map["id"] = _id;
    map["room_id"] = _roomId;
    map["name"] = _name;
    map["socket_id"] = _socketId;
    map["mac_address"] = _macAddress;
    map["state"] = _state;
    return map;
  }
}