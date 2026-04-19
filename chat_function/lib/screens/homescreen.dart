import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:chat_function/page/doctor_chatpage.dart';
import 'package:chat_function/CustomUI/CustomCard.dart';


class HomeScreen extends StatefulWidget{
  HomeScreen({Key? key}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin{

  late TabController _controller;
  @override
  void initState() {
    super.initState();
    _controller = TabController(length: 2, vsync: this, initialIndex:0); 
  }

  @override   
  Widget build(BuildContext context) {
    return Scaffold(

      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.primary,
        title: Text('We Are Here For You',
        style: TextStyle(
          color:Colors.white,//change color to white
          fontWeight: FontWeight.bold,//bold text
        )),  
        actions: [
          IconButton(
            icon: Icon(
              Icons.search,
              color: Colors.white,
              ),
            onPressed: () {},
          ),
           //pop menu button with starred massagees, setting and logout options
          PopupMenuButton<String>(
            icon: Icon(
              Icons.more_vert,
              color: Colors.white,
            ),
            onSelected: (value) => print(value),

            itemBuilder: (BuildContext context) {
              return [
                PopupMenuItem<String>(
                  value: 'Starred Messages',
                  child: Text('Starred Messages'),
                ),
                PopupMenuItem<String>(
                  value: 'Settings',
                  child: Text('Settings'),
                  
                ),

                PopupMenuItem<String>(
                  value: 'Logout',
                  child: Text('Logout'),
                ),

              ];
            },
          ),
        ],

        bottom:TabBar(
          controller: _controller,
          
           labelColor: Colors.white,      
  unselectedLabelColor: Colors.white70, 
  indicatorColor: Colors.white, 
          tabs: [
            Tab(text: 'CHAT',),
            Tab(text: 'CALLS',),
          ],
        )
      ),
      body: TabBarView(
        controller: _controller,
        children: [
          DoctorChatPage(),
          Center(child: Text('Calls')),
        ],
      ),
    );
  }
}