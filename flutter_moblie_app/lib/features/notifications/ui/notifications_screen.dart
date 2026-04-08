import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:thoutha_mobile_app/core/di/dependency_injection.dart';
import 'package:thoutha_mobile_app/features/notifications/logic/notifications_cubit.dart';
import 'package:intl/intl.dart' as intl;

/// Notifications Screen - Displays push notifications
class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  late NotificationsCubit _cubit;
  bool _showUnreadOnly = false;

  @override
  void initState() {
    super.initState();
    _cubit = getIt<NotificationsCubit>();
    _cubit.fetchNotifications();
    log('📱 NotificationsScreen displayed');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF1F1F1F) : const Color(0xFFF1F1F1),
      appBar: AppBar(
        title: Text(
          'الإشعارات',
          style: TextStyle(
            fontFamily: 'Cairo',
            fontWeight: FontWeight.w700,
            fontSize: 20.sp,
          ),
        ),
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: Colors.transparent,
        actions: [
          BlocBuilder<NotificationsCubit, NotificationsState>(
            bloc: _cubit,
            builder: (context, state) {
              if (state is SuccessState && state.notifications.isNotEmpty) {
                final unreadCount =
                    state.notifications.where((n) => n.readStatus == false).length;

                return IconButton(
                  tooltip: _showUnreadOnly
                      ? 'عرض كل الاشعارات'
                      : 'عرض غير المقروء فقط',
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
                            : theme.colorScheme.onSurface.withValues(alpha: 0.75),
                      ),
                      if (unreadCount > 0)
                        PositionedDirectional(
                          top: -4,
                          end: -6,
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: unreadCount > 9 ? 4.w : 5.w,
                              vertical: 1.h,
                            ),
                            constraints: BoxConstraints(
                              minWidth: 16.w,
                              minHeight: 16.h,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.red,
                              borderRadius: BorderRadius.circular(12.r),
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
                                fontSize: 9.sp,
                                fontWeight: FontWeight.w700,
                                height: 1.1,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),
          BlocBuilder<NotificationsCubit, NotificationsState>(
            bloc: _cubit,
            builder: (context, state) {
              if (state is SuccessState && state.notifications.isNotEmpty) {
                return Padding(
                  padding: EdgeInsetsDirectional.only(end: 10.w),
                  child: Center(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.08)
                            : Colors.black.withValues(alpha: 0.04),
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      child: PopupMenuButton(
                      onSelected: (value) {
                        if (value == 'mark_all_read') {
                          _cubit.markAllAsRead();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content:
                                  Text('تم وضع علامة على كل الإشعارات كمقروءة'),
                              duration: Duration(seconds: 2),
                            ),
                          );
                        } else if (value == 'delete_all') {
                          _showDeleteAllDialog();
                        }
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'mark_all_read',
                          child: Text('وضع علامة على الكل كمقروء'),
                        ),
                        const PopupMenuItem(
                          value: 'delete_all',
                          child: Text('حذف الكل'),
                        ),
                      ],
                      icon: const Icon(Icons.more_vert_rounded),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14.r),
                      ),
                    ),
                    ),
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          )
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1F1F1F) : const Color(0xFFF1F1F1),
        ),
        child: BlocBuilder<NotificationsCubit, NotificationsState>(
          bloc: _cubit,
          builder: (context, state) {
          if (state is LoadingState) {
            return const Center(
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
                physics: const BouncingScrollPhysics(
                  parent: AlwaysScrollableScrollPhysics(),
                ),
                padding: EdgeInsets.fromLTRB(14.w, 8.h, 14.w, 20.h),
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
                margin: EdgeInsets.symmetric(horizontal: 20.w),
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 18.h),
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  borderRadius: BorderRadius.circular(18.r),
                  border: Border.all(color: Colors.red.withValues(alpha: 0.28)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.error_outline_rounded,
                      size: 54.r,
                      color: Colors.red,
                    ),
                    SizedBox(height: 12.h),
                    Text(
                      'تعذر تحميل الإشعارات',
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 17.sp,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(height: 8.h),
                    Text(
                      state.message,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13.sp,
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                        fontFamily: 'Cairo',
                      ),
                    ),
                    SizedBox(height: 16.h),
                    FilledButton.icon(
                      onPressed: _cubit.fetchNotifications,
                      icon: const Icon(Icons.refresh_rounded),
                      label: const Text('إعادة المحاولة'),
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
  }


  Widget _buildEmptyState() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 94.r,
            height: 94.r,
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.06)
                  : theme.colorScheme.primary.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.notifications_none_rounded,
              size: 52.r,
              color: theme.colorScheme.primary,
            ),
          ),
          SizedBox(height: 16.h),
          Text(
            'لا توجد اشعارات',
            style: TextStyle(
              fontSize: 20.sp,
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
              fontFamily: 'Cairo',
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            'سيتم عرض الاشعارات هنا عند وصولها',
            style: TextStyle(
              fontSize: 14.sp,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.65),
              fontFamily: 'Cairo',
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 20.h),
          OutlinedButton.icon(
            onPressed: _cubit.fetchNotifications,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text(
              'تحديث',
              style: TextStyle(fontFamily: 'Cairo'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoUnreadState() {
    final theme = Theme.of(context);

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.mark_email_read_rounded,
            size: 56.r,
            color: theme.colorScheme.primary,
          ),
          SizedBox(height: 12.h),
          Text(
            'كل الاشعارات مقروءة',
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.w700,
              color: theme.colorScheme.onSurface,
              fontFamily: 'Cairo',
            ),
          ),
          SizedBox(height: 6.h),
          Text(
            'اضغط على الايقونة لعرض كل الاشعارات',
            style: TextStyle(
              fontSize: 13.sp,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.65),
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

    String timeStr = '';
    if (createdDate != null) {
      final difference = DateTime.now().difference(createdDate);
      if (difference.inMinutes < 1) {
        timeStr = 'الان';
      } else if (difference.inMinutes < 60) {
        timeStr = 'منذ ${difference.inMinutes} دقيقة';
      } else if (difference.inHours < 24) {
        timeStr = 'منذ ${difference.inHours} ساعة';
      } else if (difference.inDays < 7) {
        timeStr = 'منذ ${difference.inDays} يوم';
      } else {
        timeStr = intl.DateFormat('dd/MM/yyyy HH:mm', 'ar').format(createdDate);
      }
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      margin: EdgeInsets.symmetric(vertical: 6.h),
      decoration: BoxDecoration(
        color: notification.readStatus
            ? theme.cardColor
            : (isDark
                ? theme.colorScheme.primary.withValues(alpha: 0.12)
                : theme.colorScheme.primary.withValues(alpha: 0.08)),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: notification.readStatus
              ? theme.dividerColor.withValues(alpha: 0.25)
              : theme.colorScheme.primary.withValues(alpha: 0.35),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.22 : 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16.r),
          onTap: () {
            if (!notification.readStatus) {
              _cubit.markAsRead(notification.id);
            }
            _showNotificationDetailsSheet(
              context,
              notification,
              createdDate,
              timeStr,
            );
          },
          child: Stack(
        children: [
          PositionedDirectional(
            start: 0,
            top: 0,
            bottom: 0,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              width: 4.w,
              decoration: BoxDecoration(
                color: notification.readStatus
                    ? Colors.transparent
                    : theme.colorScheme.primary,
                borderRadius: BorderRadiusDirectional.only(
                  topStart: Radius.circular(16.r),
                  bottomStart: Radius.circular(16.r),
                ),
              ),
            ),
          ),
          ListTile(
            contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
            leading: Container(
              width: 44.w,
              height: 44.h,
              decoration: BoxDecoration(
                color: notification.readStatus
                    ? theme.colorScheme.surface
                    : theme.colorScheme.primary.withValues(alpha: 0.16),
                shape: BoxShape.circle,
              ),
              child: Padding(
                padding: EdgeInsets.all(8.r),
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
                    notification.title ?? 'بدون عنوان',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: notification.readStatus
                          ? FontWeight.w500
                          : FontWeight.w700,
                      fontFamily: 'Cairo',
                    ),
                  ),
                ),
                if (!notification.readStatus)
                  Container(
                    width: 8.r,
                    height: 8.r,
                    margin: EdgeInsetsDirectional.only(start: 6.w),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
              ],
            ),
            subtitle: Padding(
              padding: EdgeInsets.only(top: 4.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    notification.body ?? 'بدون محتوى',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12.sp,
                      height: 1.45,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.72),
                      fontFamily: 'Cairo',
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Row(
                    children: [
                      Icon(
                        Icons.schedule_rounded,
                        size: 12.r,
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.45),
                      ),
                      SizedBox(width: 4.w),
                      Text(
                        timeStr.isNotEmpty ? timeStr : 'وقت غير معروف',
                        style: TextStyle(
                          fontSize: 10.sp,
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                          fontFamily: 'Cairo',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            trailing: PopupMenuButton(
              onSelected: (value) {
                if (value == 'mark_read') {
                  _cubit.markAsRead(notification.id);
                } else if (value == 'delete') {
                  _cubit.deleteNotification(notification.id);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('تم حذف الاشعار'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                }
              },
              itemBuilder: (context) => [
                if (!notification.readStatus)
                  const PopupMenuItem(
                    value: 'mark_read',
                    child: Text('وضع علامة كمقروء'),
                  ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Text('حذف'),
                ),
              ],
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14.r),
              ),
              icon: Icon(
                Icons.more_horiz_rounded,
                size: 20.r,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
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
    final title = (notification.title?.toString().trim().isNotEmpty ?? false)
        ? notification.title.toString().trim()
        : 'بدون عنوان';
    final body = (notification.body?.toString().trim().isNotEmpty ?? false)
        ? notification.body.toString().trim()
        : 'بدون محتوى';

    final fullDate = createdDate != null
        ? intl.DateFormat('dd/MM/yyyy - HH:mm', 'ar').format(createdDate)
        : 'وقت غير معروف';
    final shownRelativeTime =
        relativeTime.isNotEmpty ? relativeTime : 'وقت غير معروف';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: theme.cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 20.h),
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
                      fontSize: 18.sp,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: 10.h),
                  Text(
                    body,
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 14.sp,
                      height: 1.5,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.85),
                    ),
                  ),
                  SizedBox(height: 16.h),
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(12.r),
                      border: Border.all(
                        color: theme.dividerColor.withValues(alpha: 0.35),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'الوقت: $shownRelativeTime',
                          style: TextStyle(
                            fontFamily: 'Cairo',
                            fontSize: 12.sp,
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.72),
                          ),
                        ),
                        SizedBox(height: 4.h),
                        Text(
                          'التاريخ: $fullDate',
                          style: TextStyle(
                            fontFamily: 'Cairo',
                            fontSize: 12.sp,
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.72),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 12.h),
                ],
              ),
            ),
          ),
        );
      },
    );
  }


  void _showDeleteAllDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          'حذف جميع الإشعارات',
          style: TextStyle(fontFamily: 'Cairo'),
        ),
        content: const Text(
          'هل أنت متأكد من رغبتك في حذف جميع الإشعارات؟',
          style: TextStyle(fontFamily: 'Cairo'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'إلغاء',
              style: TextStyle(fontFamily: 'Cairo'),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _cubit.deleteAllNotifications();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('تم حذف جميع الإشعارات'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text(
              'حذف',
              style: TextStyle(
                fontFamily: 'Cairo',
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
