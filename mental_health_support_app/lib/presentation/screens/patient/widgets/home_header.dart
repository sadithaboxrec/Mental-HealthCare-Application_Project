import 'package:flutter/material.dart';
import '../../../../core/controllers/auth_controller.dart';
import '../../../../core/navigation/navigation_helper.dart';

class HomeHeader extends StatelessWidget {
  final String userName;
  final Color primaryBlue;
  final Color primaryBlueDeep;

  const HomeHeader({
    super.key,
    required this.userName,
    required this.primaryBlue,
    required this.primaryBlueDeep,
  });

  @override
  Widget build(BuildContext context) {
    const dark = Color(0xFF1A2744);
    const subtle = Color(0xFF6B7280);

    return Padding(
      padding: const EdgeInsets.only(top: 4, bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.fromLTRB(4, 14, 14, 14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.white,
                    Color.lerp(Colors.white, const Color(0xFFFFFBF7), 0.85)!,
                  ],
                ),
                border: Border.all(color: const Color(0xFFE8E5E0)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                  BoxShadow(
                    color: primaryBlueDeep.withOpacity(0.08),
                    blurRadius: 24,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 5,
                    height: 52,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(5),
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [primaryBlue, primaryBlueDeep],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: primaryBlueDeep.withOpacity(0.45),
                          blurRadius: 8,
                          offset: const Offset(2, 0),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.waving_hand_rounded,
                              size: 22,
                              color: Color.lerp(
                                primaryBlueDeep,
                                const Color(0xFFFFB74D),
                                0.35,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Welcome back',
                              style: TextStyle(
                                color: subtle,
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                                letterSpacing: 0.4,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Hi, $userName',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: dark,
                            fontWeight: FontWeight.w900,
                            fontSize: 24,
                            height: 1.15,
                            letterSpacing: -0.6,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "Here's your care snapshot for today",
                          style: TextStyle(
                            color: primaryBlueDeep.withOpacity(0.88),
                            fontWeight: FontWeight.w600,
                            fontSize: 13.5,
                            height: 1.25,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 10),
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => AuthController.logout().then(
                (_) => NavigationHelper.goToLogin(context),
              ),
              borderRadius: BorderRadius.circular(16),
              child: Ink(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color: Colors.white,
                  border: Border.all(
                    color: primaryBlueDeep.withOpacity(0.22),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.logout_rounded,
                  color: primaryBlueDeep,
                  size: 24,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
