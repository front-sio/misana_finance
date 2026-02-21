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
  Future<MeetingToken> requestMeetingToken({
    required String bookingId,
  });
}
