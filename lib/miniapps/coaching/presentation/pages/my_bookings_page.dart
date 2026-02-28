import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../coaching_routes.dart';
import '../../data/models.dart';
import '../../domain/coaching_repository.dart';

class MyBookingsPage extends StatefulWidget {
  const MyBookingsPage({super.key});

  @override
  State<MyBookingsPage> createState() => _MyBookingsPageState();
}

class _MyBookingsPageState extends State<MyBookingsPage> {
  bool _loading = true;
  String? _error;
  List<UserBooking> _items = const [];
  String? _focusBookingId;
  bool _argsHandled = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_argsHandled) return;
    _argsHandled = true;
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is Map) {
      final id = args['focusBookingId'];
      if (id is String && id.isNotEmpty) {
        _focusBookingId = id;
      }
    }
  }

  CoachingRepository get _repo => context.read<CoachingRepository>();

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final rows = await _repo.listMyBookings();
      if (!mounted) return;
      setState(() => _items = rows);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final fmt = DateFormat('EEE, MMM d • HH:mm');
    final now = DateTime.now();
    final upcoming = _items.where((b) => b.endAt.isAfter(now)).toList()
      ..sort((a, b) => a.startAt.compareTo(b.startAt));
    final past = _items.where((b) => !b.endAt.isAfter(now)).toList()
      ..sort((a, b) => b.startAt.compareTo(a.startAt));

    Widget buildCard(UserBooking b) {
      final slot =
          '${fmt.format(b.startAt)} - ${DateFormat('HH:mm').format(b.endAt)}';
      final isJoinable = b.status == 'PAID' || b.status == 'COMPLETED';
      final isFocused = _focusBookingId != null && _focusBookingId == b.id;
      return Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: isFocused ? scheme.primary : scheme.outlineVariant,
            width: isFocused ? 1.4 : 1.0,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      b.topicTitle,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: isJoinable
                          ? Colors.green.withValues(alpha: 0.12)
                          : scheme.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      b.status,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: isJoinable
                            ? Colors.green.shade700
                            : scheme.primary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                slot,
                style: TextStyle(color: scheme.onSurfaceVariant),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  OutlinedButton(
                    onPressed: () {
                      Navigator.of(context).pushNamed(
                        CoachingRoutes.booking,
                        arguments: b.id,
                      );
                    },
                    child: const Text('View details'),
                  ),
                  if (isJoinable)
                    ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pushNamed(
                          CoachingRoutes.call,
                          arguments: b.id,
                        );
                      },
                      child: const Text('Join session'),
                    ),
                ],
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Session Schedule'),
        actions: [
          IconButton(
            onPressed: _loading ? null : _load,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(child: Text(_error!))
          : _items.isEmpty
          ? const Center(child: Text('No bookings yet'))
          : ListView(
              padding: const EdgeInsets.all(12),
              children: [
                Text(
                  'Upcoming Sessions (${upcoming.length})',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                if (upcoming.isEmpty)
                  const Padding(
                    padding: EdgeInsets.only(bottom: 12),
                    child: Text('No upcoming sessions'),
                  )
                else
                  ...upcoming.map(buildCard),
                const SizedBox(height: 10),
                Text(
                  'Past Sessions (${past.length})',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                if (past.isEmpty)
                  const Text('No past sessions')
                else
                  ...past.map(buildCard),
              ],
            ),
    );
  }
}
