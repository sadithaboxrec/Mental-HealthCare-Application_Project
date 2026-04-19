import 'dart:ui';

import 'package:flutter/material.dart';
import '../../../core/models/app_user.dart';
import '../../../core/models/chat_session.dart';
import '../../../core/controllers/auth_controller.dart';
import '../../../core/controllers/chat_controller.dart';
import '../../../core/navigation/navigation_helper.dart';
// Updated import to the production chat file
import 'counselor_chat.dart';

class CounselorScreen extends StatefulWidget {
  final AppUser user;
  const CounselorScreen({super.key, required this.user});

  @override
  State<CounselorScreen> createState() =>
      _CounselorScreenState();
}

class _CounselorScreenState extends State<CounselorScreen> {

  Future<void> _accept(ChatSession session) async {
    await ChatController.acceptSession(
      sessionId:     session.id,
      counselorUid:  widget.user.uid,
      counselorName: widget.user.name,
    );
    if (mounted) {
      Navigator.push(context, MaterialPageRoute(
        builder: (_) => CounselorChat( // Updated class name
          counselorUser: widget.user,
          session:       session,
        ),
      ));
    }
  }

  static const _pageGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0xFFFAFAFA),
      Color(0xFFF5F5F5),
      Color(0xFFEEEEEE),
    ],
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(
          'Counselor — ${widget.user.name}', // Removed [TEST] tag
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            letterSpacing: 0.15,
            color: Color(0xFF212121),
          ),
        ),
        flexibleSpace: ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.85),
                border: Border(
                  bottom: BorderSide(
                    color: Colors.black.withOpacity(0.06),
                    width: 1,
                  ),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 12,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
            ),
          ),
        ),
        backgroundColor: Colors.transparent,
        foregroundColor: const Color(0xFF212121),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            tooltip: 'Log out',
            onPressed: () async {
              await AuthController.logout();
              if (context.mounted) NavigationHelper.goToLogin(context);
            },
          ),
        ],
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(gradient: _pageGradient),
        child: Column(children: [

          // ── Active session banner ─────────────────────
          StreamBuilder<ChatSession?>(
            stream: ChatController
                .counselorActiveSessionStream(widget.user.uid),
            builder: (ctx, snap) {
              final active = snap.data;
              if (active == null) return const SizedBox.shrink();
              return TweenAnimationBuilder<double>(
                key: ValueKey(active.id),
                tween: Tween(begin: 0, end: 1),
                duration: const Duration(milliseconds: 280),
                curve: Curves.easeOutCubic,
                builder: (context, t, child) {
                  return Opacity(
                    opacity: t,
                    child: Transform.translate(
                      offset: Offset(0, 10 * (1 - t)),
                      child: child,
                    ),
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 4),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(18),
                      onTap: () => Navigator.push(context, MaterialPageRoute(
                        builder: (_) => CounselorChat( // Updated class name
                          counselorUser: widget.user,
                          session:       active,
                        ),
                      )),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(18),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 240),
                            curve: Curves.easeOutCubic,
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.92),
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(
                                color: Colors.black.withOpacity(0.08),
                                width: 1,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 18,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            child: Row(children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.white.withOpacity(0.65),
                                  border: Border.all(
                                    color: Colors.white.withOpacity(0.95),
                                  ),
                                ),
                                child: Icon(
                                  Icons.forum_rounded,
                                  color: Colors.black.withOpacity(0.55),
                                  size: 22,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(child: Text(
                                'Active chat with ${active.patientName}',
                                style: const TextStyle(
                                  color: Color(0xFF212121),
                                  fontWeight: FontWeight.w700,
                                  fontSize: 15,
                                  letterSpacing: 0.1,
                                ),
                              )),
                              Icon(
                                Icons.arrow_forward_ios_rounded,
                                color: Colors.black.withOpacity(0.35),
                                size: 14,
                              ),
                            ]),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),

          // ── Waiting patients ──────────────────────────
          Expanded(
            child: StreamBuilder<List<ChatSession>>(
              stream: ChatController.waitingSessionsStream(),
              builder: (ctx, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 40,
                          height: 40,
                          child: CircularProgressIndicator(
                            strokeWidth: 3,
                            color: Colors.black.withOpacity(0.35),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Loading…',
                          style: TextStyle(
                            color: Colors.black.withOpacity(0.55),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                final sessions = snap.data ?? [];

                if (sessions.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.support_agent_rounded,
                            size: 64,
                            color: Colors.black.withOpacity(0.15),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No patients waiting',
                            style: TextStyle(
                              color: Colors.black.withOpacity(0.78),
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.2,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'You will see patients here in real time',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.black.withOpacity(0.5),
                              fontSize: 14,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return ListView(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
                  children: [
                    Text(
                      '${sessions.length} patient${sessions.length > 1 ? "s" : ""} waiting',
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                        letterSpacing: 0.2,
                        color: Color(0xFF212121),
                      ),
                    ),
                    const SizedBox(height: 14),
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
      ),
    );
  }
}

// ── Waiting patient card remains same but ensured internal consistency ────
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
  bool _hovering = false;

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

    final createdAt = DateTime.tryParse(
        widget.session.createdAt) ?? DateTime.now();
    final waiting   = DateTime.now().difference(createdAt);
    final waitStr   = waiting.inMinutes < 1
        ? 'Just now'
        : '${waiting.inMinutes}m ago';

    return MouseRegion(
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 240),
        curve: Curves.easeOutCubic,
        margin: const EdgeInsets.only(bottom: 14),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 240),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(_hovering ? 0.98 : 0.96),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: Colors.black.withOpacity(0.06),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black
                        .withOpacity(_hovering ? 0.12 : 0.08),
                    blurRadius: _hovering ? 20 : 14,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      CircleAvatar(
                        radius: 24,
                        backgroundColor: const Color(0xFFEEEEEE),
                        child: Text(
                          widget.session.patientName.isNotEmpty
                              ? widget.session.patientName[0].toUpperCase()
                              : '?',
                          style: const TextStyle(
                            color: Color(0xFF212121),
                            fontWeight: FontWeight.w800,
                            fontSize: 18,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(widget.session.patientName,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 16,
                                  letterSpacing: 0.1,
                                  color: Color(0xFF263238))),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(
                                Icons.schedule_rounded,
                                size: 14,
                                color: Color(0xFFE65100),
                              ),
                              const SizedBox(width: 4),
                              Text('Waiting: $waitStr',
                                  style: const TextStyle(
                                      color: Color(0xFFBF360C),
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700)),
                            ],
                          ),
                        ],
                      )),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              const Color(0xFFFFE0B2).withOpacity(0.9),
                              const Color(0xFFFFCC80).withOpacity(0.85),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: const Color(0xFFFFB74D).withOpacity(0.9),
                          ),
                        ),
                        child: Text(
                          'WAITING',
                          style: TextStyle(
                              color: Colors.orange.shade900,
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.6),
                        ),
                      ),
                    ]),

                    const SizedBox(height: 14),
                    Divider(
                      height: 1,
                      color: Colors.black.withOpacity(0.06),
                    ),
                    const SizedBox(height: 10),

                    Row(children: [
                      _info('Gender', gender),
                      const SizedBox(width: 16),
                      _info('DOB', dob),
                      const SizedBox(width: 16),
                      _info('Status', status),
                    ]),

                    const SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        icon:  const Icon(Icons.chat_rounded, size: 18),
                        label: const Text('Accept & Start Chat'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1976D2),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                        ),
                        onPressed: widget.onAccept,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _info(String label, String value) => Expanded(
    child: Column(crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: TextStyle(
                  color: Colors.black.withOpacity(0.45),
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.2)),
          const SizedBox(height: 2),
          Text(value,
              style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  color: Color(0xFF37474F))),
        ]),
  );
}