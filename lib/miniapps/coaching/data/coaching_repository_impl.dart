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
  Future<MeetingToken> requestMeetingToken({required String bookingId}) {
    return remote.requestMeetingToken(bookingId: bookingId);
  }

  @override
  Future<MeetingToken> requestCoachMeetingToken({required String bookingId}) {
    return remote.requestCoachMeetingToken(bookingId: bookingId);
  }

  @override
  Future<List<UserBooking>> listMyBookings() {
    return remote.listMyBookings();
  }

  @override
  Future<List<CoachBooking>> listCoachBookings({
    String? date,
    String? dateFrom,
    String? dateTo,
    String? status,
  }) {
    return remote.listCoachBookings(
      date: date,
      dateFrom: dateFrom,
      dateTo: dateTo,
      status: status,
    );
  }

  @override
  Future<CoachBlockResult> blockCoachTime({
    required DateTime startAt,
    required DateTime endAt,
    String? reason,
  }) {
    return remote.blockCoachTime(
      startAt: startAt,
      endAt: endAt,
      reason: reason,
    );
  }

  @override
  Future<List<Topic>> listCoachTopics({String? search, bool? active}) {
    return remote.listCoachTopics(search: search, active: active);
  }

  @override
  Future<Topic> createCoachTopic({
    required String title,
    String? description,
    required double price15,
    required double price30,
    String currency = 'TZS',
    bool isActive = true,
  }) {
    return remote.createCoachTopic(
      title: title,
      description: description,
      price15: price15,
      price30: price30,
      currency: currency,
      isActive: isActive,
    );
  }

  @override
  Future<Topic> updateCoachTopic({
    required String id,
    String? title,
    String? description,
    double? price15,
    double? price30,
    String? currency,
    bool? isActive,
  }) {
    return remote.updateCoachTopic(
      id: id,
      title: title,
      description: description,
      price15: price15,
      price30: price30,
      currency: currency,
      isActive: isActive,
    );
  }

  @override
  Future<void> deleteCoachTopic(String id) {
    return remote.deleteCoachTopic(id);
  }
}
