import 'package:flutter/material.dart';
import 'package:snapchess/home.dart';

void main() => runApp(new MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(brightness: Brightness.dark,
      primaryColor: Colors.teal),
      debugShowCheckedModeBanner: false,
      home: Home(),);
  }
}