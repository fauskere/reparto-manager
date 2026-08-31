import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'core/design_system/design_system.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint('Firebase init: $e');
  }
  runApp(const RepartoManagerV2App());
}

class RepartoManagerV2App extends StatelessWidget {
  const RepartoManagerV2App({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: ThemeManager.instance,
      builder: (context, _) {
        return MaterialApp(
          title: 'Reparto Manager V2',
          debugShowCheckedModeBanner: false,
          theme: ThemeManager.instance.currentThemeData,
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [Locale('es', 'ES')],
          home: const DesignSystemShowroomView(),
        );
      },
    );
  }
}
