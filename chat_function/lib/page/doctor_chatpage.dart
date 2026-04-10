
import 'package:flutter/material.dart';
import 'package:chat_function/screens/homescreen.dart';//need to imort s this
import 'package:chat_function/CustomUI/CustomCard.dart';
import 'package:chat_function/model/doctorchatmodel.dart';  //need to imort s this

class DoctorChatPage extends StatefulWidget {
  const DoctorChatPage({Key? key}) : super(key: key);

  @override
  _DoctorChatPageState createState() => _DoctorChatPageState();
}


class _DoctorChatPageState extends State<DoctorChatPage> {
List<Doctorchatmodel> chats = [
  Doctorchatmodel(

    name:'Mr.Prabath Perera',
    icon: 'assets/siyana.avif',
    message: 'Hello',
    time: '10:30 AM',
    currentMessage: 'hi all',



  ),
  Doctorchatmodel(

    name:'Mr.Ramanayaka',
    icon: 'assets/siyana.avif',
    message: 'Hello',
    time: '10:30 AM',
    currentMessage: 'hi all',



  ),
  Doctorchatmodel(

    name:'Mr.Perera',
    icon: 'assets/siyana.avif',
    message: 'Hello',
    time: '10:30 AM',
    currentMessage: 'hi all',



  ),

];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        child: Icon(Icons.chat),
      ),
      body:ListView.builder(
        itemCount: chats.length,
        itemBuilder: (context, index)=> CustomCard(doctorchatmodel: chats[index]),
      ),
    );
  }
}