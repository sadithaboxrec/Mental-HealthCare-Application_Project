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
  useMaterial3: true,
  colorScheme: ColorScheme.fromSeed(
    seedColor: const Color.fromARGB(255, 176, 215, 247),
  ).copyWith(
    secondary: const Color.fromARGB(255, 152, 181, 231),
  ),
),
  home: HomeScreen(),

    ); 
  }
}
       
        

  
  

