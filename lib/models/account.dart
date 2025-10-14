class Account {
  final String id;
  final String phone;
  final int balance;
  final bool isMain;

  Account({required this.id, required this.phone, required this.balance, required this.isMain});

  factory Account.fromJson(Map<String, dynamic> json) => Account(
        id: json['id'],
        phone: json['phone'],
        balance: json['balance'],
        isMain: json['isMain'],
      );
}
