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
                  final slots = state.slots;
                  if (slots.isEmpty) {
                    return const Center(
                      child: Text('No slots for this day.'),
                    );
                  }
                  return Column(
                    children: [
                      const _SlotsLegend(),
                      Expanded(
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: slots.length,
                          itemBuilder: (context, index) {
                            final slot = slots[index];
                            final status = _slotStatus(slot);
                            final canBook = status == _SlotStatus.available;
                            return _SlotCard(
                              slot: slot,
                              status: status,
                              onTap: canBook
                                  ? () {
                                      Navigator.of(context).pushNamed(
                                        CoachingRoutes.checkout,
                                        arguments: {
                                          'topic': widget.topic,
                                          'slot': slot,
                                        },
                                      );
                                    }
                                  : null,
                            );
                          },
                        ),
                      ),
                    ],
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

enum _SlotStatus { available, taken, busy }

_SlotStatus _slotStatus(AvailabilitySlot slot) {
  final now = DateTime.now();
  if (slot.isBooked) return _SlotStatus.taken;
  if (slot.endAt.isBefore(now)) return _SlotStatus.busy;
  return _SlotStatus.available;
}

class _SlotCard extends StatelessWidget {
  final AvailabilitySlot slot;
  final _SlotStatus status;
  final VoidCallback? onTap;

  const _SlotCard({
    required this.slot,
    required this.status,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final timeFmt = DateFormat('HH:mm');
    final (label, bgColor, borderColor, textColor) = switch (status) {
      _SlotStatus.available => (
        'Available',
        Colors.green.withValues(alpha: 0.10),
        Colors.green.withValues(alpha: 0.45),
        Colors.green.shade800,
      ),
      _SlotStatus.taken => (
        'Taken',
        Colors.red.withValues(alpha: 0.10),
        Colors.red.withValues(alpha: 0.45),
        Colors.red.shade800,
      ),
      _SlotStatus.busy => (
        'Busy',
        Colors.orange.withValues(alpha: 0.12),
        Colors.orange.withValues(alpha: 0.50),
        Colors.orange.shade900,
      ),
    };

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor),
      ),
      child: ListTile(
        title: Text(
          '${timeFmt.format(slot.startAt)} - ${timeFmt.format(slot.endAt)}',
        ),
        subtitle: Text(
          label,
          style: TextStyle(color: textColor, fontWeight: FontWeight.w600),
        ),
        trailing: Icon(
          onTap == null ? Icons.block : Icons.chevron_right,
          color: textColor,
        ),
        onTap: onTap,
      ),
    );
  }
}

class _SlotsLegend extends StatelessWidget {
  const _SlotsLegend();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: const [
          _LegendChip(
            label: 'Available',
            color: Color(0xFF2E7D32),
            background: Color(0x1A2E7D32),
          ),
          _LegendChip(
            label: 'Taken',
            color: Color(0xFFC62828),
            background: Color(0x1AC62828),
          ),
          _LegendChip(
            label: 'Busy',
            color: Color(0xFFEF6C00),
            background: Color(0x1AEF6C00),
          ),
        ],
      ),
    );
  }
}

class _LegendChip extends StatelessWidget {
  final String label;
  final Color color;
  final Color background;

  const _LegendChip({
    required this.label,
    required this.color,
    required this.background,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: background,
        border: Border.all(color: color.withValues(alpha: 0.6)),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
      ),
    );
  }
}
