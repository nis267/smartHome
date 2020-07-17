class Room {
  final int id;
  String name;
  Room({this.id, this.name});

  factory Room.fromJson(Map<String, dynamic> json) {

    return Room(
      id: json['id'] as int,
      name: json['name'] as String,
    );
  }

}