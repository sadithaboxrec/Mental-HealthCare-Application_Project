import 'package:flutter/material.dart';
import 'package:chat_function/screens/homescreen.dart';


class DoctorChatPage extends StatefulWidget {
  const DoctorChatPage({Key? key}) : super(key: key);

  @override
  _DoctorChatPageState createState() => _DoctorChatPageState();
}


class _DoctorChatPageState extends State<DoctorChatPage> {
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