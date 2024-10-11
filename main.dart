import 'package:flutter/material.dart';
import 'package:helloworld/conservationfile.dart';
import 'package:helloworld/correctionscree.dart';
import 'package:helloworld/mediapractic.dart';
import 'package:helloworld/oldconservation.dart';
import 'package:provider/provider.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ConversationProvider()),
      ],
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sivi English Tutor',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: DashboardScreen(),
    );
  }
}

// Dashboard Screen
class DashboardScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Image.network(
              'https://media.licdn.com/dms/image/v2/C560BAQF1ptqCSN7OAA/company-logo_200_200/company-logo_200_200/0/1671974253366/speakifyai_logo?e=2147483647&v=beta&t=JZXtLFKb9fh3woMUZlbLbL3fTqlSHFtPQxqhRqCxKm4',
              height: 40, // Adjust height of the logo
              width: 40, // Adjust width of the logo
            ),
            SizedBox(width: 10), // Space between logo and title
            Text(
              'Sivi', // Title of the app bar
              style: TextStyle(
                fontSize: 20, // Font size for the title
                fontWeight: FontWeight.bold, // Make the title bold
              ),
            ),
          ],
        ),
        backgroundColor: Colors.blueAccent, // App bar background color
      ),
      body: Column(
        children: [
          SizedBox(height: 30),
          Text(
            'Welcome to Sivi!',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 40),
          Text(
            'Improve your English by practicing conversations and getting speech corrections.',
            style: TextStyle(fontSize: 16),
          ),
          SizedBox(height: 40),
          ListTile(
            leading: Icon(Icons.add_circle),
            title: Text('Start New Conversation'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ConversationsScreen(),
                ),
              );
            },
          ),
          ListTile(
            leading: Icon(Icons.history),
            title: Text('View Old Conversations'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => OldConversationsScreen(),
                ),
              );
            },
          ),
          ListTile(
            leading: Icon(Icons.check_circle),
            title: Text('View Speech Corrections'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => CorrectionScreen(),
                ),
              );
            },
          ),
          ListTile(
            leading: Icon(Icons.video_library),
            title: Text('Media Practice (Image/Video)'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => MediaScreen(), // New Screen
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
