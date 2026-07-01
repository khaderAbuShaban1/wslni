# Ride-Hailing Starter

هيكل مشروع مبدئي لتطبيق توصيل ركاب:

- `backend/` = Laravel admin + API
- `apps/customer_app/` = تطبيق الكستمر Flutter
- `apps/driver_app/` = تطبيق السائق Flutter

## تشغيل الـ backend

```bash
cd backend
php artisan serve
```

## تشغيل تطبيق الكستمر

```bash
cd apps/customer_app
flutter run
```

## تشغيل تطبيق السائق

```bash
cd apps/driver_app
flutter run
```

## ما تم تجهيزه

- Admin dashboard أولي في Laravel
- API routes أساسية للـ auth والرحلات والسائقين والعملاء
- شاشتان Flutter عمليتان بدل شاشة العداد الافتراضية
- اختبارات Flutter محدثة للتأكد من تحميل الشاشات الجديدة

