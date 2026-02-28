import 'package:dio/dio.dart';
import 'package:misana_finance_app/core/network/api_client.dart';

import 'models.dart';

class CoachingRemoteDataSource {
  final ApiClient client;
  CoachingRemoteDataSource(this.client);

  Future<CoachProfile> getCoachProfile() async {
    final Response res = await client.get('/coaching/coach');
    final data = res.data as Map<String, dynamic>;
    final coach = Map<String, dynamic>.from(data['coach'] as Map);
    final topics = (data['topics'] as List? ?? [])
        .map((t) => Map<String, dynamic>.from(t as Map))
        .toList();
    return CoachProfile.fromJson({...coach, 'topics': topics});
  }

  Future<List<AvailabilitySlot>> getSlots(String date) async {
    final Response res = await client.get(
      '/coaching/slots',
      params: {'date': date},
    );
    final data = res.data as Map<String, dynamic>;
    final slots = (data['slots'] as List? ?? [])
        .map(
          (s) => AvailabilitySlot.fromJson(Map<String, dynamic>.from(s as Map)),
        )
        .toList();
    return slots;
  }

  Future<Booking> createBooking({
    required String topicId,
    required String slotId,
    required int durationMinutes,
  }) async {
    final Response res = await client.post(
      '/coaching/bookings',
      data: {
        'topicId': topicId,
        'slotId': slotId,
        'durationMinutes': durationMinutes,
      },
    );
    final data = res.data as Map<String, dynamic>;
    return Booking.fromJson(Map<String, dynamic>.from(data['booking'] as Map));
  }

  Future<Booking> getBooking(String id) async {
    final Response res = await client.get('/coaching/bookings/$id');
    final data = res.data as Map<String, dynamic>;
    return Booking.fromJson(Map<String, dynamic>.from(data['booking'] as Map));
  }

  Future<PaymentInfo> initPayment({
    required String bookingId,
    required String phoneNumber,
  }) async {
    final Response res = await client.post(
      '/coaching/bookings/$bookingId/pay',
      data: {'phoneNumber': phoneNumber},
    );
    final data = Map<String, dynamic>.from(res.data as Map);
    return PaymentInfo.fromJson({
      'status': data['status'] ?? 'PAID',
      'provider': 'CLICKPESA',
      'orderReference': data['reference'] ?? data['orderReference'] ?? '',
      'transactionId': data['transactionId'] ?? '',
    });
  }

  Future<MeetingToken> requestMeetingToken({required String bookingId}) async {
    final Response res = await client.post(
      '/coaching/meetings/token',
      data: {'bookingId': bookingId},
    );
    return MeetingToken.fromJson(Map<String, dynamic>.from(res.data as Map));
  }

  Future<MeetingToken> requestCoachMeetingToken({
    required String bookingId,
  }) async {
    final Response res = await client.post(
      '/coaching/coach/meetings/token',
      data: {'bookingId': bookingId},
    );
    return MeetingToken.fromJson(Map<String, dynamic>.from(res.data as Map));
  }

  Future<List<UserBooking>> listMyBookings() async {
    final Response res = await client.get('/coaching/bookings');
    final data = Map<String, dynamic>.from(res.data as Map);
    final rows = (data['bookings'] as List? ?? [])
        .map((b) => UserBooking.fromJson(Map<String, dynamic>.from(b as Map)))
        .toList();
    return rows;
  }

  Future<List<CoachBooking>> listCoachBookings({
    String? date,
    String? dateFrom,
    String? dateTo,
    String? status,
  }) async {
    final params = <String, dynamic>{
      if (date != null && date.trim().isNotEmpty) 'date': date.trim(),
      if (dateFrom != null && dateFrom.trim().isNotEmpty)
        'dateFrom': dateFrom.trim(),
      if (dateTo != null && dateTo.trim().isNotEmpty) 'dateTo': dateTo.trim(),
      if (status != null && status.trim().isNotEmpty) 'status': status.trim(),
    };
    final Response res = await client.get(
      '/coaching/coach/bookings',
      params: params.isEmpty ? null : params,
    );
    final data = Map<String, dynamic>.from(res.data as Map);
    final rows = (data['bookings'] as List? ?? [])
        .map((b) => CoachBooking.fromJson(Map<String, dynamic>.from(b as Map)))
        .toList();
    return rows;
  }

  Future<CoachBlockResult> blockCoachTime({
    required DateTime startAt,
    required DateTime endAt,
    String? reason,
  }) async {
    final Response res = await client.post(
      '/coaching/coach/blocks',
      data: {
        'startAt': startAt.toUtc().toIso8601String(),
        'endAt': endAt.toUtc().toIso8601String(),
        if (reason != null && reason.trim().isNotEmpty) 'reason': reason.trim(),
      },
    );
    return CoachBlockResult.fromJson(
      Map<String, dynamic>.from(res.data as Map),
    );
  }

  Future<List<Topic>> listCoachTopics({String? search, bool? active}) async {
    final params = <String, dynamic>{
      if (search != null && search.trim().isNotEmpty) 'search': search.trim(),
      if (active != null) 'active': active.toString(),
    };
    final Response res = await client.get(
      '/coaching/coach/topics',
      params: params.isEmpty ? null : params,
    );
    final data = Map<String, dynamic>.from(res.data as Map);
    final rows = (data['topics'] as List? ?? [])
        .map((t) => Topic.fromJson(Map<String, dynamic>.from(t as Map)))
        .toList();
    return rows;
  }

  Future<Topic> createCoachTopic({
    required String title,
    String? description,
    required double price15,
    required double price30,
    String currency = 'TZS',
    bool isActive = true,
  }) async {
    final Response res = await client.post(
      '/coaching/coach/topics',
      data: {
        'title': title,
        'description': description,
        'price15': price15,
        'price30': price30,
        'currency': currency,
        'isActive': isActive,
      },
    );
    final data = Map<String, dynamic>.from(res.data as Map);
    return Topic.fromJson(Map<String, dynamic>.from(data['topic'] as Map));
  }

  Future<Topic> updateCoachTopic({
    required String id,
    String? title,
    String? description,
    double? price15,
    double? price30,
    String? currency,
    bool? isActive,
  }) async {
    final payload = <String, dynamic>{
      if (title != null) 'title': title,
      if (description != null) 'description': description,
      if (price15 != null) 'price15': price15,
      if (price30 != null) 'price30': price30,
      if (currency != null) 'currency': currency,
      if (isActive != null) 'isActive': isActive,
    };
    final Response res = await client.patch(
      '/coaching/coach/topics/$id',
      data: payload,
    );
    final data = Map<String, dynamic>.from(res.data as Map);
    return Topic.fromJson(Map<String, dynamic>.from(data['topic'] as Map));
  }

  Future<void> deleteCoachTopic(String id) async {
    await client.delete('/coaching/coach/topics/$id');
  }
}
