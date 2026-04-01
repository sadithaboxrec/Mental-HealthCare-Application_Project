import 'package:flutter/material.dart';
import 'package:chat_function/screens/homescreen.dart';//need to imort s this
import 'package:chat_function/page/doctor_chatpage.dart';//need to imort s this

class CustomCard extends StatelessWidget {
 const CustomCard({Key? key}) : super(key: key);
  


  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        radius:30,
        backgroundImage: AssetImage('assets/siyana.avif'),
      ),
      title: Text('Dr. Siyana Perera', style:TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
      )),

      subtitle:
      Row(children: [
        Icon(Icons.done_all, size: 16, color: Colors.blue),
        SizedBox(width: 3),
        Text('Hello, how are you feeling today?',style: TextStyle(fontSize: 14),),
      ],),
      trailing: Text('10:30 AM' ),
      
    );
  }
}