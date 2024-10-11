// Old Conversations Screen
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:helloworld/conservationfile.dart';
import 'package:provider/provider.dart';

import 'main.dart';

class OldConversationsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final conversations = context.watch<ConversationProvider>().conversations;

    return Scaffold(
      appBar: AppBar(
        title: Text('Old Conversations'),
      ),
      body: ListView.builder(
        itemCount: conversations.length,
        itemBuilder: (context, index) {
          return ListTile(
            leading: Icon(Icons.chat_bubble),
            title: Text('Chat ${index + 1}'),
            subtitle: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start, // Aligns text to the start
              children: [
                Text(conversations[index]), // Original user text
                Text('Correct way to speak: ')
              ],
            ),
          );
        },
      ),
    );
  }
}
