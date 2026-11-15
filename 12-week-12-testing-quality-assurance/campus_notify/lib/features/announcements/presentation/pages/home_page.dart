import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../auth/presentation/providers/auth_providers.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Campus Notify'),
        actions: const [_LogoutButton()],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: const Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _HomeHero(),
                SizedBox(height: 20),
                Text(
                  'Anda berhasil masuk',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
                ),
                SizedBox(height: 8),
                Text(
                  'Sesi autentikasi Anda sudah aktif.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16),
                ),
                SizedBox(height: 24),
                _HomeActions(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Widget statis: dibuat const agar tidak ikut rebuild saat parent berubah.
class _HomeHero extends StatelessWidget {
  const _HomeHero();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: 72,
      height: 72,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: scheme.primaryContainer,
        shape: BoxShape.circle,
      ),
      child: Icon(
        Icons.verified_user_outlined,
        size: 36,
        color: scheme.onPrimaryContainer,
      ),
    );
  }
}

class _HomeActions extends StatelessWidget {
  const _HomeActions();

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        _HomeActionButton(
          route: '/notes',
          icon: Icons.note_alt_outlined,
          label: 'Buka Fitur Catatan (Clean Architecture)',
        ),
        SizedBox(height: 12),
        _HomeActionButton(
          route: '/announcements',
          icon: Icons.campaign_outlined,
          label: 'Buka Pengumuman (Pagination + Cache)',
        ),
        SizedBox(height: 12),
        _HomeActionButton(
          route: '/ai-chat',
          icon: Icons.smart_toy_outlined,
          label: 'Buka Asisten Kampus AI',
        ),
      ],
    );
  }
}

class _HomeActionButton extends StatelessWidget {
  const _HomeActionButton({
    required this.route,
    required this.icon,
    required this.label,
  });

  final String route;
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: () => context.push(route),
      icon: Icon(icon),
      label: Text(label),
    );
  }
}

/// Hanya tombol logout yang butuh akses ke provider auth.
/// Dengan dipisah, HomePage dan konten statis lain tidak ikut rebuild.
class _LogoutButton extends ConsumerWidget {
  const _LogoutButton();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return IconButton(
      tooltip: 'Keluar',
      onPressed: () async {
        await ref.read(authStateProvider.notifier).logout();
        if (context.mounted) context.go('/login');
      },
      icon: const Icon(Icons.logout_rounded),
    );
  }
}
