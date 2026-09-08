import 'package:flutter/material.dart';
import 'core/theme/app_theme.dart';
import 'features/navigation/main_navigation_shell.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const IeltsPrepApp());
}

class IeltsPrepApp extends StatelessWidget {
  const IeltsPrepApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'iils',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const MainNavigationShell(),
    );
  }
}
