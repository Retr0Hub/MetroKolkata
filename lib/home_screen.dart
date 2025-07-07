import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'plan_journey_screen.dart';
import 'profile_screen.dart';
import 'recharge_screen.dart';
import 'tickets_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Get the current user from FirebaseAuth
    final user = FirebaseAuth.instance.currentUser;

    // If for some reason we land here without a user, show an error.
    if (user == null) {
      return const Scaffold(
        body: Center(
          child: Text('Error: No user logged in.'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kolkata Metro'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: () async {
              // Also sign out from Google to allow the user to select a different account next time.
              await GoogleSignIn().signOut();
              // Signing out will trigger the AuthWrapper to rebuild and show the decision screen.
              await FirebaseAuth.instance.signOut();
            },
          ),
        ],
      ),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream:
            FirebaseFirestore.instance.collection('users').doc(user.uid).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text('User data not found.'));
          }

          final userData = snapshot.data!.data();
          final String fullName = userData?['fullName'] ?? 'User';
          final num balance = userData?['metroCardBalance'] ?? 0;

          return ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              _buildBalanceCard(context, fullName, balance),
              const SizedBox(height: 24),
              _buildActionsGrid(context),
              const SizedBox(height: 24),
              Text(
                'Promotions & Offers',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              _buildPromotionsList(context),
              const SizedBox(height: 24),
              Text('Recent Activity',
                  style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              _buildRecentActivityList(context),
            ],
          );
        },
      ),
    );
  }

  Widget _buildBalanceCard(BuildContext context, String name, num balance) {
    return Card(
      child: Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              name,
              style: Theme.of(context)
                  .textTheme
                  .headlineSmall
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Available Balance',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(color: Theme.of(context).colorScheme.secondary),
            ),
            const SizedBox(height: 4),
            Text(
              '₹ ${balance.toStringAsFixed(2)}',
              style: Theme.of(context)
                  .textTheme
                  .displaySmall
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionsGrid(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 1.2,
      children: [
        _buildActionItem(
          context,
          icon: Icons.explore_outlined,
          label: 'Plan Journey',
          onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const PlanJourneyScreen())),
        ),
        _buildActionItem(
          context,
          icon: Icons.add_card_outlined,
          label: 'Recharge Card',
          onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const RechargeScreen())),
        ),
        _buildActionItem(
          context,
          icon: Icons.receipt_long,
          label: 'View Tickets',
          onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const TicketsScreen())),
        ),
        _buildActionItem(
          context,
          icon: Icons.person_outline,
          label: 'My Profile',
          onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ProfileScreen())),
        ),
      ],
    );
  }

  Widget _buildActionItem(BuildContext context, {required IconData icon, required String label, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(15),
      child: Card(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 40, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 12),
            Text(
              label,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPromotionsList(BuildContext context) {
    return SizedBox(
      height: 150,
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        scrollDirection: Axis.horizontal,
        children: [
          _buildPromotionCard(context, '20% Cashback',
              'On recharges above ₹500', Colors.orange),
          const SizedBox(width: 16),
          _buildPromotionCard(context, 'Weekend Pass',
              'Unlimited travel on Sat & Sun', Colors.teal),
          const SizedBox(width: 16),
          _buildPromotionCard(
              context, 'Student Offer', '50% off on monthly passes', Colors.pink),
        ],
      ),
    );
  }

  Widget _buildPromotionCard(BuildContext context, String title, String subtitle, Color color) {
    return SizedBox(
      width: 250,
      child: Card(
        color: color,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.white70),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecentActivityList(BuildContext context) {
    // Placeholder data
    final List<Map<String, String>> recentTrips = [
      {'from': 'Esplanade', 'to': 'Dum Dum', 'cost': '15.00'},
      {'from': 'Dum Dum', 'to': 'Esplanade', 'cost': '15.00'},
      {'from': 'Park Street', 'to': 'Kavi Subhash', 'cost': '25.00'},
    ];

    if (recentTrips.isEmpty) {
      return const Card(
        child: ListTile(
          leading: Icon(Icons.history),
          title: Text('No recent activity'),
          subtitle: Text('Your recent trips will appear here.'),
        ),
      );
    }

    return Column(
      children: recentTrips.map((trip) {
        return Card(
          child: ListTile(
            leading: const Icon(Icons.train_outlined),
            title: Text('${trip['from']} to ${trip['to']}'),
            trailing: Text('₹ ${trip['cost']}', style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
        );
      }).toList(),
    );
  }
}