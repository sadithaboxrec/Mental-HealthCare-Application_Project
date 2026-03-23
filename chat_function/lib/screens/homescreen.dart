import 'package:flutter/material.dart';

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
        title: Text('We are here for you'),  
        actions: [
          IconButton(
            icon: Icon(Icons.search),
            onPressed: () {},
          ),
          IconButton(
            icon: Icon(Icons.more_vert),
            onPressed: () {},
          ),
        ],

        bottom:TabBar(
          controller: _controller,
          tabs: [
            Tab(text: 'CHAT',),
            Tab(text: 'CALLS',),
          ],
        )
      ),
      
    );
  }
}