import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'providers/app_state.dart';
import 'screens/navigation_shell.dart';
import 'theme/nexora_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ProviderScope(child: NexoraApp()));
}

class NexoraApp extends ConsumerWidget {
  const NexoraApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp(
      title: 'NEXORA',
      debugShowCheckedModeBanner: false,
      theme: NexoraTheme.lightTheme,
      darkTheme: NexoraTheme.darkTheme,
      themeMode: themeMode,
      home: const NavigationShell(),
    );
  }
}
