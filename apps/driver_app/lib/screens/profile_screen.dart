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
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: Theme.of(context).colorScheme.outlineVariant,
            ),
            boxShadow: [
              BoxShadow(
                color: Theme.of(context).shadowColor.withValues(alpha: .11),
                blurRadius: 36,
                offset: const Offset(0, 16),
              ),
            ],
          ),
          child: Column(
            children: [
              CircleAvatar(
                radius: 40,
                backgroundColor: Theme.of(
                  context,
                ).colorScheme.primary.withValues(alpha: .15),
                child: Icon(
                  Icons.person,
                  size: 38,
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                user.name,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w900,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                user.email,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
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
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: ListTile(
        leading: CircleAvatar(
          radius: 25,
          backgroundColor: Theme.of(
            context,
          ).colorScheme.primary.withValues(alpha: .15),
          child: Icon(
            icon,
            color: Theme.of(context).colorScheme.primary,
            size: 25,
          ),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
        subtitle: Text(value),
      ),
    );
  }
}
