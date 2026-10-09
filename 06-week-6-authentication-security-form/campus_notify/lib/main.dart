import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

// Import Praktikum 1
import 'providers/auth_provider.dart';
import 'pages/login_page.dart';
import 'pages/home_page.dart';
import 'pages/announcement_page.dart';

// Import Praktikum 2 & 3
import 'messaging/push_service.dart';

final container = ProviderContainer();

// Konfigurasi Navigasi
final router = GoRouter(
  redirect: (context, state) {
    final loggedIn = container.read(authStateProvider).value ?? false;
    final goingLogin = state.matchedLocation == '/login';

    if (!loggedIn && !goingLogin) return '/login';
    if (loggedIn && goingLogin) return '/';
    return null;
  },
  routes: [
    GoRoute(path: '/login', builder: (_, _) => const LoginPage()),
    GoRoute(path: '/', builder: (_, _) => const HomePage()),
    GoRoute(
      path: '/pengumuman/:id',
      builder: (_, s) => AnnouncementPage(id: s.pathParameters['id'] ?? ''),
    ),
  ],
);

void main() async {
  // Syarat Wajib sebelum inisialisasi Firebase
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  // Daftarkan Background Handler (Praktikum 3)
  registerBackgroundHandler();

  // Inisialisasi Notifikasi (Praktikum 2)
  await requestNotificationPermission();
  await initLocalNotifications();

  // Ambil Token FCM (Praktikum 2)
  await initFcmToken(
    onToken: (token) async {
      debugPrint('FCM Token: $token');
    },
  );

  // Navigasi saat Notifikasi Diklik (Praktikum 3)
  listenForeground((route) => router.go(route));
  await handleTerminated((route) => router.go(route));

  // Jalankan Aplikasi
  runApp(UncontrolledProviderScope(container: container, child: const MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Campus Notify',
      debugShowCheckedModeBanner: false,
      routerConfig: router,
    );
  }
}
