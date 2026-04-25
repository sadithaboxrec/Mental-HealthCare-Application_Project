// import 'package:flutter/material.dart';
// import 'dart:ui' show ImageFilter;
// import '../../../../core/controllers/auth_controller.dart';
// import '../../../../core/navigation/navigation_helper.dart';
//
// class HomeHeader extends StatelessWidget {
//   final String userName;
//   // final String userRole;
//   final Color primaryBlue;
//   final Color primaryBlueDeep;
//
//   const HomeHeader({
//     super.key,
//     required this.userName,
//     // required this.userRole,
//     required this.primaryBlue,
//     required this.primaryBlueDeep,
//   });
//
//   @override
//   Widget build(BuildContext context) {
//     return Padding(
//       padding: const EdgeInsets.only(top: 4, bottom: 12),
//       child: ClipRRect(
//         borderRadius: BorderRadius.circular(24),
//         child: Stack(
//           children: [
//             // ── Gradient background ───────────────
//             Positioned.fill(
//               child: Container(
//                 decoration: BoxDecoration(
//                   gradient: LinearGradient(
//                     colors: [
//                       primaryBlue.withOpacity(0.95),
//                       const Color(0xFF56CCF2).withOpacity(0.9),
//                     ],
//                     begin: Alignment.topLeft,
//                     end: Alignment.bottomRight,
//                   ),
//                 ),
//               ),
//             ),
//
//             // ── Glass overlay ─────────────────────
//             BackdropFilter(
//               filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
//               child: Container(
//                 width: double.infinity,
//                 decoration: BoxDecoration(
//                   gradient: LinearGradient(
//                     colors: [
//                       Colors.white.withOpacity(0.22),
//                       Colors.white.withOpacity(0.06),
//                     ],
//                     begin: Alignment.topLeft,
//                     end: Alignment.bottomRight,
//                   ),
//                   border: Border.all(
//                     color: Colors.white.withOpacity(0.35),
//                   ),
//                   boxShadow: [
//                     BoxShadow(
//                       color: Colors.black.withOpacity(0.08),
//                       blurRadius: 24,
//                       offset: const Offset(0, 12),
//                     ),
//                   ],
//                 ),
//                 padding: const EdgeInsets.fromLTRB(22, 22, 16, 22),
//                 child: Row(
//                   children: [
//                     // ── Avatar ────────────────────
//                     Container(
//                       decoration: BoxDecoration(
//                         shape: BoxShape.circle,
//                         boxShadow: [
//                           BoxShadow(
//                             color: Colors.black.withOpacity(0.12),
//                             blurRadius: 12,
//                             offset: const Offset(0, 4),
//                           ),
//                         ],
//                       ),
//                       child: CircleAvatar(
//                         radius: 30,
//                         backgroundColor: Colors.white,
//                         child: Text(
//                           userName.isNotEmpty
//                               ? userName[0].toUpperCase()
//                               : '?',
//                           style: TextStyle(
//                             fontSize: 24,
//                             color: primaryBlue,
//                             fontWeight: FontWeight.bold,
//                             letterSpacing: 0.5,
//                           ),
//                         ),
//                       ),
//                     ),
//
//                     const SizedBox(width: 16),
//
//                     // ── Name + role ───────────────
//                     Expanded(
//                       child: Column(
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         children: [
//                           Row(
//                             children: [
//                               Icon(
//                                 Icons.waving_hand_rounded,
//                                 size: 16,
//                                 color: Colors.white.withOpacity(0.85),
//                               ),
//                               const SizedBox(width: 6),
//                               Text(
//                                 'Welcome back',
//                                 style: TextStyle(
//                                   color: Colors.white.withOpacity(0.85),
//                                   fontWeight: FontWeight.w500,
//                                   fontSize: 12,
//                                   letterSpacing: 0.3,
//                                 ),
//                               ),
//                             ],
//                           ),
//                           const SizedBox(height: 4),
//                           Text(
//                             'Hi, $userName',
//                             maxLines: 1,
//                             overflow: TextOverflow.ellipsis,
//                             style: const TextStyle(
//                               fontSize: 18,
//                               color: Colors.white,
//                               fontWeight: FontWeight.w700,
//                               letterSpacing: 0.2,
//                               height: 1.25,
//                             ),
//                           ),
//                           const SizedBox(height: 2),
//                           // Text(
//                           //   userRole.toUpperCase(),
//                           //   style: TextStyle(
//                           //     color: Colors.white.withOpacity(0.88),
//                           //     fontSize: 11,
//                           //     fontWeight: FontWeight.w500,
//                           //     letterSpacing: 1.2,
//                           //   ),
//                           // ),
//                         ],
//                       ),
//                     ),
//
//                     // ── Logout icon (inside card) ─
//                     IconButton(
//                       onPressed: () => AuthController.logout().then(
//                         (_) => NavigationHelper.goToLogin(context),
//                       ),
//                       icon: Icon(
//                         Icons.logout_rounded,
//                         color: Colors.white.withOpacity(0.9),
//                         size: 24,
//                       ),
//                       tooltip: 'Logout',
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }





import 'package:flutter/material.dart';
import 'dart:ui' show ImageFilter;
import '../../../../core/controllers/auth_controller.dart';
import '../../../../core/navigation/navigation_helper.dart';


import '../../../../core/controllers/notification_inbox_controller.dart';
import '../notification_screen.dart';

class HomeHeader extends StatelessWidget {
  final String userName;
  final String uid; //  added for local notifications
  final Color primaryBlue;
  final Color primaryBlueDeep;

  const HomeHeader({
    super.key,
    required this.userName,
    required this.uid, //  added for local notifications
    required this.primaryBlue,
    required this.primaryBlueDeep,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 4, bottom: 12),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: [
            // ── Gradient background ───────────────
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      primaryBlue.withOpacity(0.95),
                      const Color(0xFF56CCF2).withOpacity(0.9),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              ),
            ),

            // ── Glass overlay ─────────────────────
            BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.white.withOpacity(0.22),
                      Colors.white.withOpacity(0.06),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.35),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 24,
                      offset: const Offset(0, 12),
                    ),
                  ],
                ),
                padding: const EdgeInsets.fromLTRB(22, 22, 16, 22),
                child: Row(
                  children: [
                    // ── Avatar ────────────────────
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.12),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: CircleAvatar(
                        radius: 30,
                        backgroundColor: Colors.white,
                        child: Text(
                          userName.isNotEmpty
                              ? userName[0].toUpperCase()
                              : '?',
                          style: TextStyle(
                            fontSize: 24,
                            color: primaryBlue,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(width: 16),

                    // ── Name ───────────────
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.waving_hand_rounded,
                                size: 16,
                                color: Colors.white.withOpacity(0.85),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Welcome back',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.85),
                                  fontWeight: FontWeight.w500,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Hi, ${userName.split(' ').first}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 18,
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // ── Notification + Logout ─
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // 🔔 Notification Bell
                        StreamBuilder<int>(
                          stream: NotificationInboxController
                              .unreadCountStream(uid),
                          builder: (context, snap) {
                            final count = snap.data ?? 0;

                            return Stack(
                              children: [
                                IconButton(
                                  icon: Icon(
                                    Icons.notifications_outlined,
                                    color: Colors.white.withOpacity(0.9),
                                    size: 24,
                                  ),
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) =>
                                           NotificationScreen(
                                              uid: uid,
                                            ),
                                      ),
                                    );
                                  },
                                ),

                                //  Badge count
                                if (count > 0)
                                  Positioned(
                                    right: 6,
                                    top: 6,
                                    child: Container(
                                      padding: const EdgeInsets.all(3),
                                      decoration: const BoxDecoration(
                                        color: Colors.red,
                                        shape: BoxShape.circle,
                                      ),
                                      constraints: const BoxConstraints(
                                        minWidth: 18,
                                        minHeight: 18,
                                      ),
                                      child: Text(
                                        count > 99
                                            ? '99+'
                                            : '$count',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                  ),
                              ],
                            );
                          },
                        ),

                        // Logout
                        IconButton(
                          onPressed: () =>
                              AuthController.logout().then(
                                    (_) => NavigationHelper.goToLogin(context),
                              ),
                          icon: Icon(
                            Icons.logout_rounded,
                            color: Colors.white.withOpacity(0.9),
                            size: 24,
                          ),
                          tooltip: 'Logout',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}