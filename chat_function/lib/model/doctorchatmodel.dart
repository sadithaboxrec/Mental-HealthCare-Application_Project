import 'package:flutter/material.dart';
import 'package:chat_function/page/individual_page.dart';//need to imort s this

class Doctorchatmodel {

  String name;
  String icon;
  String message;
  String time;
  String currentMessage;

  Doctorchatmodel(
    {
      required this.name,
      required this.icon,
      required this.message,
      required this.time,
      required this.currentMessage
    }
  );


}
