class User {
  final String id;
  final String name;
  final String? email;
  final String? phone;
  final String? username;

  User({required this.id, required this.name, this.email, this.phone, this.username});

  factory User.fromJson(Map<String, dynamic> json) => User(
        id: json['id'],
        name: json['name'],
        email: json['email'],
        phone: json['phone'],
        username: json['username'],
      );
}
