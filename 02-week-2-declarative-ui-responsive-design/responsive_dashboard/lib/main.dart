import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

const double kWideBreakpoint = 700;

void main() => runApp(const AcademicApp());

class AcademicApp extends StatefulWidget {
  const AcademicApp({super.key});

  @override
  State<AcademicApp> createState() => _AcademicAppState();
}

class _AcademicAppState extends State<AcademicApp> {
  bool isDark = false;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,

      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.indigo,
        brightness: Brightness.light,
      ),

      darkTheme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.indigo,
        brightness: Brightness.dark,
      ),

      themeMode: isDark ? ThemeMode.dark : ThemeMode.light,

      home: AcademicOverviewPage(
        isDark: isDark,
        onDarkChanged: (value) {
          setState(() {
            isDark = value;
          });
        },
      ),
    );
  }
}

class AcademicOverviewPage extends StatelessWidget {
  const AcademicOverviewPage({
    required this.isDark,
    required this.onDarkChanged,
    super.key,
  });

  final bool isDark;
  final ValueChanged<bool> onDarkChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final columns =
                constraints.maxWidth >= kWideBreakpoint ? 2 : 1;

            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),

              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // HEADER
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Academic Overview',
                          style: theme.textTheme.titleLarge,
                        ),
                      ),

                      Semantics(
                        label: isDark
                            ? 'Dark mode aktif'
                            : 'Light mode aktif',
                        child: Icon(
                          isDark
                              ? Icons.dark_mode
                              : Icons.light_mode,
                          color: colorScheme.onSurface,
                        ),
                      ),

                      const SizedBox(width: 6),

                      Semantics(
                        label: 'Tombol untuk mengubah tema',
                        child: CupertinoSwitch(
                          value: isDark,
                          onChanged: onDarkChanged,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 18),

                  // PROFILE
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),

                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(14),
                    ),

                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 28,
                          backgroundColor:
                              colorScheme.primaryContainer,
                          child: Icon(
                            Icons.person,
                            color: colorScheme.onPrimaryContainer,
                          ),
                        ),

                        const SizedBox(width: 16),

                        Expanded(
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Student Profile',
                                style: theme.textTheme.headlineSmall
                                    ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),

                              const SizedBox(height: 4),

                              Text(
                                'Nama: Muhammad Rayhan Zamzami',
                                style: theme.textTheme.bodyMedium,
                              ),

                              Text(
                                'NIM: 244107020027',
                                style: theme.textTheme.bodyMedium,
                              ),

                              Text(
                                'Teknik Informatika',
                                style: theme.textTheme.bodyMedium,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 14),

                  // INFORMATION CARDS
                  GridView.count(
                    crossAxisCount: columns,
                    crossAxisSpacing: 14,
                    mainAxisSpacing: 14,
                    childAspectRatio: 2.4,
                    shrinkWrap: true,
                    physics:
                        const NeverScrollableScrollPhysics(),

                    children: const [
                      InfoCard(
                        title: 'Assignments',
                        value: '8',
                      ),
                      InfoCard(
                        title: 'Attendance',
                        value: '92%',
                      ),
                      InfoCard(
                        title: 'Portfolio',
                        value: 'Ready',
                      ),
                      InfoCard(
                        title: 'Current Week',
                        value: '02',
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

// REUSABLE WIDGET
class InfoCard extends StatelessWidget {
  const InfoCard({
    required this.title,
    required this.value,
    super.key,
  });

  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Semantics(
      label: '$title: $value',

      child: Card(
        elevation: 0,

        child: Padding(
          padding: const EdgeInsets.all(16),

          child: Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: theme.textTheme.bodyMedium,
                ),
              ),

              Text(
                value,
                style: theme.textTheme.headlineSmall,
              ),
            ],
          ),
        ),
      ),
    );
  }
}