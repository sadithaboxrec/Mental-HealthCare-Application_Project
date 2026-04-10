import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:chat_function/model/doctorchatmodel.dart';

class IndividualPage extends StatefulWidget {
  final Doctorchatmodel doctorchatmodel;

  const IndividualPage({
    Key? key,
    required this.doctorchatmodel,
  }) : super(key: key);

  @override
  _IndividualPageState createState() => _IndividualPageState();
}

class _IndividualPageState extends State<IndividualPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 180, 235, 232),

      // 🔷 APP BAR
      appBar: AppBar(
        backgroundColor: Colors.lightBlue[100],

        leadingWidth: 80,
        leading: InkWell(
          onTap: () => Navigator.pop(context),
          child: Row(
            children: [
              const SizedBox(width: 5),
              const Icon(Icons.arrow_back, size: 24),
              const SizedBox(width: 5),
              CircleAvatar(
                radius: 18,
                backgroundImage:
                    AssetImage(widget.doctorchatmodel.icon),
              ),
            ],
          ),
        ),

        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.doctorchatmodel.name,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Text("online", style: TextStyle(fontSize: 12)),
          ],
        ),

        actions: [
          IconButton(
            icon: const Icon(Icons.call),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {},
          ),
          PopupMenuButton<String>(
            itemBuilder: (context) => const [
              PopupMenuItem(
                value: "media",
                child: Text("Media, links, docs"),
              ),
              PopupMenuItem(
                value: "theme",
                child: Text("Chat theme"),
              ),
            ],
          ),
        ],
      ),

      // 🔷 BODY
      body: Stack(
        children: [
          // Chat messages
          ListView(),

          // 🔻 MESSAGE INPUT BAR
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  // 🔥 TEXT FIELD AREA
                  Expanded(
                    child: Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                      child: TextFormField(
                        textAlignVertical: TextAlignVertical.center,
                        keyboardType: TextInputType.multiline,
                        maxLines: 5,
                        minLines: 1,

                        decoration: InputDecoration(
                          hintText: "Type a message",

                          // 😊 Emoji icon
                          prefixIcon: IconButton(
                            icon: const Icon(Icons.emoji_emotions),
                            onPressed: () {},
                          ),

                          // 📎 Attach + 🎤 mic
                          suffixIcon: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.attach_file),
                                onPressed: () {},
                              ),
                              IconButton(
                                icon: const Icon(Icons.mic),
                                onPressed: () {},
                              ),
                            ],
                          ),

                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 10,
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: 5),

                  // 🚀 SEND BUTTON
                  CircleAvatar(
                    radius: 25,
                    backgroundColor: Colors.lightBlue,
                    child: IconButton(
                      icon: const Icon(Icons.send, color: Colors.white),
                      onPressed: () {},
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}