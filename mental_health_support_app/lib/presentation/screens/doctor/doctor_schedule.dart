import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/models/app_user.dart';
import '../../../core/models/appointment.dart';
import 'patient_detail.dart';
import 'doctor_analytics.dart';

const _kBlue = Color(0xFF5BB8F5);
const _kLightBlue = Color(0xFFEAF5FD);
const _kBorder = Color(0xFFDAEEFB);
const _kBg = Color(0xFFF2F8FD);
const _kCard = Colors.white;

const _kMonths = [
  'January',
  'February',
  'March',
  'April',
  'May',
  'June',
  'July',
  'August',
  'September',
  'October',
  'November',
  'December',
];

const _kMonthsShort = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
];

const _kWeekdaysFull = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
const _kWeekdaysShort = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];

String _fmtKey(DateTime d) =>
    '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

// ── Reusable Text Widget ──────────────────────────────
class ScheduleText extends StatelessWidget {
  final String text;
  final double fontSize;
  final FontWeight fontWeight;
  final Color? color;
  final TextAlign? textAlign;
  final int? maxLines;

  const ScheduleText(
    this.text, {
    super.key,
    this.fontSize = 14,
    this.fontWeight = FontWeight.normal,
    this.color,
    this.textAlign,
    this.maxLines,
  });

  @override
  Widget build(BuildContext context) => Text(
    text,
    textAlign: textAlign,
    maxLines: maxLines,
    overflow: maxLines != null ? TextOverflow.ellipsis : null,
    style: TextStyle(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color ?? Colors.black87,
    ),
  );
}

// ── Primary Button ────────────────────────────────────
class SchedulePrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;

  const SchedulePrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 40,
    child: ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: _kBlue,
        foregroundColor: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      ),
      child: ScheduleText(
        label,
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: Colors.white,
      ),
    ),
  );
}

// ── Outline Button ────────────────────────────────────
class ScheduleOutlineButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;

  const ScheduleOutlineButton({
    super.key,
    required this.label,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 40,
    child: OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: _kBlue,
        side: const BorderSide(color: _kBlue, width: 1.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      ),
      child: ScheduleText(
        label,
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: _kBlue,
      ),
    ),
  );
}

// ── View Mode Toggle ──────────────────────────────────
class ViewModeToggle extends StatelessWidget {
  final int selected;
  final ValueChanged<int> onChanged;

  const ViewModeToggle({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    const labels = ['Day', 'Week', 'Month'];
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: _kLightBlue,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: List.generate(3, (i) {
          final active = i == selected;
          return Expanded(
            child: GestureDetector(
              onTap: () => onChanged(i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: active ? _kBlue : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: ScheduleText(
                    labels[i],
                    fontSize: 13,
                    fontWeight: active ? FontWeight.bold : FontWeight.w500,
                    color: active ? Colors.white : const Color(0xFF9BB8CC),
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

// ── Day Calendar View ─────────────────────────────────
class DayCalendarView extends StatefulWidget {
  final DateTime selectedDate;
  final Set<String> datesWithDots;
  final ValueChanged<DateTime> onDateSelected;

  const DayCalendarView({
    super.key,
    required this.selectedDate,
    required this.datesWithDots,
    required this.onDateSelected,
  });

  @override
  State<DayCalendarView> createState() => _DayCalendarViewState();
}

class _DayCalendarViewState extends State<DayCalendarView> {
  late final ScrollController _sc;
  static const int _totalDays = 60;
  static const int _centerIndex = 30;
  static const double _itemW = 54;
  late final DateTime _origin;

  @override
  void initState() {
    super.initState();
    _origin = DateTime.now().subtract(const Duration(days: _centerIndex));
    _sc = ScrollController();
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToSelected());
  }

  @override
  void didUpdateWidget(DayCalendarView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedDate != widget.selectedDate) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToSelected());
    }
  }

  void _scrollToSelected() {
    if (!_sc.hasClients) return;
    final diff = widget.selectedDate
        .difference(_origin)
        .inDays
        .clamp(0, _totalDays - 1);
    final screen = MediaQuery.of(context).size.width;
    final offset = (diff * (_itemW + 6)) - (screen / 2) + (_itemW / 2);
    _sc.animateTo(
      offset.clamp(0.0, _sc.position.maxScrollExtent),
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  @override
  void dispose() {
    _sc.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: _kCard,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.blueGrey.withOpacity(0.07),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: ScheduleText(
              '${_kMonths[widget.selectedDate.month - 1]} ${widget.selectedDate.year}',
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 76,
            child: ListView.builder(
              controller: _sc,
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: _totalDays,
              itemBuilder: (_, i) {
                final day = _origin.add(Duration(days: i));
                final isSel = _fmtKey(day) == _fmtKey(widget.selectedDate);
                final hasDot = widget.datesWithDots.contains(_fmtKey(day));
                final wdLbl = _kWeekdaysFull[day.weekday % 7].substring(0, 1);

                return GestureDetector(
                  onTap: () => widget.onDateSelected(day),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: _itemW,
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    decoration: BoxDecoration(
                      color: isSel ? _kBlue : _kLightBlue,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ScheduleText(
                          wdLbl,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: isSel
                              ? Colors.white70
                              : const Color(0xFF9BB8CC),
                        ),
                        const SizedBox(height: 4),
                        ScheduleText(
                          '${day.day}',
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isSel ? Colors.white : Colors.black87,
                        ),
                        const SizedBox(height: 4),
                        Container(
                          width: 5,
                          height: 5,
                          decoration: BoxDecoration(
                            color: hasDot
                                ? (isSel ? Colors.white : _kBlue)
                                : Colors.transparent,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ── Week Calendar View ────────────────────────────────
class WeekCalendarView extends StatelessWidget {
  final DateTime selectedDate;
  final Set<String> datesWithDots;
  final ValueChanged<DateTime> onDateSelected;
  final VoidCallback onPrevWeek;
  final VoidCallback onNextWeek;

  const WeekCalendarView({
    super.key,
    required this.selectedDate,
    required this.datesWithDots,
    required this.onDateSelected,
    required this.onPrevWeek,
    required this.onNextWeek,
  });

  DateTime get _weekStart {
    final wd = selectedDate.weekday;
    return DateTime(
      selectedDate.year,
      selectedDate.month,
      selectedDate.day - (wd - 1),
    );
  }

  @override
  Widget build(BuildContext context) {
    final start = _weekStart;
    final weekDays = List.generate(7, (i) => start.add(Duration(days: i)));

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      decoration: BoxDecoration(
        color: _kCard,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.blueGrey.withOpacity(0.07),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              ScheduleText(
                '${_kMonths[selectedDate.month - 1]} ${selectedDate.year}',
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
              Row(
                children: [
                  _CalNavBtn(icon: Icons.chevron_left, onTap: onPrevWeek),
                  const SizedBox(width: 6),
                  _CalNavBtn(icon: Icons.chevron_right, onTap: onNextWeek),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: weekDays.map((day) {
              final isSel = _fmtKey(day) == _fmtKey(selectedDate);
              final hasDot = datesWithDots.contains(_fmtKey(day));
              final wdLbl = _kWeekdaysShort[day.weekday % 7];

              return GestureDetector(
                onTap: () => onDateSelected(day),
                child: Column(
                  children: [
                    ScheduleText(
                      wdLbl,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey.shade400,
                    ),
                    const SizedBox(height: 6),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: isSel ? _kBlue : Colors.transparent,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: ScheduleText(
                          '${day.day}',
                          fontSize: 14,
                          fontWeight: isSel
                              ? FontWeight.bold
                              : FontWeight.normal,
                          color: isSel ? Colors.white : Colors.black87,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      width: 5,
                      height: 5,
                      decoration: BoxDecoration(
                        color: hasDot ? _kBlue : Colors.transparent,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

// ── Month Calendar View ───────────────────────────────
class MonthCalendarView extends StatelessWidget {
  final DateTime selectedDate;
  final Set<String> datesWithDots;
  final ValueChanged<DateTime> onDateSelected;
  final VoidCallback onPrevMonth;
  final VoidCallback onNextMonth;

  const MonthCalendarView({
    super.key,
    required this.selectedDate,
    required this.datesWithDots,
    required this.onDateSelected,
    required this.onPrevMonth,
    required this.onNextMonth,
  });

  @override
  Widget build(BuildContext context) {
    final firstDay = DateTime(selectedDate.year, selectedDate.month, 1);
    final daysInMonth = DateTime(
      selectedDate.year,
      selectedDate.month + 1,
      0,
    ).day;
    final startOffset = firstDay.weekday % 7;
    final totalCells = startOffset + daysInMonth;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      decoration: BoxDecoration(
        color: _kCard,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.blueGrey.withOpacity(0.07),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              ScheduleText(
                '${_kMonths[selectedDate.month - 1]} ${selectedDate.year}',
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
              Row(
                children: [
                  _CalNavBtn(icon: Icons.chevron_left, onTap: onPrevMonth),
                  const SizedBox(width: 6),
                  _CalNavBtn(icon: Icons.chevron_right, onTap: onNextMonth),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: _kWeekdaysShort
                .map(
                  (d) => SizedBox(
                    width: 34,
                    child: ScheduleText(
                      d,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey.shade400,
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 6),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              childAspectRatio: 1.05,
            ),
            itemCount: totalCells,
            itemBuilder: (_, idx) {
              if (idx < startOffset) return const SizedBox();
              final day = idx - startOffset + 1;
              final date = DateTime(selectedDate.year, selectedDate.month, day);
              final isSel = _fmtKey(date) == _fmtKey(selectedDate);
              final hasDot = datesWithDots.contains(_fmtKey(date));

              return GestureDetector(
                onTap: () => onDateSelected(date),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: isSel ? _kBlue : Colors.transparent,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: ScheduleText(
                          '$day',
                          fontSize: 13,
                          fontWeight: isSel
                              ? FontWeight.bold
                              : FontWeight.normal,
                          color: isSel ? Colors.white : Colors.black87,
                        ),
                      ),
                    ),
                    if (hasDot) ...[
                      const SizedBox(height: 2),
                      Container(
                        width: 5,
                        height: 5,
                        decoration: const BoxDecoration(
                          color: _kBlue,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ],
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

// ── Calendar Nav Button ───────────────────────────────
class _CalNavBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _CalNavBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        color: const Color(0xFFF0F6FB),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(icon, size: 18, color: Colors.grey.shade600),
    ),
  );
}

// ── Appointment Card ──────────────────────────────────
class AppointmentCard extends StatelessWidget {
  final Appointment apt;
  final AppUser doctorUser;

  const AppointmentCard({
    super.key,
    required this.apt,
    required this.doctorUser,
  });

  String get _initials {
    final parts = apt.patientName.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return apt.patientName.isNotEmpty ? apt.patientName[0].toUpperCase() : '?';
  }

  String get _displayTime {
    final raw = apt.time.length >= 5 ? apt.time.substring(0, 5) : apt.time;
    final parts = raw.split(':');
    int hour = int.tryParse(parts[0]) ?? 0;
    final min = parts.length > 1 ? parts[1] : '00';
    final ampm = hour >= 12 ? 'PM' : 'AM';
    if (hour == 0)
      hour = 12;
    else if (hour > 12)
      hour -= 12;
    return '$hour:$min $ampm';
  }

  String get _sessionLabel {
    switch (apt.status) {
      case 'completed':
        return 'Completed Session';
      case 'absent':
        return 'Patient Absent';
      case 'rescheduled':
        return 'Rescheduled Session';
      default:
        return 'Emergency Session';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: _kCard,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _kBorder, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: _kBlue.withOpacity(0.07),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.access_time_outlined, color: _kBlue, size: 15),
                const SizedBox(width: 5),
                ScheduleText(
                  _displayTime,
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: _kBlue,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: _kLightBlue,
                  child: ScheduleText(
                    _initials,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: _kBlue,
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ScheduleText(
                      apt.patientName,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                    const SizedBox(height: 2),
                    ScheduleText(
                      _sessionLabel,
                      fontSize: 12,
                      color: Colors.grey.shade500,
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: SchedulePrimaryButton(
                    label: 'Analytics',
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => PatientAnalytics(
                          doctorUser: doctorUser,
                          patientUid: apt.patientUid,
                          patientName: apt.patientName,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ScheduleOutlineButton(
                    label: 'Prescribe',
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => PatientDetail(
                          doctorUser: doctorUser,
                          patientUid: apt.patientUid,
                          patientName: apt.patientName,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Main Doctor Schedule Screen ───────────────────────
class DoctorSchedule extends StatefulWidget {
  final AppUser user;
  const DoctorSchedule({super.key, required this.user});

  @override
  State<DoctorSchedule> createState() => _DoctorScheduleState();
}

class _DoctorScheduleState extends State<DoctorSchedule> {
  DateTime _selectedDate = DateTime.now();
  List<Appointment> _appointments = [];
  bool _loading = false;
  int _viewMode = 2; // 0=Day, 1=Week, 2=Month
  Set<String> _datesWithApt = {};

  @override
  void initState() {
    super.initState();
    _load();
    _loadDots();
  }

  String _fmt(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final snap = await FirebaseFirestore.instance
          .collection('appointments')
          .where('doctorUid', isEqualTo: widget.user.uid)
          .where('date', isEqualTo: _fmt(_selectedDate))
          .orderBy('time')
          .get();

      if (mounted) {
        setState(() {
          _appointments = snap.docs
              .map((d) => Appointment.fromMap(d.id, d.data()))
              .toList();
          _loading = false;
        });
      }
    } catch (e) {
      debugPrint('Schedule load error: $e');
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _loadDots() async {
    try {
      final from = DateTime.now().subtract(const Duration(days: 30));
      final to = DateTime.now().add(const Duration(days: 90));
      final snap = await FirebaseFirestore.instance
          .collection('appointments')
          .where('doctorUid', isEqualTo: widget.user.uid)
          .where('date', isGreaterThanOrEqualTo: _fmt(from))
          .where('date', isLessThanOrEqualTo: _fmt(to))
          .get();

      if (mounted) {
        setState(() {
          _datesWithApt = snap.docs
              .map((d) => (d.data()['date'] as String?) ?? '')
              .where((s) => s.isNotEmpty)
              .toSet();
        });
      }
    } catch (e) {
      debugPrint('Dots load error: $e');
    }
  }

  void _prevPeriod() {
    setState(() {
      switch (_viewMode) {
        case 0:
          _selectedDate = _selectedDate.subtract(const Duration(days: 1));
          break;
        case 1:
          _selectedDate = _selectedDate.subtract(const Duration(days: 7));
          break;
        case 2:
          _selectedDate = DateTime(
            _selectedDate.year,
            _selectedDate.month - 1,
            1,
          );
          break;
      }
    });
    _load();
  }

  void _nextPeriod() {
    setState(() {
      switch (_viewMode) {
        case 0:
          _selectedDate = _selectedDate.add(const Duration(days: 1));
          break;
        case 1:
          _selectedDate = _selectedDate.add(const Duration(days: 7));
          break;
        case 2:
          _selectedDate = DateTime(
            _selectedDate.year,
            _selectedDate.month + 1,
            1,
          );
          break;
      }
    });
    _load();
  }

  void _onDateSelected(DateTime d) {
    setState(() => _selectedDate = d);
    _load();
  }

  String _headerText() {
    final now = DateTime.now();
    final isToday =
        _selectedDate.day == now.day &&
        _selectedDate.month == now.month &&
        _selectedDate.year == now.year;

    if (isToday)
      return 'Today, ${_kMonthsShort[_selectedDate.month - 1]} ${_selectedDate.day}';
    return '${_kMonthsShort[_selectedDate.month - 1]} ${_selectedDate.day}, ${_selectedDate.year}';
  }

  Widget _buildCalendar() {
    switch (_viewMode) {
      case 0:
        return DayCalendarView(
          key: const ValueKey(0),
          selectedDate: _selectedDate,
          datesWithDots: _datesWithApt,
          onDateSelected: _onDateSelected,
        );
      case 1:
        return WeekCalendarView(
          key: const ValueKey(1),
          selectedDate: _selectedDate,
          datesWithDots: _datesWithApt,
          onDateSelected: _onDateSelected,
          onPrevWeek: _prevPeriod,
          onNextWeek: _nextPeriod,
        );
      default:
        return MonthCalendarView(
          key: const ValueKey(2),
          selectedDate: _selectedDate,
          datesWithDots: _datesWithApt,
          onDateSelected: _onDateSelected,
          onPrevMonth: _prevPeriod,
          onNextMonth: _nextPeriod,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        backgroundColor: _kCard,
        elevation: 0,
        centerTitle: true,
        automaticallyImplyLeading: false,
        leading: Padding(
          padding: const EdgeInsets.all(8),
          child: GestureDetector(
            onTap: () => Navigator.of(
              context,
            ).pushNamedAndRemoveUntil('/home', (route) => false),
            behavior: HitTestBehavior.opaque,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFFF0F6FB),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.chevron_left,
                color: Colors.black87,
                size: 22,
              ),
            ),
          ),
        ),
        title: const ScheduleText(
          'Schedules',
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: ViewModeToggle(
              selected: _viewMode,
              onChanged: (v) {
                setState(() => _viewMode = v);
                _load();
              },
            ),
          ),
          SliverToBoxAdapter(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 280),
              child: _buildCalendar(),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 6),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  ScheduleText(
                    _headerText(),
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  if (!_loading)
                    ScheduleText(
                      '${_appointments.length} Appointment${_appointments.length == 1 ? '' : 's'}',
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: _kBlue,
                    ),
                ],
              ),
            ),
          ),
          if (_loading)
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.only(top: 40),
                child: Center(
                  child: CircularProgressIndicator(
                    color: _kBlue,
                    strokeWidth: 2.5,
                  ),
                ),
              ),
            )
          else if (_appointments.isEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.only(top: 48),
                child: Center(
                  child: Column(
                    children: [
                      Icon(
                        Icons.event_available,
                        size: 52,
                        color: Colors.grey.shade300,
                      ),
                      const SizedBox(height: 10),
                      ScheduleText(
                        'No appointments on this day',
                        color: Colors.grey.shade400,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (ctx, i) => AppointmentCard(
                    apt: _appointments[i],
                    doctorUser: widget.user,
                  ),
                  childCount: _appointments.length,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
