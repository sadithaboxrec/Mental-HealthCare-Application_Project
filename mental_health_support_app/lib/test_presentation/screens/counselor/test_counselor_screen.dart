import 'package:flutter/material.dart';
import '../../../core/models/app_user.dart';
import '../../../core/models/chat_session.dart';
import '../../../core/controllers/auth_controller.dart';
import '../../../core/controllers/chat_controller.dart';
import '../../../core/navigation/navigation_helper.dart';
import 'test_counselor_chat.dart';

class TestCounselorScreen extends StatefulWidget {
  final AppUser user;
  const TestCounselorScreen({super.key, required this.user});

  @override
  State<TestCounselorScreen> createState() =>
      _TestCounselorScreenState();
}

class _TestCounselorScreenState extends State<TestCounselorScreen> {

  Future<void> _accept(ChatSession session) async {
    await ChatController.acceptSession(
      sessionId:     session.id,
      counselorUid:  widget.user.uid,
      counselorName: widget.user.name,
    );
    if (mounted) {
      Navigator.push(context, MaterialPageRoute(
        builder: (_) => TestCounselorChat(
          counselorUser: widget.user,
          session:       session,
        ),
      ));
    }
  }




  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: Text('[TEST] Counselor — ${widget.user.name}'),
        backgroundColor: Colors.purple,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await AuthController.logout();
              if (context.mounted) NavigationHelper.goToLogin(context);
            },
          ),
        ],
      ),
      body: Column(children: [

        // ── Active session banner ─────────────────────
        StreamBuilder<ChatSession?>(
          stream: ChatController
              .counselorActiveSessionStream(widget.user.uid),
          builder: (ctx, snap) {
            final active = snap.data;
            if (active == null) return const SizedBox.shrink();
            return GestureDetector(
              onTap: () => Navigator.push(context, MaterialPageRoute(
                builder: (_) => TestCounselorChat(
                  counselorUser: widget.user,
                  session:       active,
                ),
              )),
              child: Container(
                width:   double.infinity,
                padding: const EdgeInsets.all(12),
                color:   Colors.purple,
                child: Row(children: [
                  const Icon(Icons.chat,
                      color: Colors.white, size: 18),
                  const SizedBox(width: 8),
                  Expanded(child: Text(
                    'Active chat with ${active.patientName}',
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold),
                  )),
                  const Icon(Icons.arrow_forward_ios,
                      color: Colors.white70, size: 14),
                ]),
              ),
            );
          },
        ),

        // ── Waiting patients ──────────────────────────
        Expanded(
          child: StreamBuilder<List<ChatSession>>(
            stream: ChatController.waitingSessionsStream(),
            builder: (ctx, snap) {

              // debugPrint('Waiting sessions: ${snap.data?.length} — state: ${snap.connectionState}');
              debugPrint('=== COUNSELOR STREAM ===');
              debugPrint('State: ${snap.connectionState}');
              debugPrint('Error: ${snap.error}');
              debugPrint('Sessions count: ${snap.data?.length}');


              if (snap.connectionState == ConnectionState.waiting) {
                return const Center(
                    child: CircularProgressIndicator());
              }

              final sessions = snap.data ?? [];

              if (sessions.isEmpty) {
                return const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.support_agent,
                          size: 60, color: Colors.grey),
                      SizedBox(height: 12),
                      Text('No patients waiting',
                          style: TextStyle(
                              color: Colors.grey, fontSize: 16)),
                      SizedBox(height: 4),
                      Text('You will see patients here in real time',
                          style: TextStyle(
                              color: Colors.grey, fontSize: 12)),
                    ],
                  ),
                );
              }

              return ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Text(
                    '${sessions.length} patient${sessions.length > 1 ? "s" : ""} waiting',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.purple),
                  ),
                  const SizedBox(height: 12),
                  ...sessions.map((s) =>
                      _WaitingPatientCard(
                        session:  s,
                        onAccept: () => _accept(s),
                      )),
                ],
              );
            },
          ),
        ),
      ]),
    );
  }
}


// ── Waiting patient card ──────────────────────────────────
class _WaitingPatientCard extends StatefulWidget {
  final ChatSession  session;
  final VoidCallback onAccept;
  const _WaitingPatientCard({
    required this.session, required this.onAccept});

  @override
  State<_WaitingPatientCard> createState() =>
      _WaitingPatientCardState();
}

class _WaitingPatientCardState extends State<_WaitingPatientCard> {
  Map<String, dynamic>? _patientDetails;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final details = await ChatController
        .getPatientDetails(widget.session.patientUid);
    if (mounted) setState(() => _patientDetails = details);
  }

  @override
  Widget build(BuildContext context) {
    final gender = _patientDetails?['gender'] ?? '—';
    final dob    = _patientDetails?['dob']    ?? '—';
    final status = _patientDetails?['employeeStatus'] ?? '—';

    // How long waiting
    final createdAt = DateTime.tryParse(
        widget.session.createdAt) ?? DateTime.now();
    final waiting   = DateTime.now().difference(createdAt);
    final waitStr   = waiting.inMinutes < 1
        ? 'Just now'
        : '${waiting.inMinutes}m ago';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              CircleAvatar(
                backgroundColor: Colors.purple.shade100,
                child: Text(
                  widget.session.patientName.isNotEmpty
                      ? widget.session.patientName[0].toUpperCase()
                      : '?',
                  style: TextStyle(
                      color:      Colors.purple.shade700,
                      fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.session.patientName,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15)),
                  Text('Waiting: $waitStr',
                      style: const TextStyle(
                          color: Colors.orange,
                          fontSize: 12,
                          fontWeight: FontWeight.w500)),
                ],
              )),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color:        Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Colors.orange),
                ),
                child: const Text('WAITING',
                    style: TextStyle(
                        color:      Colors.orange,
                        fontSize:   10,
                        fontWeight: FontWeight.bold)),
              ),
            ]),

            const SizedBox(height: 10),
            const Divider(),
            const SizedBox(height: 6),

            // Basic patient info
            Row(children: [
              _info('Gender', gender),
              const SizedBox(width: 16),
              _info('DOB', dob),
              const SizedBox(width: 16),
              _info('Status', status),
            ]),

            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon:  const Icon(Icons.chat, size: 16),
                label: const Text('Accept & Start Chat'),
                style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.purple,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8))),
                onPressed: widget.onAccept,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _info(String label, String value) => Expanded(
    child: Column(crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(
                  color: Colors.grey, fontSize: 10)),
          Text(value,
              style: const TextStyle(
                  fontWeight: FontWeight.w500, fontSize: 12)),
        ]),
  );
}