# 🔔 Notifications Quick Start Guide

## التثبيت والإعداد السريع

لا حاجة لأي تثبيت إضافي! كل شيء جاهز للعمل.

---

## ✅ ما تم فعله

### 1. **ربط API الإشعارات**
تم ربط `Notifications Screen` مع `Notification Microservice` عبر:
- `http://16.16.218.59:9000/api/v1/notifications`

### 2. **إنشاء State Management بـ Cubit**
- `NotificationsCubit` - يدير جلب وتحديث الإشعارات
- `NotificationsState` - حالات التطبيق (Loading, Success, Error, Empty)

### 3. **بناء الـ UI**
- عرض جميع الإشعارات في قائمة
- عرض عدد الإشعارات غير المقروءة في الجرس
- خيارات لكل إشعار (وضع علامة، حذف)
- خيارات للعمليات الجماعية

---

## 🎯 الاستخدام

### 1. الشاشة الرئيسية - عرض الجرس:
```dart
// في app bar من أي شاشة
IconButton(
  icon: Icon(Icons.notifications_none),
  onPressed: () => Navigator.push(
    context,
    MaterialPageRoute(builder: (_) => NotificationsScreen()),
  ),
)

// عرض الرقم الأحمر (عدد الإشعارات)
if (unreadCount > 0)
  Badge(label: Text('$unreadCount'))
```

### 2. فتح شاشة الإشعارات:
```dart
Navigator.push(
  context,
  MaterialPageRoute(builder: (_) => NotificationsScreen()),
);
```

### 3. جلب الإشعارات يدويًا:
```dart
final cubit = getIt<NotificationsCubit>();
await cubit.fetchNotifications();
```

---

## 📊 الحالات التي يتم معالجتها

| الحالة | الوصف |
|-------|-------|
| **Loading** | يتم جلب البيانات من API |
| **Success** | تم جلب الإشعارات بنجاح وعرضها |
| **Error** | حدث خطأ (شبكة، خادم، إلخ) |
| **Empty** | لا توجد إشعارات |

---

## 🎨 ميزات واجهة المستخدم

✅ **قائمة الإشعارات:**
- صورة لكل إشعار
- العنوان والمحتوى
- الوقت النسبي (منذ دقيقة، ساعة، يوم)
- لون مختلف للإشعارات غير المقروءة

✅ **الإجراءات:**
- وضع علامة على إشعار واحد كمقروء
- حذف إشعار واحد
- وضع علامة على الكل كمقروء
- حذف جميع الإشعارات

✅ **الميزات:**
- إعادة تحميل (Pull to Refresh)
- معالجة الأخطاء مع زر "حاول مرة أخرى"
- رسائل خطأ بالعربية
- دعم الوضع الداكن

---

## 🔧 الملفات الرئيسية

```
lib/
├── features/notifications/
│   ├── data/
│   │   ├── repos/
│   │   │   └── notification_repo.dart       (البيانات والـ API)
│   │   └── models/
│   │       └── notification_log_model.dart  (نموذج البيانات)
│   ├── logic/
│   │   ├── notifications_cubit.dart         (إدارة الحالة)
│   │   └── notifications_state.dart         (حالات التطبيق)
│   └── ui/
│       └── notifications_screen.dart        (الواجهة)
├── core/
│   ├── di/
│   │   └── dependency_injection.dart        (تسجيل الـ Cubit)
│   ├── networking/
│   │   └── api_service.dart                 (طلبات HTTP)
│   └── utils/
│       └── notification_helper.dart         (helper functions)
```

---

## 🌐 API Endpoints

| العملية | الطريقة | المسار |
|--------|--------|-------|
| جلب الكل | GET | `/api/v1/notifications` |
| وضع علامة على واحد | PUT | `/api/v1/notifications/{id}/read` |
| وضع علامة على الكل | PUT | `/api/v1/notifications/read-all` |
| حذف واحد | DELETE | `/api/v1/notifications/{id}` |
| حذف الكل | DELETE | `/api/v1/notifications` |

**Base URL**: `http://16.16.218.59:9000`

---

## 🔐 التوثيق (Authentication)

جميع طلبات API تتطلب:
```
Authorization: Bearer <JWT_TOKEN>
Content-Type: application/json
```

يتم إضافة Token تلقائياً بواسطة `DioFactory`.

---

## 📱 أمثلة عملية

### مثال 1: عرض عدد الإشعارات في الجرس

```dart
class DoctorHomeScreen extends StatefulWidget {
  @override
  State<DoctorHomeScreen> createState() => _DoctorHomeScreenState();
}

class _DoctorHomeScreenState extends State<DoctorHomeScreen> {
  late NotificationsCubit _cubit;

  @override
  void initState() {
    super.initState();
    _cubit = getIt<NotificationsCubit>();
    _cubit.fetchNotifications(); // جلب الإشعارات عند الدخول
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        actions: [
          BlocBuilder<NotificationsCubit, NotificationsState>(
            bloc: _cubit,
            builder: (context, state) {
              int unreadCount = _cubit.getUnreadCount();
              return Stack(
                children: [
                  IconButton(
                    icon: Icon(Icons.notifications_none),
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => NotificationsScreen()),
                    ),
                  ),
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
              );
            },
          ),
        ],
      ),
      body: Center(child: Text('Home Screen')),
    );
  }
}
```

### مثال 2: استدعاء عملية تحديث يدويًا

```dart
void handleMarkAsRead(int notificationId) async {
  final cubit = getIt<NotificationsCubit>();
  await cubit.markAsRead(notificationId);
  
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text('تم وضع علامة كمقروء')),
  );
}
```

### مثال 3: حذف جميع الإشعارات مع تأكيد

```dart
void handleDeleteAll() async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text('حذف جميع الإشعارات؟'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: Text('إلغاء'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(ctx, true),
          child: Text('حذف'),
        ),
      ],
    ),
  );

  if (confirmed == true) {
    final cubit = getIt<NotificationsCubit>();
    await cubit.deleteAllNotifications();
  }
}
```

---

## 🧪 اختبار الميزة

### خطوات الاختبار:

1. **تشغيل التطبيق**
   ```bash
   flutter run
   ```

2. **فتح شاشة الإشعارات**
   - اضغط على أيقونة الجرس في AppBar

3. **تحقق من الحالات:**
   - هل تظهر قائمة الإشعارات؟
   - هل يظهر عدد الإشعارات غير المقروءة؟
   - هل يعمل Pull-to-Refresh؟
   - هل تعمل خيارات الإجراءات؟

4. **اختبر الأخطاء:**
   - عطّل الإنترنت (Airplane Mode)
   - تحقق من رسالة الخطأ
   - اضغط "حاول مرة أخرى"

---

## 🐛 تصحيح الأخطاء (Debug)

### عرض السجلات:
```dart
// في النافذة Flutter الطرفية
// ابحث عن: "📨 Fetching notifications from API"
// ستشاهد جميع عمليات جلب البيانات
```

### استخدام DevTools:
```bash
flutter pub global activate devtools
devtools
```

---

## 📚 المراجع

- **Flutter BLoC Documentation**: https://bloclibrary.dev
- **Freezed Package**: https://pub.dev/packages/freezed
- **Dio HTTP Client**: https://pub.dev/packages/dio
- **GetIt Service Locator**: https://pub.dev/packages/get_it

---

## ❓ الأسئلة الشائعة

**س: كيف أجلب الإشعارات عند دخول الشاشة؟**
ج: تم تطبيق هذا تلقائياً في `initState` من `NotificationsScreen`.

**س: هل تُحفظ الإشعارات محلياً؟**
ج: حالياً لا، لكن يمكن إضافة Hive لـ caching إذا لزم الأمر.

**س: هل يتم تحديث الإشعارات فوراً؟**
ج: لا بشكل فوري. يمكن إضافة WebSocket للتحديثات الفورية.

**س: هل يعمل البحث والتصفية؟**
ج: حالياً لا، لكن يمكن إضافتها بسهولة في الـ Cubit.

---

## ✨ ملخص سريع

| المهمة | الحالة |
|-------|--------|
| جلب الإشعارات من API | ✅ |
| عرض الإشعارات | ✅ |
| وضع علامة كمقروء | ✅ |
| حذف الإشعارات | ✅ |
| عرض عدد غير المقروءة | ✅ |
| معالجة الأخطاء | ✅ |
| دعم Dark Mode | ✅ |

**الحالة: جاهز للإنتاج!** 🚀

---

**تاريخ الإنشاء**: 4 أبريل 2026  
**الإصدار**: 1.0.0  
**الحالة**: ✅ يعمل بكامل الطاقة

