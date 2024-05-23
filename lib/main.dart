import 'package:flutter/material.dart';
import 'package:mapa/components/auth_page.dart';
import 'package:firebase_core/firebase_core.dart';
import '../services/firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    name: "mapa",
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(home: AuthPage());
  }
}
