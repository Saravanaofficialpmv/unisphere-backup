import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:unisphere/widgets/common/unisphere_header_card.dart';

class CampusEventModel {
  final String title;
  final String category;
  final String date;
  final String location;
  final String time;
  final String speaker;
  final Color color;

  CampusEventModel({
    required this.title,
    required this.category,
    required this.date,
    required this.location,
    required this.time,
    required this.speaker,
    required this.color,
  });
}

class EventsScreen extends StatefulWidget {
  final VoidCallback? onBack;
  const EventsScreen({super.key, this.onBack});

  @override
  State<EventsScreen> createState() => _EventsScreenState();
}

class _EventsScreenState extends State<EventsScreen> {
  List<CampusEventModel> _events = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadEvents();
  }

  Future<void> _loadEvents() async {
    try {
      final snap = await FirebaseFirestore.instance.collection('events').get();
      if (mounted) {
        setState(() {
          _events = snap.docs.map((doc) {
            final data = doc.data();
            return CampusEventModel(
              title: data['title']?.toString() ?? 'Campus Event',
              category: data['category']?.toString() ?? 'General',
              date: data['date']?.toString() ?? 'TBD',
              location: data['location']?.toString() ?? 'Campus',
              time: data['time']?.toString() ?? 'TBD',
              speaker: data['speaker']?.toString() ?? '',
              color: const Color(0xFF4F46E5),
            );
          }).toList();
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _events = [];
          _isLoading = false;
        });
      }
    }
  }

  void _navigateBackToFeatureHub(BuildContext context) async {
    if (widget.onBack != null) {
      widget.onBack!();
    } else if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    } else {
      context.go('/student');
    }
  }

  @override
  Widget build(BuildContext context) {
    final scaffold = Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Column(
          children: [
            UnisphereHeaderCard(
              title: 'Campus Events & Fests',
              subtitle: 'Technical Workshops, Symposiums & Fests',
              onBack: () => _navigateBackToFeatureHub(context),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Upcoming Events & Workshops', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                    const SizedBox(height: 12),

                    if (_isLoading)
                      const Center(child: Padding(padding: EdgeInsets.all(32), child: CircularProgressIndicator()))
                    else if (_events.isEmpty)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Column(
                          children: [
                            Icon(Icons.event_busy_rounded, size: 48, color: Colors.grey.shade400),
                            const SizedBox(height: 12),
                            const Text('No Upcoming Events', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                            const SizedBox(height: 6),
                            const Text('Campus workshops and symposiums will appear here once announced.', textAlign: TextAlign.center, style: TextStyle(fontSize: 13, color: Color(0xFF64748B))),
                          ],
                        ),
                      )
                    else
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _events.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 14),
                      itemBuilder: (context, index) {
                        final event = _events[index];
                        return Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                            boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)],
                          ),
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(color: event.color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
                                    child: Text(event.category, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: event.color)),
                                  ),
                                  const Spacer(),
                                  const Icon(Icons.calendar_today_rounded, size: 14, color: Color(0xFF64748B)),
                                  const SizedBox(width: 4),
                                  Text(event.date, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF64748B))),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Text(event.title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  const Icon(Icons.person_pin_rounded, size: 14, color: Color(0xFF64748B)),
                                  const SizedBox(width: 4),
                                  Text(event.speaker, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  const Icon(Icons.location_on_rounded, size: 14, color: Color(0xFF64748B)),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      event.location,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  const Icon(Icons.access_time_rounded, size: 14, color: Color(0xFF64748B)),
                                  const SizedBox(width: 4),
                                  Flexible(
                                    child: Text(
                                      event.time,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                                    ),
                                  ),
                                ],
                              ),
                              const Divider(height: 20),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  onPressed: () {},
                                  icon: const Icon(Icons.event_available_rounded, size: 16),
                                  label: const Text('RSVP & Add to Calendar'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: event.color,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );

    final bool canPopRoute = ModalRoute.of(context)?.canPop ?? false;
    return PopScope(
      canPop: canPopRoute,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop || !mounted) return;
        if (widget.onBack != null) {
          widget.onBack!();
        }
      },
      child: scaffold,
    );
  }
}
