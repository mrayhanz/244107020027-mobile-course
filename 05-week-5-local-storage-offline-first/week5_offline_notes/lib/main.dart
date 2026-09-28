import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'pages/notes_page.dart';
import 'pages/setting_page.dart';
import 'dart:io';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
    if (Platform.isWindows || Platform.isLinux) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Membaca status tema dari provider yang sudah Anda buat
    final isDarkMode = ref.watch(darkModeProvider).value ?? false;

    return MaterialApp(
      title: 'Offline Notes',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.light(useMaterial3: true),
      darkTheme: ThemeData.dark(useMaterial3: true),
      themeMode: isDarkMode ? ThemeMode.dark : ThemeMode.light,
      home: const NotesPage(),
    );
  }
}