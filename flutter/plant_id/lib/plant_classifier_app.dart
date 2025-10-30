import 'package:flutter/material.dart';
import 'home_page.dart';

class PlantClassifierApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Plant Classifier',
      theme: ThemeData(
        primarySwatch: Colors.green,
        scaffoldBackgroundColor: Color(0xFFF0FFF4),
      ),
      debugShowCheckedModeBanner: false,
      home: HomePage(),
    );
  }
}
