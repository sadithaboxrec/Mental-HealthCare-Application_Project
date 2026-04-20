import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/models/app_user.dart';
import '../../../core/models/appointment.dart';
import '../../../core/controllers/doctor_controller.dart';
import 'patient_detail.dart';
import 'patient_analytics.dart';

const _kBlue = Color(0xFF5BB8F5);
const _kBorder = Color(0xFFDAEEFB);
const _kLightBlue = Color(0xFFEAF5FD);

class DoctorPatients extends StatefulWidget {
  final AppUser user;
  const DoctorPatients({super.key, required this.user});

  @override
  State<DoctorPatients> createState() => _DoctorPatientsState();
}

class _DoctorPatientsState extends State<DoctorPatients> {
  List<Map<String, dynamic>> _allPatients = [];
  List<Map<String, dynamic>> _filteredPatients = [];

  Map<String, String> _moodEmojis = {};
  Map<String, int> _sessionCounts = {};
  Map<String, String> _durations = {};

  bool _loading = true;
  String _selectedFilter = 'All';

  @override
  void initState() {
    super.initState();
    _loadPatients();
  }

  Future<void> _loadPatients() async {
    setState(() => _loading = true);
    try {
      final patients = await DoctorController.getAllPatients(widget.user.uid);

      final Map<String, String> emojis = {};
      final Map<String, int> sessions = {};
      final Map<String, String> durations = {};

      for (final p in patients) {
        final uid = p['uid'] as String? ?? '';
        if (uid.isEmpty) continue;

        emojis[uid] = await _getLatestMoodEmoji(uid);
        sessions[uid] = await _getCompletedSessionCount(uid);
        durations[uid] = _calculateDuration(p['createdAt']);
      }

      if (mounted) {
        setState(() {
          _allPatients = patients;
          _moodEmojis = emojis;
          _sessionCounts = sessions;
          _durations = durations;
          _loading = false;
          _applyFilter();
        });
      }
    } catch (e) {
      debugPrint('Patients load error: $e');
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<String> _getLatestMoodEmoji(String patientUid) async {
    try {
      final snap = await FirebaseFirestore.instance
          .collection('daily_logs')
          .where('patientUid', isEqualTo: patientUid)
          .orderBy('date', descending: true)
          .limit(1)
          .get();

      if (snap.docs.isEmpty) return '😐';
      final mood = snap.docs.first.data()['mood'] as int? ?? 3;
      return _getMoodEmoji(mood);
    } catch (_) {
      return '😐';
    }
  }

  String _getMoodEmoji(int mood) {
    switch (mood) {
      case 1:
        return "😢";
      case 2:
        return "🙁";
      case 3:
        return "😐";
      case 4:
        return "🙂";
      case 5:
        return "😊";
      default:
        return "😐";
    }
  }

  Future<int> _getCompletedSessionCount(String patientUid) async {
    try {
      final snap = await FirebaseFirestore.instance
          .collection('appointments')
          .where('patientUid', isEqualTo: patientUid)
          .where('status', isEqualTo: 'completed')
          .get();
      return snap.docs.length;
    } catch (_) {
      return 0;
    }
  }

  String _calculateDuration(dynamic createdAt) {
    if (createdAt == null) return "New";
    try {
      DateTime joinDate = createdAt is Timestamp
          ? createdAt.toDate()
          : DateTime.parse(createdAt.toString());

      final days = DateTime.now().difference(joinDate).inDays;
      if (days < 7) return "$days days";
      if (days < 30) return "${days ~/ 7} weeks";
      final months = days ~/ 30;
      if (months < 12) return "$months mo";
      final years = months ~/ 12;
      return "$years yr${years > 1 ? 's' : ''}";
    } catch (_) {
      return "Unknown";
    }
  }

  void _applyFilter() {
    setState(() {
      if (_selectedFilter == 'All') {
        _filteredPatients = List.from(_allPatients);
      } else if (_selectedFilter == 'Emergency') {
        _filteredPatients = _allPatients
            .where((p) => p['isEmergency'] == true || p['emergency'] == true)
            .toList();
      } else {
        _filteredPatients = List.from(_allPatients);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text('My Patients'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadPatients),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Search patients...',
                      filled: true,
                      fillColor: Colors.grey.shade200,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 14,
                      ),
                    ),
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      _buildFilterButton('All'),
                      const SizedBox(width: 8),
                      _buildFilterButton('Today'),
                      const SizedBox(width: 8),
                      _buildFilterButton('Emergency'),
                    ],
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  child: Text(
                    'Showing ${_filteredPatients.length} Patients',
                    style: const TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                ),

                const Divider(height: 1),

                Expanded(
                  child: _filteredPatients.isEmpty
                      ? const Center(
                          child: Text(
                            'No patients found',
                            style: TextStyle(color: Colors.grey),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _filteredPatients.length,
                          itemBuilder: (context, index) {
                            final p = _filteredPatients[index];
                            final uid = p['uid'] as String? ?? '';
                            final isEmergency =
                                p['isEmergency'] == true ||
                                p['emergency'] == true;
                            return _buildPatientCard(p, uid, isEmergency);
                          },
                        ),
                ),
              ],
            ),
    );
  }

  Widget _buildFilterButton(String label) {
    final isSelected = _selectedFilter == label;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedFilter = label;
            _applyFilter();
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected
                ? _kBlue.withValues(alpha: 0.15)
                : Colors.grey.shade200,
            borderRadius: BorderRadius.circular(30),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? _kBlue : Colors.grey.shade700,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPatientCard(
    Map<String, dynamic> p,
    String uid,
    bool isEmergency,
  ) {
    final name = p['name'] as String? ?? 'Unknown Patient';
    final moodEmoji = _moodEmojis[uid] ?? '😐';
    final sessions = _sessionCounts[uid] ?? 0;
    final duration = _durations[uid] ?? "New";

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: _kLightBlue,
                  radius: 28,
                  child: Text(
                    name.isNotEmpty ? name[0].toUpperCase() : '?',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: _kBlue,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Joined $duration',
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                if (isEmergency)
                  const Icon(Icons.warning_amber_rounded, color: Colors.red),
              ],
            ),

            const SizedBox(height: 16),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStat(moodEmoji, 'Mood'),
                _buildStat(sessions.toString(), 'Sessions'),
                _buildStat(duration, 'Duration'),
              ],
            ),

            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => PatientAnalytics(
                            doctorUser: widget.user,
                            patientUid: uid,
                            patientName: name,
                          ),
                        ),
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.grey),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text('Analytics'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => PatientDetail(
                            doctorUser: widget.user,
                            patientUid: uid,
                            patientName: name,
                          ),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _kBlue,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text('Prescribe'),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.chat_bubble_outline, size: 18),
                    label: const Text('Chat'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _kLightBlue,
                      foregroundColor: _kBlue,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: () {},
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.phone, size: 18),
                    label: const Text('Call'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: () {},
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStat(String value, String label) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontSize: 24)),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }
}
