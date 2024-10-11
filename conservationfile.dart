// Old Conversations Screen
import 'package:flutter/material.dart';
import 'package:helloworld/mediapractic.dart';

import 'package:provider/provider.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

class ConversationsScreen extends StatefulWidget {
  @override
  _ConversationsScreenState createState() => _ConversationsScreenState();
}

class _ConversationsScreenState extends State<ConversationsScreen> {
  stt.SpeechToText _speech = stt.SpeechToText();
  bool _isListening = false;
  String _userSpeech = '';
  String _botResponse = '';
  List<String> _messageHistory = [];
  ScrollController _scrollController = ScrollController();
  Timer? _silenceTimer;
  bool _hasUserResponded = false;

  List<Map<String, dynamic>> _questions = [];
  TextEditingController _textController =
      TextEditingController(); // Controller for text input

  @override
  void initState() {
    super.initState();
    _fetchQuestions(); // Fetch questions from the API
  }

  Future<void> _fetchQuestions() async {
    try {
      final response = await http.get(Uri.parse(
          'https://my-json-server.typicode.com/tryninjastudy/dummyapi/db'));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        List<dynamic> restaurantData = data['restaurant'];

        setState(() {
          _questions = restaurantData
              .map((item) => {'bot': item['bot'], 'human': item['human']})
              .toList();
        });

        // Start the conversation with the first bot question if available
        if (_questions.isNotEmpty) {
          _startConversation();
        }
      } else {
        print('Failed to load questions: ${response.statusCode}');
        throw Exception('Failed to load questions');
      }
    } catch (e) {
      print('Error fetching questions: $e');
    }
  }

  void _startConversation() {
    if (_questions.isNotEmpty) {
      _botResponse = "Bot: ${_questions[0]['bot']}"; // First question from API
      _messageHistory.add(_botResponse);
      setState(() {});
    }
  }

  void _startListening() async {
    bool available = await _speech.initialize();
    if (available) {
      setState(() {
        _isListening = true;
        _userSpeech = ''; // Reset speech
        _hasUserResponded = false; // Reset response tracking
      });
      _speech.listen(onResult: (result) {
        if (result.hasConfidenceRating && result.confidence > 0.5) {
          setState(() {
            _userSpeech = result.recognizedWords; // Update speech
            _textController.text = _userSpeech; // Fill in the text field
          });
        }
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
  }

  void _resetSilenceTimer() {
    _silenceTimer?.cancel();
    _silenceTimer = Timer(Duration(seconds: 2), () {
      _stopListening(); // Stop listening after 2 seconds of silence
    });
  }

  void _handleResponse(String userResponse) {
    if (userResponse.isNotEmpty) {
      String userMessage = "User: $userResponse";
      _messageHistory.add(userMessage);
      context.read<ConversationProvider>().addConversation(userMessage);

      // Find the next bot response
      int currentQuestionIndex =
          _messageHistory.length ~/ 2; // Each exchange has two entries
      if (currentQuestionIndex < _questions.length) {
        _botResponse = "Bot: ${_questions[currentQuestionIndex]['bot']}";
        _messageHistory.add(_botResponse);
      } else {
        _botResponse = "Bot: Thank you for your answers!";
        _messageHistory.add(_botResponse);
      }

      setState(() {});
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    Future.delayed(Duration(milliseconds: 100), () {
      _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
    });
  }

  void _clearSpeech() {
    setState(() {
      _userSpeech = ''; // Clear user speech
      _textController.clear(); // Clear the text field
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
                      onPressed: _startListening, // Start listening for speech
                    ),
                    Expanded(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.vertical,
                        child: Container(
                          constraints: BoxConstraints(
                            maxHeight: 100, // Limit max height of text field
                          ),
                          child: TextField(
                            controller: _textController, // Use the controller
                            decoration: InputDecoration(
                              hintText: "Type or speak your message...",
                              border: OutlineInputBorder(),
                            ),
                            maxLines: null, // Allow for multiline input
                            onSubmitted: (value) {
                              _handleResponse(value);
                              _clearSpeech();
                            },
                          ),
                        ),
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.clear),
                      onPressed: _clearSpeech, // Clear button
                    ),
                    IconButton(
                      icon: Icon(Icons.send),
                      onPressed: () {
                        _handleResponse(_textController.text);
                        _clearSpeech();
                      }, // Send button
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

class ConversationProvider with ChangeNotifier {
  List<String> _conversations = [];

  List<String> get conversations => _conversations;

  void addConversation(String conversation) {
    _conversations.add(conversation);
    notifyListeners();
  }
}
