import '../domain/coaching_repository.dart';
import 'coaching_remote_data_source.dart';
import 'models.dart';

class CoachingRepositoryImpl implements CoachingRepository {
  final CoachingRemoteDataSource remote;
  CoachingRepositoryImpl(this.remote);

  @override
  Future<CoachProfile> getCoachProfile() => remote.getCoachProfile();

  @override
  Future<List<AvailabilitySlot>> getSlots(String date) => remote.getSlots(date);

  @override
  Future<Booking> createBooking({
    required String topicId,
    required String slotId,
    required int durationMinutes,
  }) {
    return remote.createBooking(
      topicId: topicId,
      slotId: slotId,
      durationMinutes: durationMinutes,
    );
  }

  @override
  Future<Booking> getBooking(String id) => remote.getBooking(id);

  @override
  Future<PaymentInfo> initPayment({
    required String bookingId,
    required String phoneNumber,
  }) {
    return remote.initPayment(bookingId: bookingId, phoneNumber: phoneNumber);
  }

  @override
  Future<MeetingToken> requestMeetingToken({
    required String bookingId,
  }) {
    return remote.requestMeetingToken(bookingId: bookingId);
  }
}
