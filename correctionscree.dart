import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'main.dart';

class CorrectionScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // Mock data for corrections
    final corrections = [
      "User: I goed to the store.",
      "Correction: I went to the store.",
      "User: She don't like apples.",
      "Correction: She doesn't like apples.",
      // Add more examples as needed
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text('Speech Corrections'),
      ),
      body: ListView.builder(
        itemCount: corrections.length,
        itemBuilder: (context, index) {
          return ListTile(
            title: Text(corrections[index]),
          );
        },
      ),
    );
  }
}
