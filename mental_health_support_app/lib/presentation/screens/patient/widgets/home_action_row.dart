import 'package:flutter/material.dart';

class HomeActionRow extends StatelessWidget {
  final VoidCallback onDiaryTap;
  final VoidCallback onSupportTap;
  final Color primaryBlue;
  final Color primaryBlueDeep;

  const HomeActionRow({
    super.key,
    required this.onDiaryTap,
    required this.onSupportTap,

    /// Defaults to the same light blue used on the patient home screen.
    this.primaryBlue = const Color(0xFF8EC5F5),
    required this.primaryBlueDeep,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _actionBtn(
            "Diary",
            Icons.auto_stories_rounded,
            primaryBlueDeep,
            primaryBlue,
            onDiaryTap,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: _actionBtn(
            "Want to talk someone?",
            Icons.forum_rounded,
            const Color(0xFF5BB4E0),
            const Color(0xFF9FD8F0),
            onSupportTap,
          ),
        ),
      ],
    );
  }

  Widget _actionBtn(
    String title,
    IconData icon,
    Color gradientEnd,
    Color gradientStart,
    VoidCallback tap,
  ) {
    final r = BorderRadius.circular(24);
    return Material(
      color: Colors.transparent,
      elevation: 0,
      child: InkWell(
        onTap: tap,
        borderRadius: r,
        splashColor: Colors.white.withOpacity(0.28),
        highlightColor: Colors.white.withOpacity(0.14),
        child: Ink(
          height: 112,
          decoration: BoxDecoration(
            borderRadius: r,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                gradientStart,
                Color.lerp(gradientStart, gradientEnd, 0.55)!,
                gradientEnd,
              ],
              stops: const [0.0, 0.45, 1.0],
            ),
            border: Border.all(color: Colors.white.withOpacity(0.55), width: 2),
            boxShadow: [
              BoxShadow(
                color: gradientEnd.withOpacity(0.55),
                blurRadius: 22,
                offset: const Offset(0, 12),
                spreadRadius: -2,
              ),
              BoxShadow(
                color: Colors.black.withOpacity(0.12),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: 44,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(r.topLeft.x),
                    ),
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.white.withOpacity(0.35),
                        Colors.white.withOpacity(0),
                      ],
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      icon,
                      color: Colors.white,
                      size: 34,
                      shadows: [
                        Shadow(
                          color: Colors.black.withOpacity(0.22),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      title,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                        height: 1.2,
                        letterSpacing: 0.15,
                        shadows: [
                          Shadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
