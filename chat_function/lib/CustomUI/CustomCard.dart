import 'package:flutter/material.dart';
import 'package:chat_function/model/doctorchatmodel.dart';
import 'package:chat_function/page/individual_page.dart'; // ✅ correct import

class CustomCard extends StatelessWidget {
  const CustomCard({
    Key? key,
    required this.doctorchatmodel,
  }) : super(key: key);

  final Doctorchatmodel doctorchatmodel;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: () {   // 🔥 ADD THIS
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => IndividualPage(
              doctorchatmodel: doctorchatmodel,
            ),
          ),
        );
      },

      leading: CircleAvatar(
        radius: 30,
        backgroundImage: AssetImage(
          doctorchatmodel.icon,
        ),
      ),

      title: Text(
        doctorchatmodel.name,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),

      subtitle: Row(
        children: [
          const Icon(Icons.done_all, size: 16, color: Colors.blue),
          const SizedBox(width: 2),
          Text(
            doctorchatmodel.message,
            style: const TextStyle(fontSize: 14),
          ),
        ],
      ),

      trailing: Text(doctorchatmodel.time),
    );
  }
}