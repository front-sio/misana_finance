import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../coaching_routes.dart';
import '../../data/models.dart';
import '../bloc/slots_bloc.dart';
import '../bloc/slots_event.dart';
import '../bloc/slots_state.dart';

class PickSlotPage extends StatefulWidget {
  final Topic topic;

  const PickSlotPage({super.key, required this.topic});

  @override
  State<PickSlotPage> createState() => _PickSlotPageState();
}

class _PickSlotPageState extends State<PickSlotPage> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  @override
  void initState() {
    super.initState();
    _selectedDay = DateTime.now();
    _loadSlotsForDay(_selectedDay!);
  }

  void _loadSlotsForDay(DateTime day) {
    final dateStr = DateFormat('yyyy-MM-dd').format(day);
    context.read<SlotsBloc>().add(LoadSlots(dateStr));
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Pick a slot')),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
            decoration: BoxDecoration(
              color: scheme.surfaceContainerHighest,
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(18),
              ),
              border: Border(bottom: BorderSide(color: scheme.outlineVariant)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Choose a day',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                TableCalendar(
                  firstDay: DateTime.now().subtract(const Duration(days: 0)),
                  lastDay: DateTime.now().add(const Duration(days: 30)),
                  focusedDay: _focusedDay,
                  calendarFormat: CalendarFormat.week,
                  selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                  onDaySelected: (selectedDay, focusedDay) {
                    setState(() {
                      _selectedDay = selectedDay;
                      _focusedDay = focusedDay;
                    });
                    _loadSlotsForDay(selectedDay);
                  },
                  headerVisible: false,
                  calendarStyle: CalendarStyle(
                    todayDecoration: BoxDecoration(
                      color: scheme.primary.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    selectedDecoration: BoxDecoration(
                      color: scheme.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: BlocBuilder<SlotsBloc, SlotsState>(
              builder: (context, state) {
                if (state is SlotsLoading) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (state is SlotsFailure) {
                  return Center(child: Text(state.message));
                }
                if (state is SlotsLoaded) {
                  final now = DateTime.now();
                  final slots = state.slots
                      .where((s) => !s.isBooked && s.endAt.isAfter(now))
                      .toList();
                  if (slots.isEmpty) {
                    return const Center(
                      child: Text('No available slots for this day.'),
                    );
                  }
                  return ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: slots.length,
                    itemBuilder: (context, index) {
                      final slot = slots[index];
                      return _SlotCard(
                        slot: slot,
                        onTap: () {
                          Navigator.of(context).pushNamed(
                            CoachingRoutes.checkout,
                            arguments: {'topic': widget.topic, 'slot': slot},
                          );
                        },
                      );
                    },
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _SlotCard extends StatelessWidget {
  final AvailabilitySlot slot;
  final VoidCallback onTap;

  const _SlotCard({required this.slot, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final timeFmt = DateFormat('HH:mm');
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: ListTile(
        title: Text(
          '${timeFmt.format(slot.startAt)} - ${timeFmt.format(slot.endAt)}',
        ),
        subtitle: Text(
          'Available',
          style: TextStyle(color: scheme.onSurfaceVariant),
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
