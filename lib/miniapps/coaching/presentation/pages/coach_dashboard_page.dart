import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../coaching_routes.dart';
import '../../data/models.dart';
import '../../domain/coaching_repository.dart';

class CoachDashboardPage extends StatefulWidget {
  const CoachDashboardPage({super.key});

  @override
  State<CoachDashboardPage> createState() => _CoachDashboardPageState();
}

class _CoachDashboardPageState extends State<CoachDashboardPage> {
  bool _loading = true;
  bool _submitting = false;
  bool _topicsLoading = true;
  bool _topicsSubmitting = false;
  String? _error;
  List<CoachBooking> _bookings = const [];
  List<Topic> _topics = const [];
  DateTime _selectedDate = DateTime.now();
  DateTime _filterFrom = DateTime.now();
  DateTime _filterTo = DateTime.now().add(const Duration(days: 30));
  String _statusFilter = 'ALL';
  TimeOfDay _startTime = const TimeOfDay(hour: 9, minute: 0);
  TimeOfDay _endTime = const TimeOfDay(hour: 10, minute: 0);
  final TextEditingController _reasonController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadBookings();
    _loadTopics();
  }

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  CoachingRepository get _repo => context.read<CoachingRepository>();

  String _ymd(DateTime d) => DateFormat('yyyy-MM-dd').format(d);

  Future<void> _loadBookings() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final rows = await _repo.listCoachBookings(
        dateFrom: _ymd(_filterFrom),
        dateTo: _ymd(_filterTo),
        status: _statusFilter == 'ALL' ? null : _statusFilter,
      );
      if (!mounted) return;
      setState(() {
        _bookings = rows;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  Future<void> _loadTopics() async {
    setState(() {
      _topicsLoading = true;
    });
    try {
      final rows = await _repo.listCoachTopics();
      if (!mounted) return;
      setState(() {
        _topics = rows;
      });
    } catch (_) {
      if (!mounted) return;
      // Keep existing list when refresh fails.
    } finally {
      if (mounted) {
        setState(() {
          _topicsLoading = false;
        });
      }
    }
  }

  DateTime _combine(DateTime date, TimeOfDay tod) {
    return DateTime(date.year, date.month, date.day, tod.hour, tod.minute);
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked == null) return;
    setState(() {
      _selectedDate = picked;
    });
    await _loadBookings();
  }

  Future<void> _pickFilterFrom() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _filterFrom,
      firstDate: DateTime.now().subtract(const Duration(days: 90)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked == null) return;
    setState(() {
      _filterFrom = picked;
      if (_filterTo.isBefore(_filterFrom)) {
        _filterTo = _filterFrom;
      }
    });
    await _loadBookings();
  }

  Future<void> _pickFilterTo() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _filterTo,
      firstDate: _filterFrom,
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked == null) return;
    setState(() {
      _filterTo = picked;
    });
    await _loadBookings();
  }

  Future<void> _pickStartTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _startTime,
    );
    if (picked == null) return;
    setState(() => _startTime = picked);
  }

  Future<void> _pickEndTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _endTime,
    );
    if (picked == null) return;
    setState(() => _endTime = picked);
  }

  Future<void> _blockTime() async {
    final start = _combine(_selectedDate, _startTime);
    final end = _combine(_selectedDate, _endTime);
    if (!end.isAfter(start)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('End time lazima iwe baada ya start time'),
        ),
      );
      return;
    }

    setState(() => _submitting = true);
    try {
      final result = await _repo.blockCoachTime(
        startAt: start,
        endAt: end,
        reason: _reasonController.text.trim(),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${result.message}. Slots zilizofungwa: ${result.blockedSlots}, tayari booked: ${result.alreadyBookedSlots}',
          ),
        ),
      );
      await _loadBookings();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed: $e')));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _showTopicDialog({Topic? initial}) async {
    final isEdit = initial != null;
    final formKey = GlobalKey<FormState>();
    final titleCtrl = TextEditingController(text: initial?.title ?? '');
    final descCtrl = TextEditingController(text: initial?.description ?? '');
    final price15Ctrl = TextEditingController(
      text: initial != null ? initial.price15.toStringAsFixed(0) : '',
    );
    final price30Ctrl = TextEditingController(
      text: initial != null ? initial.price30.toStringAsFixed(0) : '',
    );
    bool isActive = initial?.isActive ?? true;

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setLocal) => AlertDialog(
            title: Text(isEdit ? 'Edit Topic' : 'New Topic'),
            content: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: titleCtrl,
                      decoration: const InputDecoration(labelText: 'Title'),
                      validator: (v) =>
                          (v == null || v.trim().length < 3) ? 'Min 3 chars' : null,
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: descCtrl,
                      minLines: 2,
                      maxLines: 4,
                      decoration: const InputDecoration(
                        labelText: 'Description',
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: price15Ctrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Price 15 min'),
                      validator: (v) =>
                          (double.tryParse((v ?? '').trim()) ?? 0) <= 0 ? 'Invalid price' : null,
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: price30Ctrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Price 30 min'),
                      validator: (v) =>
                          (double.tryParse((v ?? '').trim()) ?? 0) <= 0 ? 'Invalid price' : null,
                    ),
                    const SizedBox(height: 8),
                    SwitchListTile(
                      value: isActive,
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Active'),
                      onChanged: (v) => setLocal(() => isActive = v),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () async {
                  if (!formKey.currentState!.validate()) return;
                  Navigator.of(ctx).pop(true);
                },
                child: Text(isEdit ? 'Save' : 'Create'),
              ),
            ],
          ),
        );
      },
    );

    if (result != true) return;
    if (!mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _topicsSubmitting = true);
    try {
      if (isEdit) {
        await _repo.updateCoachTopic(
          id: initial.id,
          title: titleCtrl.text.trim(),
          description: descCtrl.text.trim(),
          price15: double.parse(price15Ctrl.text.trim()),
          price30: double.parse(price30Ctrl.text.trim()),
          isActive: isActive,
        );
      } else {
        await _repo.createCoachTopic(
          title: titleCtrl.text.trim(),
          description: descCtrl.text.trim(),
          price15: double.parse(price15Ctrl.text.trim()),
          price30: double.parse(price30Ctrl.text.trim()),
          isActive: isActive,
        );
      }
      if (!mounted) return;
      await _loadTopics();
      messenger.showSnackBar(
        SnackBar(content: Text(isEdit ? 'Topic updated' : 'Topic created')),
      );
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(SnackBar(content: Text('Topic action failed: $e')));
    } finally {
      if (mounted) setState(() => _topicsSubmitting = false);
    }
  }

  Future<void> _deleteTopic(Topic topic) async {
    final ok =
        await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Delete Topic'),
            content: Text('Delete "${topic.title}"?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(ctx).pop(true),
                child: const Text('Delete'),
              ),
            ],
          ),
        ) ??
        false;
    if (!ok) return;
    if (!mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _topicsSubmitting = true);
    try {
      await _repo.deleteCoachTopic(topic.id);
      if (!mounted) return;
      await _loadTopics();
      messenger.showSnackBar(const SnackBar(content: Text('Topic deleted')));
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(SnackBar(content: Text('Delete failed: $e')));
    } finally {
      if (mounted) setState(() => _topicsSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final timeFmt = DateFormat('HH:mm');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Coach Dashboard'),
        actions: [
          IconButton(
            onPressed: _loading ? null : _loadBookings,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Block Activity Time',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      OutlinedButton.icon(
                        onPressed: _pickDate,
                        icon: const Icon(Icons.calendar_today),
                        label: Text(
                          DateFormat('EEE, MMM d').format(_selectedDate),
                        ),
                      ),
                      OutlinedButton(
                        onPressed: _pickStartTime,
                        child: Text('Start ${_startTime.format(context)}'),
                      ),
                      OutlinedButton(
                        onPressed: _pickEndTime,
                        child: Text('End ${_endTime.format(context)}'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _reasonController,
                    decoration: const InputDecoration(
                      labelText: 'Reason (optional)',
                      hintText: 'Office meeting, travel, etc.',
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _submitting ? null : _blockTime,
                      icon: const Icon(Icons.block),
                      label: Text(
                        _submitting ? 'Saving...' : 'Block this time',
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Topics',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                      IconButton(
                        tooltip: 'Refresh topics',
                        onPressed: _topicsLoading ? null : _loadTopics,
                        icon: const Icon(Icons.refresh),
                      ),
                      FilledButton.icon(
                        onPressed: _topicsSubmitting
                            ? null
                            : () => _showTopicDialog(),
                        icon: const Icon(Icons.add),
                        label: const Text('New'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (_topicsLoading)
                    const Padding(
                      padding: EdgeInsets.all(12),
                      child: CircularProgressIndicator(),
                    )
                  else if (_topics.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(8),
                      child: Text('No topics yet.'),
                    )
                  else
                    ..._topics.map(
                      (t) => Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        decoration: BoxDecoration(
                          border: Border.all(color: scheme.outlineVariant),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ListTile(
                          title: Text(t.title),
                          subtitle: Text(
                            '${t.price15.toStringAsFixed(0)} / 15m • ${t.price30.toStringAsFixed(0)} / 30m • ${t.isActive ? "Active" : "Inactive"}',
                          ),
                          trailing: Wrap(
                            spacing: 4,
                            children: [
                              IconButton(
                                tooltip: 'Edit',
                                onPressed: _topicsSubmitting
                                    ? null
                                    : () => _showTopicDialog(initial: t),
                                icon: const Icon(Icons.edit_outlined),
                              ),
                              IconButton(
                                tooltip: 'Delete',
                                onPressed: _topicsSubmitting
                                    ? null
                                    : () => _deleteTopic(t),
                                icon: const Icon(Icons.delete_outline),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Booking Filters',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      OutlinedButton.icon(
                        onPressed: _pickFilterFrom,
                        icon: const Icon(Icons.date_range),
                        label: Text(
                          'From ${DateFormat('MMM d').format(_filterFrom)}',
                        ),
                      ),
                      OutlinedButton.icon(
                        onPressed: _pickFilterTo,
                        icon: const Icon(Icons.event),
                        label: Text(
                          'To ${DateFormat('MMM d').format(_filterTo)}',
                        ),
                      ),
                      DropdownButton<String>(
                        value: _statusFilter,
                        items: const [
                          DropdownMenuItem(
                            value: 'ALL',
                            child: Text('All status'),
                          ),
                          DropdownMenuItem(value: 'PAID', child: Text('PAID')),
                          DropdownMenuItem(
                            value: 'PENDING_PAYMENT',
                            child: Text('PENDING_PAYMENT'),
                          ),
                          DropdownMenuItem(
                            value: 'PAYMENT_FAILED',
                            child: Text('PAYMENT_FAILED'),
                          ),
                          DropdownMenuItem(
                            value: 'CANCELLED',
                            child: Text('CANCELLED'),
                          ),
                          DropdownMenuItem(
                            value: 'COMPLETED',
                            child: Text('COMPLETED'),
                          ),
                        ],
                        onChanged: (value) async {
                          if (value == null) return;
                          setState(() => _statusFilter = value);
                          await _loadBookings();
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Text(
                'Coach Session Schedule (${DateFormat('MMM d').format(_filterFrom)} - ${DateFormat('MMM d').format(_filterTo)})',
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (_loading)
            const Center(child: CircularProgressIndicator())
          else if (_error != null)
            Text(_error!, style: TextStyle(color: scheme.error))
          else if (_bookings.isEmpty)
            const Text('Hakuna bookings kwa tarehe hii.')
          else
            ..._bookings.map(
              (b) => Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: scheme.outlineVariant),
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
                              color: (b.status == 'PAID' ||
                                      b.status == 'COMPLETED')
                                  ? Colors.green.withValues(alpha: 0.12)
                                  : scheme.primary.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              b.status,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: (b.status == 'PAID' ||
                                        b.status == 'COMPLETED')
                                    ? Colors.green.shade700
                                    : scheme.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${timeFmt.format(b.startAt)} - ${timeFmt.format(b.endAt)}',
                        style: TextStyle(color: scheme.onSurfaceVariant),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'User: ${b.userId.substring(0, 8)}...  •  ${b.amount.toStringAsFixed(0)} TZS',
                        style: TextStyle(color: scheme.onSurfaceVariant),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size(0, 40),
                            ),
                            onPressed: () {
                              Navigator.of(context).pushNamed(
                                CoachingRoutes.booking,
                                arguments: b.id,
                              );
                            },
                            child: const Text('View details'),
                          ),
                          if (b.status == 'PAID' || b.status == 'COMPLETED')
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                minimumSize: const Size(0, 40),
                              ),
                              onPressed: () {
                                Navigator.of(context).pushNamed(
                                  CoachingRoutes.call,
                                  arguments: {
                                    'bookingId': b.id,
                                    'asCoach': true,
                                  },
                                );
                              },
                              child: const Text('Join as coach'),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
