class Device {
  final int id;
  int roomId;
  final String socketId;
  String name;
  final String macAddress;
  int state;
  bool isChecked;
  Device({this.id, this.roomId, this.name, this.socketId, this.macAddress, this.state, this.isChecked = false});

  factory Device.fromJson(Map<String, dynamic> json) {

    return Device(
      id: json['id'] as int,
      roomId: json['room_id'] as int,
      name: json['name'] as String,
      socketId: json['socket_id'] as String,
      macAddress: json['mac_address'] as String,
      state: json['state'] as int,
      isChecked: false,
    );
  }
}