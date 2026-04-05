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

  @override
  void initState() {
    super.initState();
    _cubit = getIt<NotificationsCubit>();
    _cubit.fetchNotifications();
    log('📱 NotificationsScreen displayed');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('الإشعارات'),
        centerTitle: true,
        elevation: 0,
        actions: [
          BlocBuilder<NotificationsCubit, NotificationsState>(
            bloc: _cubit,
            builder: (context, state) {
              if (state is SuccessState && state.notifications.isNotEmpty) {
                return Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8.w),
                  child: Center(
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
                      icon: const Icon(Icons.more_vert),
                    ),
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          )
        ],
      ),
      body: BlocBuilder<NotificationsCubit, NotificationsState>(
        bloc: _cubit,
        builder: (context, state) {
          if (state is LoadingState) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          } else if (state is SuccessState) {
            if (state.notifications.isEmpty) {
              return _buildEmptyState();
            }
            return RefreshIndicator(
              onRefresh: () async {
                await _cubit.fetchNotifications();
              },
              child: ListView.builder(
                padding: EdgeInsets.all(8.w),
                itemCount: state.notifications.length,
                itemBuilder: (context, index) {
                  final notification = state.notifications[index];
                  return _buildNotificationCard(context, notification);
                },
              ),
            );
          } else if (state is FailureState) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64.r,
                    color: Colors.red,
                  ),
                  SizedBox(height: 16.h),
                  Text(
                    'حدث خطأ: ${state.message}',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16.sp,
                      color: Colors.red,
                      fontFamily: 'Cairo',
                    ),
                  ),
                  SizedBox(height: 32.h),
                  ElevatedButton(
                    onPressed: () => _cubit.fetchNotifications(),
                    child: const Text('حاول مرة أخرى'),
                  ),
                ],
              ),
            );
          }
          return _buildEmptyState();
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.notifications_none_rounded,
            size: 80.r,
            color: Colors.grey[400],
          ),
          SizedBox(height: 16.h),
          Text(
            'لا توجد إشعارات',
            style: TextStyle(
              fontSize: 20.sp,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
              fontFamily: 'Cairo',
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            'سيتم عرض إشعاراتك هنا عند وصولها',
            style: TextStyle(
              fontSize: 14.sp,
              color: Colors.grey[500],
              fontFamily: 'Cairo',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationCard(
    BuildContext context,
    dynamic notification,
  ) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Try to parse createdAt for formatting
    DateTime? createdDate;
    try {
      createdDate = DateTime.parse(notification.createdAt);
    } catch (e) {
      createdDate = null;
    }

    String timeStr = '';
    if (createdDate != null) {
      final now = DateTime.now();
      final difference = now.difference(createdDate);

      if (difference.inMinutes < 1) {
        timeStr = 'الآن';
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

    return Card(
      margin: EdgeInsets.symmetric(vertical: 6.h),
      color: notification.readStatus
          ? theme.cardColor
          : (isDark ? Colors.blue[900]?.withOpacity(0.3) : Colors.blue[50]),
      elevation: notification.readStatus ? 0 : 2,
      child: ListTile(
        contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
        leading: Container(
          width: 50.w,
          height: 50.h,
          decoration: BoxDecoration(
            color: notification.readStatus
                ? theme.colorScheme.surface
                : theme.primaryColor.withOpacity(0.2),
            borderRadius: BorderRadius.circular(8.r),
          ),
          child: Icon(
            Icons.notifications_active,
            color: notification.readStatus ? Colors.grey : theme.primaryColor,
            size: 24.r,
          ),
        ),
        title: Text(
          notification.title ?? 'بدون عنوان',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 14.sp,
            fontWeight:
                notification.readStatus ? FontWeight.normal : FontWeight.bold,
            fontFamily: 'Cairo',
            color: notification.readStatus
                ? theme.colorScheme.onSurface.withOpacity(0.7)
                : theme.colorScheme.onSurface,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 4.h),
            Text(
              notification.body ?? 'بدون محتوى',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12.sp,
                color: theme.colorScheme.onSurface.withOpacity(0.6),
                fontFamily: 'Cairo',
              ),
            ),
            SizedBox(height: 6.h),
            Text(
              timeStr.isNotEmpty ? timeStr : 'وقت غير معروف',
              style: TextStyle(
                fontSize: 10.sp,
                color: theme.colorScheme.onSurface.withOpacity(0.5),
                fontFamily: 'Cairo',
              ),
            ),
          ],
        ),
        trailing: PopupMenuButton(
          onSelected: (value) {
            if (value == 'mark_read') {
              _cubit.markAsRead(notification.id);
            } else if (value == 'delete') {
              _cubit.deleteNotification(notification.id);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('تم حذف الإشعار'),
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
          icon: Icon(
            Icons.more_vert,
            size: 20.r,
            color: theme.colorScheme.onSurface.withOpacity(0.5),
          ),
        ),
      ),
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
