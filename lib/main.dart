import 'package:etwowconnect2/home.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

const title = 'E-Twow GT SE Unofficial App';

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: title,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.yellowAccent),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: title),
    );
  }
}


