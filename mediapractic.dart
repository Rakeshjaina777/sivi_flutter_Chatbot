import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'dart:async';

class MediaScreen extends StatefulWidget {
  @override
  _MediaScreenState createState() => _MediaScreenState();
}

class _MediaScreenState extends State<MediaScreen> {
  bool _isVideo = false; // Set to false to show only the image

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Describe the Media')),
      body: Column(
        children: [
          FadeInImage.assetNetwork(
            placeholder: 'assets/placeholder.png', // Placeholder image
            image:
                'https://i.pinimg.com/736x/18/24/57/182457d5e52ee13d44f78729f05b75b6.jpg',
            height: 200,
            width: double.infinity,
            fit: BoxFit.cover,
            fadeInDuration: Duration(milliseconds: 300),
          ),
          SizedBox(height: 20),
          Text(
            'Please describe what you see for 2 minutes:',
            style: TextStyle(fontSize: 16),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {
              // Navigate to conversation screen where speech recognition happens
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ConversationScreen(isVideo: _isVideo),
                ),
              );
            },
            child: Text('Start Speaking'),
          ),
        ],
      ),
    );
  }
}

void main() => runApp(MaterialApp(home: MediaScreen()));

class ConversationScreen extends StatefulWidget {
  final bool isVideo; // To pass whether media was video or image

  ConversationScreen({required this.isVideo});

  @override
  _ConversationScreenState createState() => _ConversationScreenState();
}

class _ConversationScreenState extends State<ConversationScreen> {
  stt.SpeechToText _speech = stt.SpeechToText();
  bool _isListening = false;
  bool _hasSentMessage = false; // To ensure message is sent only once
  String _userSpeech = '';
  TextEditingController _textController = TextEditingController();
  List<String> _messageHistory = [];
  ScrollController _scrollController = ScrollController();
  Timer? _silenceTimer;

  @override
  void initState() {
    super.initState();
    _addMediaPrompt();
  }

  void _addMediaPrompt() {
    // Add a message asking user to describe the media
    _messageHistory.add(widget.isVideo
        ? "Bot: Please describe the video you just saw."
        : "Bot: Please describe the image you just saw.");
    setState(() {});
  }

  void _startListening() async {
    bool available = await _speech.initialize();
    if (available && !_hasSentMessage) {
      setState(() {
        _isListening = true;
        _userSpeech = ''; // Reset speech
      });
      _speech.listen(onResult: (result) {
        setState(() {
          _userSpeech = result.recognizedWords; // Update speech
        });
        _resetSilenceTimer(); // Reset timer for detecting silence
      });
    }
  }

  void _stopListening() {
    _speech.stop();
    _silenceTimer?.cancel();
    setState(() {
      _isListening = false;
    });

    if (_userSpeech.isNotEmpty && !_hasSentMessage) {
      _sendMessage();
    }
  }

  void _resetSilenceTimer() {
    _silenceTimer?.cancel();
    _silenceTimer = Timer(Duration(seconds: 2), () {
      _stopListening(); // Stop listening after 2 seconds of silence
    });
  }

  void _sendMessage() {
    // Add the user's speech or typed text to message history
    if ((_userSpeech.isNotEmpty || _textController.text.isNotEmpty) &&
        !_hasSentMessage) {
      String userInput = _userSpeech.isNotEmpty
          ? _userSpeech
          : _textController.text; // Prioritize speech over text
      _messageHistory.add("User: $userInput");
      _messageHistory.add("Bot: Here's a better way to describe it...");
      _messageHistory.add("Bot: This is a vibrant logo with colors X and Y.");
      _scrollToBottom();
      _hasSentMessage =
          true; // Message has been sent, no further inputs allowed
      setState(() {});
    }
  }

  void _scrollToBottom() {
    Future.delayed(Duration(milliseconds: 100), () {
      _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Chat'),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              controller: _scrollController,
              padding: EdgeInsets.all(10),
              child: Column(
                children: _messageHistory.map((message) {
                  bool isUser = message.startsWith("User:");
                  return _buildMessage(message, isUser);
                }).toList(),
              ),
            ),
          ),
          _isListening
              ? CircularProgressIndicator() // Show progress when listening
              : Row(
                  children: [
                    IconButton(
                      icon: Icon(Icons.mic),
                      onPressed: _hasSentMessage
                          ? null
                          : _startListening, // Start listening for speech
                    ),
                    Expanded(
                      child: TextField(
                        controller: _textController,
                        decoration: InputDecoration(
                          hintText: "Type or speak your message...",
                          border: OutlineInputBorder(),
                        ),
                        onChanged: (value) {
                          if (value.isNotEmpty && !_hasSentMessage) {
                            _userSpeech = value;
                          }
                        },
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.send),
                      onPressed: _hasSentMessage
                          ? null
                          : () {
                              _sendMessage();
                              _textController.clear();
                            }, // Send the typed or spoken message
                    ),
                  ],
                ),
        ],
      ),
    );
  }

  Widget _buildMessage(String message, bool isUser) {
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        padding: EdgeInsets.all(10),
        margin: EdgeInsets.symmetric(vertical: 5),
        decoration: BoxDecoration(
          color: isUser ? Colors.blueAccent : Colors.grey[300],
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          message,
          style: TextStyle(color: isUser ? Colors.white : Colors.black),
        ),
      ),
    );
  }
}
