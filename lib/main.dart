import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'home_page.dart';

Future main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
      options: const FirebaseOptions(
    apiKey: "AIzaSyCcWS60wqVJaqo2s8bkR7BUTAGamNqsoLg",
    authDomain: "snakegame-6c461.firebaseapp.com",
    projectId: "snakegame-6c461",
    storageBucket: "snakegame-6c461.appspot.com",
    messagingSenderId: "622425222870",
    appId: "1:622425222870:web:916406656a7ee87ad2e377",
    measurementId: "G-LSPCK08V9R",
  ));
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: const HomePage(),
      theme: ThemeData(brightness: Brightness.dark),
    );
  }
}
