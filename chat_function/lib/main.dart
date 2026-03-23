import 'package:flutter/material.dart';
import 'package:chat_function/screens/homescreen.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
  theme: ThemeData(
    primaryColor: const Color.fromARGB(255, 109, 167, 214),
    colorScheme: ColorScheme.fromSeed(
      seedColor: Colors.blue,
      secondary: Colors.blueAccent,
    ),
  ),
  home: HomeScreen(),

    ); //meterialApp
  }
}
       
        

  
  

