import 'package:flutter/material.dart';

class PlanJourneyScreen extends StatelessWidget {
  const PlanJourneyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Plan Journey'),
      ),
      body: const Center(
        child: Text('Journey planner coming soon!', style: TextStyle(fontSize: 18)),
      ),
    );
  }
}