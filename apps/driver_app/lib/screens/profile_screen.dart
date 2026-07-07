part of '../main.dart';

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
