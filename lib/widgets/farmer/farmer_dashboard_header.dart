import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../profile_avatar_image.dart';

class FarmerInboxMessage {
  final String id;
  final String title;
  final String body;
  final String timeAgo;
  final bool isRead;

  const FarmerInboxMessage({
    required this.id,
    required this.title,
    required this.body,
    required this.timeAgo,
    this.isRead = false,
  });

  FarmerInboxMessage copyWith({bool? isRead}) {
    return FarmerInboxMessage(
      id: id,
      title: title,
      body: body,
      timeAgo: timeAgo,
      isRead: isRead ?? this.isRead,
    );
  }
}

class FarmerDashboardHeader extends StatelessWidget {
  final String farmerName;
  final String profileImageUrl;
  final VoidCallback? onLogout;
  final VoidCallback? onEditProfile;
  final List<FarmerInboxMessage> messages;
  final ValueChanged<String>? onNotificationRead;

  const FarmerDashboardHeader({
    super.key,
    required this.farmerName,
    required this.profileImageUrl,
    this.onLogout,
    this.onEditProfile,
    this.messages = const [],
    this.onNotificationRead,
  });

  int get _unreadCount => messages.where((m) => !m.isRead).length;

  void _showMessages(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return _NotificationsSheet(
          initialMessages: messages,
          onNotificationRead: onNotificationRead,
        );
      },
    );
  }

  void _showProfileMenu(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.border,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                ProfileAvatarImage(
                  imageUrl: profileImageUrl,
                  size: 72,
                  borderColor: AppColors.primary,
                  fallbackIconColor: AppColors.primary,
                ),
                const SizedBox(height: 12),
                Text(
                  farmerName,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: onEditProfile == null
                        ? null
                        : () {
                            Navigator.pop(ctx);
                            onEditProfile!();
                          },
                    icon: const Icon(Icons.edit_outlined),
                    label: const Text('Edit Profile'),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(ctx);
                      onLogout?.call();
                    },
                    icon: const Icon(Icons.logout_rounded, color: AppColors.error),
                    label: const Text(
                      'Logout',
                      style: TextStyle(color: AppColors.error),
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: const BorderSide(color: AppColors.error),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primaryDark, AppColors.primary],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'AgriMarket Ethiopia',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.3,
                      ),
                    ),
                  ),
                  InkWell(
                    onTap: () => _showMessages(context),
                    borderRadius: BorderRadius.circular(24),
                    child: Padding(
                      padding: const EdgeInsets.all(6),
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          const Icon(
                            Icons.notifications_none_rounded,
                            color: Colors.white,
                            size: 28,
                          ),
                          if (_unreadCount > 0)
                            Positioned(
                              right: -2,
                              top: -2,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 5,
                                  vertical: 2,
                                ),
                                constraints: const BoxConstraints(
                                  minWidth: 18,
                                  minHeight: 18,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.red,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: Colors.white, width: 1.5),
                                ),
                                child: Text(
                                  _unreadCount > 9 ? '9+' : '$_unreadCount',
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    height: 1.1,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => _showProfileMenu(context),
                  borderRadius: BorderRadius.circular(16),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        ProfileAvatarImage(
                          imageUrl: profileImageUrl,
                          size: 56,
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                farmerName,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              Text(
                                'Tap to edit profile',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.85),
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          Icons.chevron_right_rounded,
                          color: Colors.white.withValues(alpha: 0.8),
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
    );
  }
}

class _NotificationsSheet extends StatefulWidget {
  final List<FarmerInboxMessage> initialMessages;
  final ValueChanged<String>? onNotificationRead;

  const _NotificationsSheet({
    required this.initialMessages,
    this.onNotificationRead,
  });

  @override
  State<_NotificationsSheet> createState() => _NotificationsSheetState();
}

class _NotificationsSheetState extends State<_NotificationsSheet> {
  late List<FarmerInboxMessage> _messages;

  @override
  void initState() {
    super.initState();
    _messages = List<FarmerInboxMessage>.from(widget.initialMessages);
  }

  int get _unreadCount => _messages.where((m) => !m.isRead).length;

  void _openNotificationDetail(FarmerInboxMessage message) {
    if (!message.isRead) {
      setState(() {
        _messages = _messages
            .map((m) => m.id == message.id ? m.copyWith(isRead: true) : m)
            .toList();
      });
      widget.onNotificationRead?.call(message.id);
    }

    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(message.title),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                message.body,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                message.timeAgo,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.55,
      minChildSize: 0.35,
      maxChildSize: 0.9,
      builder: (context, scrollController) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 12),
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Row(
                children: [
                  Text(
                    'Notifications',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  if (_unreadCount > 0) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '$_unreadCount new',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Expanded(
              child: _messages.isEmpty
                  ? const Center(
                      child: Text(
                        'No notifications right now',
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                    )
                  : ListView.separated(
                      controller: scrollController,
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                      itemCount: _messages.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final msg = _messages[index];
                        return ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 4,
                          ),
                          onTap: () => _openNotificationDetail(msg),
                          leading: CircleAvatar(
                            backgroundColor: msg.isRead
                                ? AppColors.surface
                                : AppColors.primary.withValues(alpha: 0.15),
                            child: Icon(
                              Icons.notifications_outlined,
                              color: msg.isRead
                                  ? AppColors.textSecondary
                                  : AppColors.primary,
                              size: 22,
                            ),
                          ),
                          title: Text(
                            msg.title,
                            style: TextStyle(
                              fontWeight:
                                  msg.isRead ? FontWeight.w500 : FontWeight.w700,
                              fontSize: 14,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
                              Text(
                                msg.body,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: AppColors.textSecondary,
                                  height: 1.35,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                msg.timeAgo,
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                          trailing: const Icon(
                            Icons.chevron_right_rounded,
                            color: AppColors.textSecondary,
                          ),
                          isThreeLine: true,
                        );
                      },
                    ),
            ),
          ],
        );
      },
    );
  }
}
