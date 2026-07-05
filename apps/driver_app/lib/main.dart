import 'dart:convert';
import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

const _emerald = Color(0xFF10B981);
const _dark = Color(0xFF1F2937);
const _muted = Color(0xFF6B7280);
const _light = Color(0xFFF3F4F6);
const _line = Color(0xFFE5E7EB);

void main() {
  runApp(const DriverRideApp());
}

class DriverRideApp extends StatelessWidget {
  const DriverRideApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'وصلني للسائق',
      locale: const Locale('ar'),
      supportedLocales: const [Locale('ar')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      builder: (context, child) => Directionality(
        textDirection: TextDirection.rtl,
        child: child ?? const SizedBox.shrink(),
      ),
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: _emerald,
        scaffoldBackgroundColor: Colors.white,
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: _light,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 18,
            vertical: 16,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: const BorderSide(color: _emerald, width: 1.4),
          ),
        ),
      ),
      home: const AuthPage(),
    );
  }
}

class ApiClient {
  ApiClient({String? baseUrl})
    : baseUrl = baseUrl ?? 'http://127.0.0.1:8000/api';

  final String baseUrl;

  Future<Map<String, dynamic>> post(
    String path,
    Map<String, dynamic> body,
  ) async {
    final client = HttpClient();
    final request = await client.postUrl(Uri.parse('$baseUrl/$path'));
    request.headers.contentType = ContentType.json;
    request.headers.set(HttpHeaders.acceptHeader, 'application/json');
    request.write(jsonEncode(body));
    final response = await request.close();
    final text = await response.transform(utf8.decoder).join();
    client.close();
    final decoded = _decode(text);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiException(_message(decoded), response.statusCode, decoded);
    }

    return decoded;
  }

  Future<List<dynamic>> getList(String path) async {
    final client = HttpClient();
    final request = await client.getUrl(Uri.parse('$baseUrl/$path'));
    request.headers.set(HttpHeaders.acceptHeader, 'application/json');
    final response = await request.close();
    final text = await response.transform(utf8.decoder).join();
    client.close();

    final decoded = jsonDecode(text);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiException('تعذر تحميل البيانات.', response.statusCode, {});
    }
    if (decoded is List) return decoded;
    return [];
  }

  Map<String, dynamic> _decode(String text) {
    if (text.isEmpty) return {};
    try {
      final decoded = jsonDecode(text);
      if (decoded is Map<String, dynamic>) return decoded;
    } catch (_) {
      return {'message': 'وصل رد غير متوقع من الخادم.'};
    }
    return {'message': 'وصل رد غير متوقع من الخادم.'};
  }

  String _message(Map<String, dynamic> decoded) {
    final errors = decoded['errors'];
    if (errors is Map && errors.isNotEmpty) {
      final first = errors.values.first;
      if (first is List && first.isNotEmpty) return first.first.toString();
    }
    return decoded['message']?.toString() ?? 'حدث خطأ غير متوقع.';
  }
}

class ApiException implements Exception {
  ApiException(this.message, this.statusCode, this.body);

  final String message;
  final int statusCode;
  final Map<String, dynamic> body;
}

class DriverUser {
  const DriverUser({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.vehicleType,
    required this.vehiclePlate,
  });

  final int id;
  final String name;
  final String email;
  final String phone;
  final String vehicleType;
  final String vehiclePlate;

  factory DriverUser.fromJson(Map<String, dynamic> json) {
    final profile = json['driver_profile'];
    final profileMap = profile is Map ? profile : {};
    return DriverUser(
      id: int.tryParse(json['id']?.toString() ?? '') ?? 0,
      name: json['name']?.toString() ?? 'سائق',
      email: json['email']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
      vehicleType: profileMap['vehicle_type']?.toString() ?? '',
      vehiclePlate: profileMap['vehicle_plate']?.toString() ?? '',
    );
  }
}

class RideRequestItem {
  RideRequestItem({
    required this.id,
    required this.pickup,
    required this.dropoff,
    required this.customerName,
    required this.notes,
  });

  final int id;
  final String pickup;
  final String dropoff;
  final String customerName;
  final String notes;

  factory RideRequestItem.fromJson(Map<String, dynamic> json) {
    final customer = json['customer'];
    final customerMap = customer is Map ? customer : {};
    return RideRequestItem(
      id: int.tryParse(json['id']?.toString() ?? '') ?? 0,
      pickup: json['pickup_address']?.toString() ?? '',
      dropoff: json['dropoff_address']?.toString() ?? '',
      customerName: customerMap['name']?.toString() ?? 'زبون',
      notes: json['notes']?.toString() ?? '',
    );
  }
}

class AuthPage extends StatefulWidget {
  const AuthPage({super.key});

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  final _api = ApiClient();
  final _loginKey = GlobalKey<FormState>();
  final _registerKey = GlobalKey<FormState>();
  final _otpKey = GlobalKey<FormState>();

  final _loginEmail = TextEditingController();
  final _loginPassword = TextEditingController();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _password = TextEditingController();
  final _confirmPassword = TextEditingController();
  final _license = TextEditingController();
  final _vehicleType = TextEditingController();
  final _vehiclePlate = TextEditingController();
  final _otp = TextEditingController();

  bool _register = false;
  bool _otpMode = false;
  bool _loading = false;
  String? _pendingEmail;

  @override
  void dispose() {
    _loginEmail.dispose();
    _loginPassword.dispose();
    _name.dispose();
    _email.dispose();
    _phone.dispose();
    _password.dispose();
    _confirmPassword.dispose();
    _license.dispose();
    _vehicleType.dispose();
    _vehiclePlate.dispose();
    _otp.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_loginKey.currentState!.validate()) return;
    await _run(() async {
      final result = await _api.post('auth/login', {
        'email': _loginEmail.text.trim(),
        'password': _loginPassword.text,
      });
      final user = DriverUser.fromJson(result['user'] as Map<String, dynamic>);
      if (user.id == 0) throw ApiException('بيانات السائق غير صحيحة.', 422, {});
      _openHome(user);
    });
  }

  Future<void> _registerDriver() async {
    if (!_registerKey.currentState!.validate()) return;
    await _run(() async {
      await _api.post('auth/driver/register', {
        'name': _name.text.trim(),
        'email': _email.text.trim(),
        'phone': _phone.text.trim(),
        'password': _password.text,
        'password_confirmation': _confirmPassword.text,
        'license_number': _license.text.trim(),
        'vehicle_type': _vehicleType.text.trim(),
        'vehicle_plate': _vehiclePlate.text.trim(),
      });
      setState(() {
        _pendingEmail = _email.text.trim();
        _otpMode = true;
      });
      _show('تم إرسال رمز التحقق إلى البريد الإلكتروني');
    });
  }

  Future<void> _verifyOtp() async {
    if (!_otpKey.currentState!.validate()) return;
    await _run(() async {
      final result = await _api.post('auth/verify-otp', {
        'email': _pendingEmail,
        'otp': _otp.text.trim(),
      });
      _openHome(DriverUser.fromJson(result['user'] as Map<String, dynamic>));
    });
  }

  Future<void> _run(Future<void> Function() action) async {
    setState(() => _loading = true);
    try {
      await action();
    } on ApiException catch (error) {
      if (error.statusCode == 403 && error.body['requires_otp'] == true) {
        setState(() {
          _pendingEmail = error.body['email']?.toString() ?? _loginEmail.text;
          _otpMode = true;
          _register = false;
        });
      }
      _show(error.message);
    } on SocketException {
      _show('تعذر الاتصال بالخادم. تأكد أن Laravel يعمل على المنفذ 8000.');
    } catch (_) {
      _show('حدث خطأ غير متوقع.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _openHome(DriverUser user) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => DriverHomePage(user: user)),
    );
  }

  void _show(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const SizedBox(height: 20),
            const Icon(Icons.local_taxi, size: 56),
            const SizedBox(height: 12),
            Text(
              _otpMode
                  ? 'تحقق من البريد'
                  : _register
                  ? 'إنشاء حساب سائق'
                  : 'تسجيل دخول السائق',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 24),
            if (_otpMode)
              _OtpForm(
                formKey: _otpKey,
                email: _pendingEmail ?? '',
                otp: _otp,
                loading: _loading,
                onVerify: _verifyOtp,
                onBack: () => setState(() => _otpMode = false),
              )
            else if (_register)
              _RegisterForm(
                formKey: _registerKey,
                name: _name,
                email: _email,
                phone: _phone,
                password: _password,
                confirmPassword: _confirmPassword,
                license: _license,
                vehicleType: _vehicleType,
                vehiclePlate: _vehiclePlate,
                loading: _loading,
                onSubmit: _registerDriver,
              )
            else
              _LoginForm(
                formKey: _loginKey,
                email: _loginEmail,
                password: _loginPassword,
                loading: _loading,
                onSubmit: _login,
              ),
            const SizedBox(height: 12),
            if (!_otpMode)
              TextButton(
                onPressed: _loading
                    ? null
                    : () => setState(() => _register = !_register),
                child: Text(
                  _register
                      ? 'عندك حساب؟ تسجيل الدخول'
                      : 'ما عندك حساب؟ إنشاء حساب جديد',
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _LoginForm extends StatelessWidget {
  const _LoginForm({
    required this.formKey,
    required this.email,
    required this.password,
    required this.loading,
    required this.onSubmit,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController email;
  final TextEditingController password;
  final bool loading;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: Column(
        children: [
          _Field(
            controller: email,
            label: 'البريد الإلكتروني',
            icon: Icons.email_outlined,
          ),
          const SizedBox(height: 12),
          _Field(
            controller: password,
            label: 'كلمة المرور',
            icon: Icons.lock_outline,
            obscure: true,
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: loading ? null : onSubmit,
            icon: const Icon(Icons.login),
            label: const Text('تسجيل الدخول'),
          ),
        ],
      ),
    );
  }
}

class _RegisterForm extends StatelessWidget {
  const _RegisterForm({
    required this.formKey,
    required this.name,
    required this.email,
    required this.phone,
    required this.password,
    required this.confirmPassword,
    required this.license,
    required this.vehicleType,
    required this.vehiclePlate,
    required this.loading,
    required this.onSubmit,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController name;
  final TextEditingController email;
  final TextEditingController phone;
  final TextEditingController password;
  final TextEditingController confirmPassword;
  final TextEditingController license;
  final TextEditingController vehicleType;
  final TextEditingController vehiclePlate;
  final bool loading;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: Column(
        children: [
          _Field(
            controller: name,
            label: 'الاسم الكامل',
            icon: Icons.person_outline,
          ),
          const SizedBox(height: 10),
          _Field(
            controller: email,
            label: 'البريد الإلكتروني',
            icon: Icons.email_outlined,
          ),
          const SizedBox(height: 10),
          _Field(
            controller: phone,
            label: 'رقم الجوال',
            icon: Icons.phone_outlined,
          ),
          const SizedBox(height: 10),
          _Field(
            controller: license,
            label: 'رقم الرخصة',
            icon: Icons.badge_outlined,
          ),
          const SizedBox(height: 10),
          _Field(
            controller: vehicleType,
            label: 'نوع السيارة',
            icon: Icons.directions_car_outlined,
          ),
          const SizedBox(height: 10),
          _Field(
            controller: vehiclePlate,
            label: 'رقم السيارة',
            icon: Icons.pin_outlined,
          ),
          const SizedBox(height: 10),
          _Field(
            controller: password,
            label: 'كلمة المرور',
            icon: Icons.lock_outline,
            obscure: true,
          ),
          const SizedBox(height: 10),
          _Field(
            controller: confirmPassword,
            label: 'تأكيد كلمة المرور',
            icon: Icons.lock_reset,
            obscure: true,
            validator: (value) {
              if (value != password.text) return 'كلمتا المرور غير متطابقتين';
              return _required(value);
            },
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: loading ? null : onSubmit,
            icon: const Icon(Icons.person_add_alt_1),
            label: const Text('إنشاء حساب سائق'),
          ),
        ],
      ),
    );
  }
}

class _OtpForm extends StatelessWidget {
  const _OtpForm({
    required this.formKey,
    required this.email,
    required this.otp,
    required this.loading,
    required this.onVerify,
    required this.onBack,
  });

  final GlobalKey<FormState> formKey;
  final String email;
  final TextEditingController otp;
  final bool loading;
  final VoidCallback onVerify;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: Column(
        children: [
          Text('تم إرسال الرمز إلى $email'),
          const SizedBox(height: 12),
          _Field(
            controller: otp,
            label: 'رمز التحقق',
            icon: Icons.verified_outlined,
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: loading ? null : onVerify,
            icon: const Icon(Icons.check),
            label: const Text('تحقق'),
          ),
          TextButton(
            onPressed: loading ? null : onBack,
            child: const Text('رجوع'),
          ),
        ],
      ),
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({
    required this.controller,
    required this.label,
    required this.icon,
    this.obscure = false,
    this.validator,
  });

  final TextEditingController controller;
  final String label;
  final IconData icon;
  final bool obscure;
  final String? Function(String?)? validator;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      decoration: InputDecoration(prefixIcon: Icon(icon), labelText: label),
      validator: validator ?? _required,
    );
  }
}

String? _required(String? value) {
  if (value == null || value.trim().isEmpty) return 'هذا الحقل مطلوب';
  return null;
}

class DriverHomePage extends StatefulWidget {
  const DriverHomePage({required this.user, super.key});

  final DriverUser user;

  @override
  State<DriverHomePage> createState() => _DriverHomePageState();
}

class _DriverHomePageState extends State<DriverHomePage> {
  int _index = 0;
  bool _online = true;

  late final List<Widget> _pages = [
    RequestsPage(user: widget.user),
    const _TripsPage(),
    const _EarningsPage(),
    _DriverProfilePage(user: widget.user),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('وصلني للسائق'),
        actions: [
          Row(
            children: [
              Text(_online ? 'متصل' : 'غير متصل'),
              Switch(
                value: _online,
                onChanged: (value) => setState(() => _online = value),
              ),
            ],
          ),
        ],
      ),
      body: _pages[_index],
      bottomNavigationBar: DecoratedBox(
        decoration: const BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Color(0x14000000),
              blurRadius: 24,
              offset: Offset(0, -8),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: BottomNavigationBar(
            currentIndex: _index,
            onTap: (value) => setState(() => _index = value),
            type: BottomNavigationBarType.fixed,
            backgroundColor: Colors.white,
            selectedItemColor: _emerald,
            unselectedItemColor: _muted,
            selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w900),
            unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w700),
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.local_taxi_outlined),
                activeIcon: Icon(Icons.local_taxi),
                label: 'الطلبات',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.route_outlined),
                activeIcon: Icon(Icons.route),
                label: 'رحلاتي',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.payments_outlined),
                activeIcon: Icon(Icons.payments),
                label: 'الأرباح',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.person_outline),
                activeIcon: Icon(Icons.person),
                label: 'الحساب',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class RequestsPage extends StatefulWidget {
  const RequestsPage({required this.user, super.key});

  final DriverUser user;

  @override
  State<RequestsPage> createState() => _RequestsPageState();
}

class _RequestsPageState extends State<RequestsPage> {
  final _api = ApiClient();
  late Future<List<RideRequestItem>> _future;
  Timer? _pollTimer;
  List<RideRequestItem> _lastRides = const [];

  @override
  void initState() {
    super.initState();
    _future = _load();
    _pollTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (mounted) _refresh(silent: true);
    });
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  Future<List<RideRequestItem>> _load() async {
    final rows = await _api.getList('rides');
    final rides = rows
        .whereType<Map<String, dynamic>>()
        .map(RideRequestItem.fromJson)
        .toList();
    _lastRides = rides;
    return rides;
  }

  void _refresh({bool silent = false}) {
    setState(() => _future = _load());
    if (!silent) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('جاري تحديث الطلبات...')));
    }
  }

  Future<void> _sendOffer(
    RideRequestItem ride,
    String price,
    String notes,
  ) async {
    if (price.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('اكتب سعر العرض أولًا')));
      return;
    }
    await _api.post('rides/${ride.id}/offers', {
      'driver_id': widget.user.id,
      'price': price,
      'notes': notes.isEmpty ? null : notes,
    });
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('تم إرسال عرضك للزبون')));
    _refresh();
  }

  void _openOfferSheet(RideRequestItem ride) {
    final price = TextEditingController();
    final notes = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Container(
        padding: EdgeInsets.fromLTRB(
          18,
          18,
          18,
          MediaQuery.of(context).viewInsets.bottom + 18,
        ),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'قدّم عرض سعر',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w900,
                color: _dark,
              ),
            ),
            const SizedBox(height: 12),
            _RouteSummaryBox(ride: ride),
            const SizedBox(height: 12),
            TextField(
              controller: price,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.payments_outlined),
                labelText: 'السعر',
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: notes,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.notes),
                labelText: 'ملاحظات اختيارية',
              ),
            ),
            const SizedBox(height: 14),
            FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: _emerald,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 56),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
              onPressed: () async {
                await _sendOffer(ride, price.text.trim(), notes.text.trim());
                if (context.mounted) Navigator.pop(context);
              },
              icon: const Icon(Icons.send),
              label: const Text('إرسال العرض'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<RideRequestItem>>(
      future: _future,
      initialData: _lastRides,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting &&
            _lastRides.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: TextButton.icon(
              onPressed: () => _refresh(),
              icon: const Icon(Icons.refresh),
              label: const Text('تعذر تحميل الطلبات، حاول مرة أخرى'),
            ),
          );
        }

        final rides = snapshot.data ?? [];
        if (rides.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: _EmptyStateCard(
                icon: Icons.local_taxi_outlined,
                title: 'لا توجد طلبات حاليًا',
                message: 'عندما يرسل الزبائن طلبات جديدة ستظهر هنا.',
                actionLabel: 'تحديث',
                onAction: () => _refresh(),
              ),
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async => _refresh(silent: true),
          child: ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: rides.length + 1,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              if (index == 0) {
                return Row(
                  children: [
                    Expanded(
                      child: Text(
                        'طلبات الزبائن',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w900,
                          color: _dark,
                        ),
                      ),
                    ),
                    IconButton.filledTonal(
                      tooltip: 'تحديث',
                      onPressed: () => _refresh(),
                      icon: const Icon(Icons.refresh),
                    ),
                  ],
                );
              }
              final ride = rides[index - 1];
              return _RideRequestCard(
                ride: ride,
                onOffer: () => _openOfferSheet(ride),
              );
            },
          ),
        );
      },
    );
  }
}

class _TripsPage extends StatelessWidget {
  const _TripsPage();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(20),
        child: _EmptyStateCard(
          icon: Icons.route_outlined,
          title: 'لا توجد رحلات بعد',
          message: 'الرحلات المقبولة ستظهر هنا.',
        ),
      ),
    );
  }
}

class _EarningsPage extends StatelessWidget {
  const _EarningsPage();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(20),
        child: _EmptyStateCard(
          icon: Icons.payments_outlined,
          title: 'لا توجد أرباح بعد',
          message: 'بعد إكمال الرحلات ستظهر أرباحك هنا.',
        ),
      ),
    );
  }
}

class _RideRequestCard extends StatelessWidget {
  const _RideRequestCard({required this.ride, required this.onOffer});

  final RideRequestItem ride;
  final VoidCallback onOffer;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _line),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F111827),
            blurRadius: 24,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const CircleAvatar(
                radius: 26,
                backgroundColor: Color(0xFFD1FAE5),
                child: Icon(Icons.person, color: _emerald),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      ride.customerName,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                        color: _dark,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'طلب رحلة جديد',
                      style: TextStyle(color: _muted),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _RouteSummaryBox(ride: ride),
          if (ride.notes.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              'ملاحظات: ${ride.notes}',
              style: const TextStyle(color: _muted),
            ),
          ],
          const SizedBox(height: 14),
          FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: _emerald,
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 54),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
            ),
            onPressed: onOffer,
            icon: const Icon(Icons.local_offer_outlined),
            label: const Text(
              'قدّم عرض سعر',
              style: TextStyle(fontWeight: FontWeight.w900),
            ),
          ),
        ],
      ),
    );
  }
}

class _RouteSummaryBox extends StatelessWidget {
  const _RouteSummaryBox({required this.ride});

  final RideRequestItem ride;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _light,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          _RouteLine(label: 'من', value: ride.pickup, icon: Icons.my_location),
          const Divider(height: 22),
          _RouteLine(
            label: 'إلى',
            value: ride.dropoff,
            icon: Icons.place_outlined,
          ),
        ],
      ),
    );
  }
}

class _RouteLine extends StatelessWidget {
  const _RouteLine({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: _emerald),
        const SizedBox(width: 8),
        Text('$label: ', style: const TextStyle(color: _muted)),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w900, color: _dark),
          ),
        ),
      ],
    );
  }
}

class _EmptyStateCard extends StatelessWidget {
  const _EmptyStateCard({
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _line),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            radius: 34,
            backgroundColor: _light,
            child: Icon(icon, color: _emerald, size: 30),
          ),
          const SizedBox(height: 14),
          Text(
            title,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w900,
              color: _dark,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: _muted, height: 1.5),
          ),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: 14),
            OutlinedButton.icon(
              onPressed: onAction,
              icon: const Icon(Icons.refresh),
              label: Text(actionLabel!),
            ),
          ],
        ],
      ),
    );
  }
}

class _DriverProfilePage extends StatelessWidget {
  const _DriverProfilePage({required this.user});

  final DriverUser user;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _line),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0F111827),
                blurRadius: 24,
                offset: Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            children: [
              const CircleAvatar(
                radius: 40,
                backgroundColor: Color(0xFFD1FAE5),
                child: Icon(Icons.person, size: 38, color: _emerald),
              ),
              const SizedBox(height: 12),
              Text(
                user.name,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w900,
                  color: _dark,
                ),
              ),
              const SizedBox(height: 4),
              Text(user.email, style: const TextStyle(color: _muted)),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _ProfileInfoTile(icon: Icons.phone, title: 'الجوال', value: user.phone),
        _ProfileInfoTile(
          icon: Icons.directions_car,
          title: 'السيارة',
          value: user.vehicleType.isEmpty ? 'غير مضاف' : user.vehicleType,
        ),
        _ProfileInfoTile(
          icon: Icons.pin,
          title: 'رقم السيارة',
          value: user.vehiclePlate.isEmpty ? 'غير مضاف' : user.vehiclePlate,
        ),
      ],
    );
  }
}

class _ProfileInfoTile extends StatelessWidget {
  const _ProfileInfoTile({
    required this.icon,
    required this.title,
    required this.value,
  });

  final IconData icon;
  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _line),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _light,
          child: Icon(icon, color: _dark),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
        subtitle: Text(value),
      ),
    );
  }
}
