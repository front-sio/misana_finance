import '../data/models.dart';

abstract class CoachingRepository {
  Future<CoachProfile> getCoachProfile();
  Future<List<AvailabilitySlot>> getSlots(String date);
  Future<Booking> createBooking({
    required String topicId,
    required String slotId,
    required int durationMinutes,
  });
  Future<Booking> getBooking(String id);
  Future<PaymentInfo> initPayment({
    required String bookingId,
    required String phoneNumber,
  });
  Future<MeetingToken> requestMeetingToken({required String bookingId});
  Future<MeetingToken> requestCoachMeetingToken({required String bookingId});
  Future<List<UserBooking>> listMyBookings();
  Future<List<CoachBooking>> listCoachBookings({
    String? date,
    String? dateFrom,
    String? dateTo,
    String? status,
  });
  Future<CoachBlockResult> blockCoachTime({
    required DateTime startAt,
    required DateTime endAt,
    String? reason,
  });
  Future<List<Topic>> listCoachTopics({String? search, bool? active});
  Future<Topic> createCoachTopic({
    required String title,
    String? description,
    required double price15,
    required double price30,
    String currency,
    bool isActive,
  });
  Future<Topic> updateCoachTopic({
    required String id,
    String? title,
    String? description,
    double? price15,
    double? price30,
    String? currency,
    bool? isActive,
  });
  Future<void> deleteCoachTopic(String id);
}
