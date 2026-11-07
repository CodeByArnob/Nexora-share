import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'providers/app_state.dart';
import 'screens/desktop_shell.dart';
import 'theme/nexora_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ProviderScope(child: NexoraDesktopApp()));
}

class NexoraDesktopApp extends ConsumerWidget {
  const NexoraDesktopApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp(
      title: 'NEXORA',
      debugShowCheckedModeBanner: false,
      theme: NexoraTheme.lightTheme,
      darkTheme: NexoraTheme.darkTheme,
      themeMode: themeMode,
      home: const DesktopShell(),
    );
  }
}
