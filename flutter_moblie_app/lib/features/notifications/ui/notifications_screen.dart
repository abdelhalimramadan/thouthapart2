import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:thoutha_mobile_app/core/di/dependency_injection.dart';
import 'package:thoutha_mobile_app/core/helpers/shared_pref_helper.dart';
import 'package:thoutha_mobile_app/features/notifications/logic/notifications_cubit.dart';
import 'package:thoutha_mobile_app/core/routing/routes.dart';
import 'package:intl/intl.dart' as intl;
import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:showcaseview/showcaseview.dart';
import 'package:thoutha_mobile_app/tour/tour_config.dart';
import 'package:thoutha_mobile_app/tour/tour_service.dart';

/// Notifications Screen - Displays push notifications
class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  late NotificationsCubit _cubit;
  bool _showUnreadOnly = false;
  bool _isTourStarted = false;

  @override
  void initState() {
    super.initState();
    _cubit = getIt<NotificationsCubit>();
    _cubit.fetchNotifications();
    log('NotificationsScreen displayed');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;

        final navigator = Navigator.of(context);
        final doctorId = await SharedPrefHelper.getInt('doctor_id');

        if (navigator.canPop()) {
          navigator.pop();
        } else {
          if (context.mounted) {
            navigator.pushNamedAndRemoveUntil(
              doctorId != 0 ? Routes.doctorHomeScreen : Routes.categoriesScreen,
              (route) => false,
            );
          }
        }
      },
      child: ShowCaseWidget(
        onComplete: (index, key) {
          TourService.onDismiss(key)();
        },
        builder: (context) {
          if (!_isTourStarted) {
            _isTourStarted = true;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) TourService.startTourForScreen(context, 'notifications');
            });
          }
          return Scaffold(
        backgroundColor: isDark ? Color(0xFF1F1F1F) : Color(0xFFF1F1F1),
        appBar: AppBar(
          title: Text(
            'notifications.notifications'.tr(),
            style: TextStyle(
              fontFamily: 'Cairo',
              fontWeight: FontWeight.w700,
              fontSize: 20,
            ),
          ),
          centerTitle: true,
          elevation: 0,
          scrolledUnderElevation: 0,
          backgroundColor: Colors.transparent,
          leading: IconButton(
            icon: Icon(Icons.arrow_back_ios_new_rounded),
            onPressed: () async {
              final navigator = Navigator.of(context);
              if (navigator.canPop()) {
                navigator.pop();
              } else {
                final doctorId = await SharedPrefHelper.getInt('doctor_id');
                if (context.mounted) {
                  navigator.pushNamedAndRemoveUntil(
                    doctorId != 0
                        ? Routes.doctorHomeScreen
                        : Routes.categoriesScreen,
                    (route) => false,
                  );
                }
              }
            },
          ),
          actions: [
            BlocBuilder<NotificationsCubit, NotificationsState>(
              bloc: _cubit,
              builder: (context, state) {
                if (state is SuccessState && state.notifications.isNotEmpty) {
                  final unreadCount =
                      state.notifications.where((n) => n.readStatus == false).length;
  
                  return Showcase(
                    key: TourConfig.notifFilterKey,
                    title: 'تصفية الإشعارات',
                    description: 'فلتر لعرض الإشعارات غير المقروءة فقط',
                    child: IconButton(
                    tooltip: _showUnreadOnly
                        ? 'notifications.view_all_notifications'.tr()
                        : 'notifications.show_unread_only'.tr(),
                    onPressed: () {
                      setState(() {
                        _showUnreadOnly = !_showUnreadOnly;
                      });
                    },
                    icon: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Icon(
                          _showUnreadOnly
                              ? Icons.mark_email_unread_rounded
                              : Icons.mark_email_read_outlined,
                          color: _showUnreadOnly
                              ? theme.colorScheme.primary
                              : theme.colorScheme.onSurface.withOpacity(0.75),
                        ),
                         if (unreadCount > 0)
                           PositionedDirectional(
                             top: -4,
                             end: -6,
                             child: Container(
                               padding: EdgeInsets.symmetric(
                                 horizontal: unreadCount > 9 ? 4 : 5,
                                 vertical: 1,
                               ),
                               constraints: BoxConstraints(
                                 minWidth: 16,
                                 minHeight: 16,
                               ),
                               decoration: BoxDecoration(
                                 color: Colors.red,
                                 borderRadius: BorderRadius.circular(12),
                                 border: Border.all(
                                   color: theme.scaffoldBackgroundColor,
                                   width: 1,
                                 ),
                               ),
                               child: Text(
                                 unreadCount > 99 ? '99+' : '$unreadCount',
                                 textAlign: TextAlign.center,
                                 style: TextStyle(
                                   color: Colors.white,
                                   fontFamily: 'Cairo',
                                   fontSize: 9,
                                   fontWeight: FontWeight.w700,
                                   height: 1.1,
                                 ),
                               ),
                             ),
                           ),
                      ],
                    ),
                  ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
            const SizedBox.shrink(),
          ],
        ),
        body: Container(
          decoration: BoxDecoration(
            color: isDark ? Color(0xFF1F1F1F) : Color(0xFFF1F1F1),
          ),
          child: BlocBuilder<NotificationsCubit, NotificationsState>(
            bloc: _cubit,
            builder: (context, state) {
              final isDark = Theme.of(context).brightness == Brightness.dark;
            if (state is LoadingState) {
              return Center(
                child: CircularProgressIndicator(),
              );
            } else if (state is SuccessState) {
              final visibleNotifications = _showUnreadOnly
                  ? state.notifications.where((n) => n.readStatus == false).toList()
                  : state.notifications;
  
              if (state.notifications.isEmpty) {
                return _buildEmptyState();
              }
  
              if (visibleNotifications.isEmpty) {
                return _buildNoUnreadState();
              }
  
              return RefreshIndicator(
                onRefresh: () async {
                  await _cubit.fetchNotifications();
                },
                color: theme.colorScheme.primary,
                child: ListView.builder(
                  physics: BouncingScrollPhysics(
                    parent: AlwaysScrollableScrollPhysics(),
                  ),
                  padding: EdgeInsets.fromLTRB(14, 8, 14, 20),
                  itemCount: visibleNotifications.length,
                  itemBuilder: (context, index) {
                    final notification = visibleNotifications[index];
                    return _buildNotificationCard(context, notification);
                  },
                ),
              );
            } else if (state is FailureState) {
              return Center(
                child: Container(
                  margin: EdgeInsets.symmetric(horizontal: 20),
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                  decoration: BoxDecoration(
                    color: theme.cardColor,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: Colors.red.withOpacity(0.28)),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.error_outline_rounded,
                        size: 54,
                        color: Colors.red,
                      ),
                      SizedBox(height: 12),
                      Text(
                        'notifications.unable_to_load_notifications'.tr(),
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        state.message,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13,
                          color: isDark ? Colors.white70 : theme.colorScheme.onSurface.withOpacity(0.7),
                          fontFamily: 'Cairo',
                        ),
                      ),
                      SizedBox(height: 16),
                      FilledButton.icon(
                        onPressed: _cubit.fetchNotifications,
                        icon: Icon(Icons.refresh_rounded),
                        label: Text('doctor.retry'.tr()),
                      ),
                    ],
                  ),
                ),
              );
            }
            return _buildEmptyState();
            },
          ),
        ),
      );
    },
   ),
  );
 }


  Widget _buildEmptyState() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 94,
            height: 94,
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withOpacity(0.06)
                  : theme.colorScheme.primary.withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.notifications_none_rounded,
              size: 52,
              color: theme.colorScheme.primary,
            ),
          ),
           SizedBox(height: 16),
           Text(
             'notifications.no_notifications'.tr(),
             style: TextStyle(
               fontSize: 20,
               fontWeight: FontWeight.bold,
               color: isDark ? Colors.white : theme.colorScheme.onSurface,
               fontFamily: 'Cairo',
             ),
           ),
           SizedBox(height: 8),
           Text(
             'notifications.notifications_will_be_displayed'.tr(),
             style: TextStyle(
               fontSize: 14,
               color: theme.colorScheme.onSurface.withOpacity(0.65),
               fontFamily: 'Cairo',
             ),
             textAlign: TextAlign.center,
           ),
           SizedBox(height: 20),
           OutlinedButton.icon(
             onPressed: _cubit.fetchNotifications,
             icon: Icon(Icons.refresh_rounded),
             label: Text(
               'notifications.to_update'.tr(),
               style: TextStyle(fontFamily: 'Cairo'),
             ),
           ),
        ],
      ),
    );
  }

  Widget _buildNoUnreadState() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.mark_email_read_rounded,
            size: 56,
            color: theme.colorScheme.primary,
          ),
           SizedBox(height: 12),
           Text(
             'notifications.all_notifications_are_read'.tr(),
             style: TextStyle(
               fontSize: 18,
               fontWeight: FontWeight.w700,
               color: isDark ? Colors.white : theme.colorScheme.onSurface,
               fontFamily: 'Cairo',
             ),
           ),
           SizedBox(height: 6),
           Text(
             'notifications.click_on_the_icon'.tr(),
             style: TextStyle(
               fontSize: 13,
               color: isDark ? Colors.white.withOpacity(0.9) : theme.colorScheme.onSurface.withOpacity(0.65),
               fontFamily: 'Cairo',
             ),
           ),
        ],
      ),
    );
  }

  Widget _buildNotificationCard(BuildContext context, dynamic notification) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    DateTime? createdDate;
    try {
      createdDate = DateTime.parse(notification.createdAt);
    } catch (_) {
      createdDate = null;
    }

    return AnimatedContainer(
      duration: Duration(milliseconds: 220),
      margin: EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        color: notification.readStatus
            ? theme.cardColor
            : (isDark
                ? theme.colorScheme.primary.withOpacity(0.12)
                : theme.colorScheme.primary.withOpacity(0.08)),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: notification.readStatus
              ? theme.dividerColor.withOpacity(0.25)
              : theme.colorScheme.primary.withOpacity(0.35),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.22 : 0.06),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () async {
            // 1. Mark as read if not already read
            if (!notification.readStatus) {
              _cubit.markAsRead(notification.id);
            }

            // 2. Navigate to Upcoming Appointments (Hujoozat al-Qadima)
            final appointmentId = notification.appointmentId;
            final doctorId = await SharedPrefHelper.getInt('doctor_id');
            
            if (context.mounted) {
              Navigator.pushNamed(
                context,
                doctorId != 0 
                  ? Routes.doctorNextBookingScreen 
                  : Routes.appointmentsScreen,
                arguments: appointmentId != null && appointmentId.isNotEmpty 
                  ? {'appointmentId': appointmentId} 
                  : null,
              );
            }
          },
          child: Stack(
        children: [
          PositionedDirectional(
            start: 0,
            top: 0,
            bottom: 0,
            child: AnimatedContainer(
              duration: Duration(milliseconds: 220),
              width: 4,
              decoration: BoxDecoration(
                color: notification.readStatus
                    ? Colors.transparent
                    : theme.colorScheme.primary,
                borderRadius: BorderRadiusDirectional.only(
                  topStart: Radius.circular(16),
                  bottomStart: Radius.circular(16),
                ),
              ),
            ),
          ),
          ListTile(
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            leading: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: notification.readStatus
                    ? theme.colorScheme.surface
                    : theme.colorScheme.primary.withOpacity(0.16),
                shape: BoxShape.circle,
              ),
              child: Padding(
                padding: EdgeInsets.all(8),
                child: Opacity(
                  opacity: notification.readStatus ? 0.78 : 1,
                  child: Image.asset(
                    'assets/images/splash-logo.png',
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
            title: Row(
              children: [
                Expanded(
                  child: Text(
                    notification.title ?? 'notifications.untitled'.tr(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: notification.readStatus
                          ? FontWeight.w500
                          : FontWeight.w700,
                      fontFamily: 'Cairo',
                    ),
                  ),
                ),
                if (!notification.readStatus)
                  Container(
                    width: 8,
                    height: 8,
                    margin: EdgeInsetsDirectional.only(start: 6),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
              ],
            ),
            subtitle: Padding(
              padding: EdgeInsets.only(top: 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    notification.body ?? 'notifications.no_content'.tr(),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      height: 1.45,
                      color: isDark ? Colors.white.withOpacity(0.9) : theme.colorScheme.onSurface.withOpacity(0.72),
                      fontFamily: 'Cairo',
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    ),
  ),
);
}

  void _showNotificationDetailsSheet(
    BuildContext context,
    dynamic notification,
    DateTime? createdDate,
    String relativeTime,
  ) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
     final title = (notification.title?.toString().trim().isNotEmpty ?? false)
         ? notification.title.toString().trim()
         : 'notifications.untitled'.tr();
     final body = (notification.body?.toString().trim().isNotEmpty ?? false)
         ? notification.body.toString().trim()
         : 'notifications.no_content'.tr();

     final fullDate = createdDate != null
         ? intl.DateFormat('dd/MM/yyyy - HH:mm', 'ar').format(createdDate)
         : 'notifications.unknown_time'.tr();
     final shownRelativeTime =
         relativeTime.isNotEmpty ? relativeTime : 'notifications.unknown_time'.tr();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: theme.cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: EdgeInsets.fromLTRB(16, 12, 16, 20),
            child: Directionality(
              textDirection: TextDirection.rtl,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: 10),
                  Text(
                    body,
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 14,
                      height: 1.5,
                      color: isDark ? Colors.white : theme.colorScheme.onSurface.withOpacity(0.85),
                    ),
                  ),
                  SizedBox(height: 12),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
