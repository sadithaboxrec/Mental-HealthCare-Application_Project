//in this page only show user(patient) only bcz he/she have only one doctor or consultun
//only show big call and chat buttons with bottom back options

import 'package:flutter/material.dart';

class PatientChatPage extends StatelessWidget {
  const PatientChatPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Example doctor info
    String doctorName = "Dr. Samantha Perera";
    String doctorSpecialty = "Mental Health Consultant";

    return Scaffold(
      appBar: AppBar(
        title: Text("Your Doctor"),
        backgroundColor: Colors.teal,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Doctor info
            CircleAvatar(
              radius: 50,
              backgroundImage: AssetImage('assets/doctor_avatar.png'), // replace with doctor image
            ),
            SizedBox(height: 15),
            Text(
              doctorName,
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 5),
            Text(
              doctorSpecialty,
              style: TextStyle(fontSize: 16, color: Colors.grey[700]),
            ),
            SizedBox(height: 30),

            // Chat + Call buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  onPressed: () {
                    // Navigate to chat page
                    // Navigator.push(context, MaterialPageRoute(builder: (_) => DoctorChatPage()));
                  },
                  icon: Icon(Icons.chat),
                  label: Text("Chat"),
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(horizontal: 25, vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    // Call doctor function
                  },
                  icon: Icon(Icons.call),
                  label: Text("Call"),
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(horizontal: 25, vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ],
            ),

            SizedBox(height: 50),
            Divider(thickness: 1, color: Colors.grey[300]),
            SizedBox(height: 20),

            // Emergency call only button
            ElevatedButton.icon(
              onPressed: () {
                // Emergency call function
              },
              icon: Icon(Icons.warning, color: Colors.white),
              label: Text(
                "Emergency Call",
                style: TextStyle(color: Colors.white),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                padding: EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}