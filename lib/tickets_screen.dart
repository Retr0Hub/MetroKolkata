import 'package:flutter/material.dart';

class TicketsScreen extends StatelessWidget {
  const TicketsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('View Tickets'),
      ),
      body: const Center(
        child: Text('Ticket history coming soon!', style: TextStyle(fontSize: 18)),
      ),
    );
  }
}