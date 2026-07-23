import 'package:flutter/material.dart';

class LearningLogScreen extends StatelessWidget {
  const LearningLogScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Learning Log')),
      body: const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'Your completed sessions and learning notes will appear here.',
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
