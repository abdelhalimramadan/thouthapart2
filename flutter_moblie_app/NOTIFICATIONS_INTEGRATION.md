# Notifications Integration Guide

## Overview
تم ربط شاشة الإشعارات (Notifications Screen) مع API الإشعارات من الـ Notification Microservice (http://16.16.218.59:9000).

## Architecture

### 1. **Data Layer**
- **Repository**: `NotificationRepo` (`lib/features/notifications/data/repos/notification_repo.dart`)
  - يتعامل مع جميع عمليات API للإشعارات
  - Methods:
    - `getNotifications()` - جلب جميع الإشعارات
    - `markNotificationAsRead(id)` - وضع علامة على إشعار واحد كمقروء
    - `markAllNotificationsAsRead()` - وضع علامة على كل الإشعارات كمقروء
    - `deleteNotification(id)` - حذف إشعار واحد
    - `deleteAllNotifications()` - حذف جميع الإشعارات
    - `registerDeviceToken(...)` - تسجيل FCM token

- **Models**: `NotificationLogModel` (`lib/features/notifications/data/models/notification_log_model.dart`)
  - يمثل بيانات الإشعار الواحد

### 2. **Business Logic Layer (State Management)**
- **Cubit**: `NotificationsCubit` (`lib/features/notifications/logic/notifications_cubit.dart`)
  - يدير حالة الإشعارات (Loading, Success, Failure)
  - Methods:
    - `fetchNotifications()` - جلب الإشعارات من API
    - `markAsRead(id)` - وضع علامة على إشعار كمقروء + تحديث الحالة
    - `markAllAsRead()` - وضع علامة على الكل كمقروء + تحديث الحالة
    - `deleteNotification(id)` - حذف + تحديث الحالة
    - `deleteAllNotifications()` - حذف الكل + تحديث الحالة
    - `getUnreadCount()` - الحصول على عدد الإشعارات غير المقروءة

- **State**: `NotificationsState` (`lib/features/notifications/logic/notifications_state.dart`)
  - `InitialState` - الحالة الأولية
  - `LoadingState` - حالة التحميل
  - `SuccessState` - حالة النجاح مع قائمة الإشعارات
  - `FailureState` - حالة الفشل مع رسالة الخطأ

### 3. **Presentation Layer**
- **Screen**: `NotificationsScreen` (`lib/features/notifications/ui/notifications_screen.dart`)
  - عرض قائمة الإشعارات
  - الحصول على عدد الإشعارات غير المقروءة لعرضها في الجرس (bell icon)
  - خيارات للعمليات:
    - وضع علامة على الكل كمقروء
    - حذف الكل
    - وضع علامة على الواحد كمقروء
    - حذف الواحد

### 4. **Integration with UI**
- **Notification Bell Icon**: موجود في `AppBar` في الشاشات التالية:
  - `doctor_home_screen.dart`
  - `doctor_confirmed_appointments_screen.dart`
  - `doctor_booking_records_screen.dart`
  - `doctor_next_booking_screen.dart`

- **Helper**: `NotificationHelper` (`lib/core/utils/notification_helper.dart`)
  - `getUnreadCount()` - يرجع عدد الإشعارات غير المقروءة من الـ Cubit
  - `markAsRead()` - تحديث حالة الإشعارات
  - `setHasUnread(bool)` - تعيين حالة الإشعارات

## API Endpoints

```
Base URL: http://16.16.218.59:9000/api/v1

GET /notifications
  Response: List<NotificationLogModel>

PATCH /notifications/{id}/read
  Response: { success: true }

PATCH /notifications/read-all
  Response: { success: true }

DELETE /notifications/{id}
  Response: { success: true }

DELETE /notifications
  Response: { success: true }
```

## Usage Example

### في أي Widget:
```dart
// الحصول على Cubit من DI
final cubit = getIt<NotificationsCubit>();

// جلب الإشعارات
await cubit.fetchNotifications();

// وضع علامة على إشعار كمقروء
await cubit.markAsRead(notificationId);

// الحصول على عدد الإشعارات غير المقروءة
int unreadCount = cubit.getUnreadCount();
```

### في StatefulWidget:
```dart
class MyScreen extends StatefulWidget {
  @override
  State<MyScreen> createState() => _MyScreenState();
}

class _MyScreenState extends State<MyScreen> {
  late NotificationsCubit _cubit;

  @override
  void initState() {
    super.initState();
    _cubit = getIt<NotificationsCubit>();
    _cubit.fetchNotifications(); // جلب الإشعارات عند الدخول
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<NotificationsCubit, NotificationsState>(
      bloc: _cubit,
      builder: (context, state) {
        if (state is LoadingState) {
          return CircularProgressIndicator();
        } else if (state is SuccessState) {
          return ListView(
            children: state.notifications.map((notif) {
              return NotificationTile(notification: notif);
            }).toList(),
          );
        } else if (state is FailureState) {
          return Text('Error: ${state.message}');
        }
        return SizedBox.shrink();
      },
    );
  }
}
```

### عرض عدد الإشعارات غير المقروءة في الجرس:
```dart
// في AppBar
Stack(
  children: [
    IconButton(
      icon: Icon(Icons.notifications_none),
      onPressed: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => NotificationsScreen()),
      ),
    ),
    // عرض badge مع عدد الإشعارات
    if (unreadCount > 0)
      Positioned(
        right: 8,
        top: 10,
        child: Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: Colors.red,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              unreadCount > 9 ? '9+' : '$unreadCount',
              style: TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
  ],
)
```

## Dependency Injection Setup

تم تسجيل النوتيفيكيشن كيوبت في `lib/core/di/dependency_injection.dart`:

```dart
getIt.registerFactory<NotificationsCubit>(
  () => NotificationsCubit(getIt()),
);
```

## Data Model

```dart
@freezed
class NotificationLogModel {
  const factory NotificationLogModel({
    required int id,
    required String title,
    required String body,
    @Default(false) bool readStatus,
    @JsonKey(name: 'createdAt') required String createdAt,
    @Default('') String? appointmentId,
    @Default('') String? messageId,
    @Default('') String? doctorId,
    @Default('') String? type,
    @Default('') String? time,
    @Default('') String? clinic,
    @Default('') String? doctorName,
  }) = _NotificationLogModel;

  factory NotificationLogModel.fromJson(Map<String, dynamic> json) =>
      _$NotificationLogModelFromJson(json);
}
```

## Features Implemented

✅ جلب الإشعارات من API  
✅ عرض الإشعارات في قائمة  
✅ وضع علامة على الإشعارات كمقروءة  
✅ حذف الإشعارات  
✅ عرض عدد الإشعارات غير المقروءة في الجرس  
✅ تحديث الحالة تلقائياً بعد العمليات  
✅ معالجة الأخطاء والحالات الفارغة  
✅ تنسيق الوقت (منذ دقيقة، منذ ساعة، إلخ)  
✅ قائمة خيارات (وضع علامة كمقروء، حذف) لكل إشعار  

## Next Steps (Optional)

إذا أردت تحسينات إضافية:

1. **Pagination**: إضافة pagination لتحميل الإشعارات تدريجياً
2. **Local Caching**: حفظ الإشعارات محلياً مع Hive أو SQLite
3. **Real-time Updates**: استخدام WebSocket أو Firebase Realtime لتحديثات فورية
4. **Sound & Vibration**: إضافة صوت واهتزاز عند وصول إشعار جديد
5. **Notification Preferences**: شاشة لتغيير تفضيلات الإشعارات

---

**Status**: ✅ Integration Complete - Ready to Use

