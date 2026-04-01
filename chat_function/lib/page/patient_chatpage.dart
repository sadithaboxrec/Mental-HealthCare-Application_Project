import 'package:flutter/material.dart';
import 'package:chat_function/screens/homescreen.dart';//need to imort s this


class PatientChatpage extends StatefulWidget {
  const PatientChatpage({Key? key}) : super(key: key);

  @override
  _PatientChatpageState createState() => _PatientChatpageState();
}


class _PatientChatpageState extends State<PatientChatpage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        child: Icon(Icons.chat),
      ),
    );
  }
}