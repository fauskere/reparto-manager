import 'package:flutter/material.dart';
import 'core/theme.dart';
import 'core/app_config.dart';
import 'modules/shell/app_shell.dart';
import 'modules/clients/emergency_fix.dart';
import 'core/preferences_service.dart';
import 'modules/clients/fix_lapaz.dart';
import 'scripts/fix_db.dart';

import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options.dart';

import 'package:flutter_localizations/flutter_localizations.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    FirebaseFirestore.instance.settings = const Settings(persistenceEnabled: true);
  } catch (e) {
    print("Error inicializando Firebase: $e");
  }
  await PreferencesService().init();
  // Ejecutar reparaciones en segundo plano para no bloquear el inicio de la app sin internet
  Future.microtask(() async {
    print('Ejecutando script de arreglo de DB...');
    try {
      await runFix();
    } catch(e) {
      print('Error en runFix: $e');
    }
    
    print('Ejecutando reparacion de emergencia...');
    try {
      await EmergencyFix.run();
    } catch(e) {
      print('Error en EmergencyFix: $e');
    }
    
    if (PreferencesService().getBool('fix_lapaz_v6') != true) {
      try {
        await fixLaPazCentralV6();
        await PreferencesService().setBool('fix_lapaz_v6', true);
      } catch(e) {
        print('Error en lapaz fix v5: $e');
      }
    }
  });

  print('LLEGA A RUN APP'); runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConfig.appName,
      theme: AppTheme.darkTheme,
      debugShowCheckedModeBanner: false,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('es', 'ES'),
      ],
      home: AppShell(key: AppShell.globalKey),
    );
  }
}




