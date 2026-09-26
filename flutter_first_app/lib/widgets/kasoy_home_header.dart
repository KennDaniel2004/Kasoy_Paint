import 'package:flutter/material.dart';
import '../main.dart';

/// Top header for the Home screen: greeting block + notification button.
class KasoyHomeHeader extends StatelessWidget {
  const KasoyHomeHeader({
    super.key,
    required this.userName,
    required this.onNotificationTap,
    this.hasUnreadNotifications = true,
  });

  final String userName;
  final VoidCallback onNotificationTap;
  final bool hasUnreadNotifications;

  /// Resolves the greeting based on the current time of day.
  String get _greeting {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning,';
    if (hour < 18) return 'Good afternoon,';
    return 'Good evening,';
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _greeting,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textGrey,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Hello, $userName!',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 23,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark,
                    height: 1.15,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          _NotificationButton(
            onTap: onNotificationTap,
            showIndicator: hasUnreadNotifications,
          ),
        ],
      ),
    );
  }
}

/// Circular notification button with a small orange indicator dot.
class _NotificationButton extends StatelessWidget {
  const _NotificationButton({required this.onTap, required this.showIndicator});

  final VoidCallback onTap;
  final bool showIndicator;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: showIndicator
          ? 'Notifications, unread updates available'
          : 'Notifications',
      child: Material(
        color: Colors.white,
        shape: const CircleBorder(),
        elevation: 0,
        child: InkWell(
          onTap: onTap,
          customBorder: const CircleBorder(),
          child: SizedBox(
            width: 48,
            height: 48,
            child: Stack(
              alignment: Alignment.center,
              children: [
                const Icon(
                  Icons.notifications_none_rounded,
                  color: AppColors.textDark,
                  size: 24,
                ),
                if (showIndicator)
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Container(
                      width: 9,
                      height: 9,
                      decoration: const BoxDecoration(
                        color: AppColors.primaryOrange,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}