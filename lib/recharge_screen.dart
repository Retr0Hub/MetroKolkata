import 'package:flutter/material.dart';

class RechargeScreen extends StatelessWidget {
  const RechargeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Recharge Card'),
      ),
      body: const Center(
        child: Text('Recharge functionality coming soon!', style: TextStyle(fontSize: 18)),
      ),
    );
  }
}