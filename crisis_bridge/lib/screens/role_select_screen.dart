import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class RoleSelectScreen extends StatelessWidget {
  const RoleSelectScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                '◆ CRISIS BRIDGE ◆',
                style: theme.textTheme.titleLarge?.copyWith(fontSize: 24, letterSpacing: 4),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'EMERGENCY COORDINATION SYSTEM',
                style: theme.textTheme.bodySmall?.copyWith(letterSpacing: 2),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 64),
              _RoleCard(
                icon: Icons.shield_outlined,
                label: 'STAFF / RESPONDER',
                subtitle: 'Manage maps · Monitor incidents',
                onTap: () => context.go('/login?role=staff'),
              ),
              const SizedBox(height: 16),
              _RoleCard(
                icon: Icons.person_outline,
                label: 'OCCUPANT / GUEST',
                subtitle: 'Scan QR · Navigate to safety',
                onTap: () => context.go('/user/home'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final VoidCallback onTap;

  const _RoleCard({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Row(
            children: [
              Icon(icon, color: theme.colorScheme.primary, size: 36),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label, style: theme.textTheme.labelLarge?.copyWith(letterSpacing: 2)),
                    const SizedBox(height: 4),
                    Text(subtitle, style: theme.textTheme.bodySmall),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios, color: theme.colorScheme.primary, size: 16),
            ],
          ),
        ),
      ),
    );
  }
}