import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:flutter/material.dart';
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
  TextEditingController _controller = TextEditingController();
  bool showEmoji = false;
  FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();

    _focusNode.addListener(() {
      if (_focusNode.hasFocus) {
        setState(() {
          showEmoji = false;
        });
      }
    });
  }

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
        ],
      ),

      // 🔷 BODY
      body: Column(
        children: [
          Expanded(
            child: ListView(),
          ),

          // fix input area issue
          Row(
            children: [
              Expanded(
                child: Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                  margin: const EdgeInsets.all(8),
                  child: TextFormField(
                    controller: _controller,
                    focusNode: _focusNode,
                    textAlignVertical: TextAlignVertical.center,
                    keyboardType: TextInputType.multiline,
                    maxLines: 5,
                    minLines: 1,
                    decoration: InputDecoration(
                      hintText: "Type a message",

                      // 😊 EMOJI BUTTON
                      prefixIcon: IconButton(
                        icon: const Icon(Icons.emoji_emotions),
                        onPressed: () {
                          _focusNode.unfocus();
                          setState(() {
                            showEmoji = !showEmoji;
                          });
                        },
                      ),

                      // 📎 + 🎤
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

              //send botton
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: CircleAvatar(
                  radius: 25,
                  backgroundColor: Colors.lightBlue,
                  child: IconButton(
                    icon: const Icon(Icons.send, color: Colors.white),
                    onPressed: () {
                      print(_controller.text);
                      _controller.clear();
                    },
                  ),
                ),
              ),
            ],
          ),

          //emoji picker
          showEmoji ? emojiSelect() : Container(),
        ],
      ),
    );
  }

  Widget emojiSelect() {
    return SizedBox(
      height: 250,
      child: EmojiPicker(
        onEmojiSelected: (category, emoji) {
          _controller.text += emoji.emoji;
        },
        
        ),
      
    );
  
}
}