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
    return CoachProfile.fromJson({
      ...coach,
      'topics': topics,
    });
  }

  Future<List<AvailabilitySlot>> getSlots(String date) async {
    final Response res = await client.get(
      '/coaching/slots',
      params: {'date': date},
    );
    final data = res.data as Map<String, dynamic>;
    final slots = (data['slots'] as List? ?? [])
        .map((s) => AvailabilitySlot.fromJson(Map<String, dynamic>.from(s as Map)))
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
      'status': data['status'] ?? 'pending',
      'provider': 'CLICKPESA',
      'orderReference': data['reference'] ?? data['orderReference'] ?? '',
      'transactionId': data['transactionId'] ?? '',
    });
  }

  Future<MeetingToken> requestMeetingToken({
    required String bookingId,
  }) async {
    final Response res = await client.post(
      '/coaching/meetings/token',
      data: {'bookingId': bookingId},
    );
    return MeetingToken.fromJson(Map<String, dynamic>.from(res.data as Map));
  }
}
