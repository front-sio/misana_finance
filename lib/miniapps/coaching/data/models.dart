class CoachProfile {
  final String id;
  final String name;
  final String? headline;
  final String? bio;
  final String? avatarUrl;
  final List<Topic> topics;

  CoachProfile({
    required this.id,
    required this.name,
    required this.topics,
    this.headline,
    this.bio,
    this.avatarUrl,
  });

  factory CoachProfile.fromJson(Map<String, dynamic> json) {
    return CoachProfile(
      id: json['id'] as String,
      name: json['name'] as String,
      headline: json['headline'] as String?,
      bio: json['bio'] as String?,
      avatarUrl: json['avatarUrl'] as String?,
      topics: (json['topics'] as List? ?? [])
          .map((t) => Topic.fromJson(Map<String, dynamic>.from(t as Map)))
          .toList(),
    );
  }
}

class Topic {
  final String id;
  final String title;
  final String? description;
  final double price15;
  final double price30;
  final String currency;

  Topic({
    required this.id,
    required this.title,
    required this.price15,
    required this.price30,
    required this.currency,
    this.description,
  });

  factory Topic.fromJson(Map<String, dynamic> json) {
    return Topic(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      price15: _toDouble(json['price15']),
      price30: _toDouble(json['price30']),
      currency: (json['currency'] as String?) ?? 'TZS',
    );
  }
}

class AvailabilitySlot {
  final String id;
  final DateTime startAt;
  final DateTime endAt;
  final bool isBooked;

  AvailabilitySlot({
    required this.id,
    required this.startAt,
    required this.endAt,
    required this.isBooked,
  });

  factory AvailabilitySlot.fromJson(Map<String, dynamic> json) {
    return AvailabilitySlot(
      id: json['id'] as String,
      startAt: DateTime.parse(json['startAt'] as String),
      endAt: DateTime.parse(json['endAt'] as String),
      isBooked: json['isBooked'] as bool? ?? false,
    );
  }
}

class Booking {
  final String id;
  final String status;
  final int durationMinutes;
  final double amount;
  final DateTime startAt;
  final DateTime endAt;
  final String topicTitle;
  final PaymentInfo? payment;

  Booking({
    required this.id,
    required this.status,
    required this.durationMinutes,
    required this.amount,
    required this.startAt,
    required this.endAt,
    required this.topicTitle,
    this.payment,
  });

  factory Booking.fromJson(Map<String, dynamic> json) {
    final slot = json['slot'] as Map? ?? {};
    final topic = json['topic'] as Map? ?? {};
    return Booking(
      id: json['id'] as String,
      status: json['status'] as String,
      durationMinutes: (json['durationMinutes'] as num?)?.toInt() ?? 0,
      amount: _toDouble(json['amount']),
      startAt: DateTime.parse(slot['startAt'] as String),
      endAt: DateTime.parse(slot['endAt'] as String),
      topicTitle: (topic['title'] as String?) ?? 'Session',
      payment: json['payment'] == null
          ? null
          : PaymentInfo.fromJson(Map<String, dynamic>.from(json['payment'] as Map)),
    );
  }
}

class PaymentInfo {
  final String status;
  final String provider;
  final String orderReference;
  final String transactionId;

  PaymentInfo({
    required this.status,
    required this.provider,
    required this.orderReference,
    required this.transactionId,
  });

  factory PaymentInfo.fromJson(Map<String, dynamic> json) {
    return PaymentInfo(
      status: (json['status'] as String?) ?? 'PENDING',
      provider: (json['provider'] as String?) ?? 'CLICKPESA',
      orderReference: (json['orderReference'] as String?) ?? '',
      transactionId: (json['transactionId'] as String?) ?? '',
    );
  }
}

class MeetingToken {
  final String appId;
  final String channelName;
  final int uid;
  final String token;
  final int expiresIn;
  final String mode;

  MeetingToken({
    required this.appId,
    required this.channelName,
    required this.uid,
    required this.token,
    required this.expiresIn,
    required this.mode,
  });

  factory MeetingToken.fromJson(Map<String, dynamic> json) {
    return MeetingToken(
      appId: json['appId'] as String,
      channelName: json['channelName'] as String,
      uid: (json['uid'] as num).toInt(),
      token: json['token'] as String,
      expiresIn: (json['expiresIn'] as num).toInt(),
      mode: (json['mode'] as String?) ?? 'AUDIO',
    );
  }
}

double _toDouble(dynamic v) {
  if (v == null) return 0.0;
  if (v is num) return v.toDouble();
  return double.tryParse(v.toString()) ?? 0.0;
}
