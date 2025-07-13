import 'dart:async';
import 'dart:ui';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:intl/intl.dart';
import 'plan_journey_screen.dart';
import 'profile_screen.dart';
import 'recharge_screen.dart';
import 'tickets_screen.dart';
import 'widgets/glassmorphic_container.dart';

import 'package:cloud_firestore/cloud_firestore.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  bool _isDrawerOpen = false;
  DateTime? _lastBackPressed;
  String? _currentCity;
  String? _locationError;
  bool _isLoadingLocation = true;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _determinePosition();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _toggleDrawer() => setState(() {
        _isDrawerOpen = !_isDrawerOpen;
        _isDrawerOpen ? _animationController.forward() : _animationController.reverse();
      });

  Future<void> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    setState(() {
      _isLoadingLocation = true;
      _locationError = null;
    });

    // Test if location services are enabled.
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      setState(() {
        _locationError = 'Location services are disabled.';
        _isLoadingLocation = false;
      });
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        setState(() {
          _locationError = 'Location permissions are denied.';
          _isLoadingLocation = false;
        });
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      setState(() {
        _locationError = 'Location permissions are permanently denied.';
        _isLoadingLocation = false;
      });
      return;
    }

    try {
      final position = await Geolocator.getCurrentPosition();
      List<Placemark> placemarks =
          await placemarkFromCoordinates(position.latitude, position.longitude);
      Placemark place = placemarks[0];
      setState(() {
        _currentCity = place.locality ?? 'Unknown City';
        _isLoadingLocation = false;
      });
    } catch (e) {
      setState(() {
        _locationError = 'Failed to get location.';
        _isLoadingLocation = false;
      });
    }
  }

  Future<bool> _onWillPop() async {
    // If the drawer is open, the back button should close it.
    if (_isDrawerOpen) {
      _toggleDrawer();
      return false;
    }

    // If we can pop the navigator (i.e., we're on a sub-screen like Profile),
    // then just allow the pop to happen.
    if (Navigator.of(context).canPop()) {
      return true;
    }

    // Otherwise, we're on the HomeScreen, so implement the "double tap to exit" logic.
    final now = DateTime.now();
    final timeSinceLastPress = _lastBackPressed != null ? now.difference(_lastBackPressed!) : null;

    if (timeSinceLastPress == null || timeSinceLastPress > const Duration(seconds: 2)) {
      _lastBackPressed = now;
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Press back again to exit.'),
            duration: Duration(seconds: 2)),
      );
      return false;
    }
    return true;
  }

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

    // By setting the background color on a single, persistent Scaffold,
    // we prevent any flickering during transitions or data loading.
    return Scaffold( // The background color is now set by the AppTheme
      // backgroundColor: const Color(0xFF1C1C2D), // No longer needed
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream:
            FirebaseFirestore.instance.collection('users').doc(user.uid).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.white)));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text('User data not found.', style: TextStyle(color: Colors.white)));
          }

          final userData = snapshot.data!.data()!;
          final String fullName = userData['fullName'] ?? 'User';
          final num balance = userData['metroCardBalance'] ?? 0;

          // The Stack lays out the drawer behind the main screen.
          // Both are always rendered, ensuring a smooth, flicker-free animation.
          return WillPopScope(
            onWillPop: _onWillPop,
            child: Stack(
              children: [
                // Background Image for the Glass Effect
                Container(
                  decoration: const BoxDecoration(
                    image: DecorationImage(
                      image: AssetImage("assets/ios_background.jpg"), // Make sure you have this image
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                // The drawer is a layer below the main screen
                _AppDrawer(userData: userData),

                // The main screen content, animated on top of the drawer
                AnimatedBuilder(
                  animation: _animationController,
                  builder: (context, child) {
                    // Values for the animation
                    final double slide = 275.0 * _animationController.value;
                    final double scale = 1.0 - (_animationController.value * 0.2);
                    final double borderRadius = 24.0 * _animationController.value;

                    return Transform(
                      transform: Matrix4.identity()
                        ..translate(slide)
                        ..scale(scale),
                      alignment: Alignment.centerLeft,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(borderRadius),
                        child: child,
                      ),
                    );
                  },
                  child: GestureDetector(
                    onTap: _isDrawerOpen ? _toggleDrawer : null,
                    child: AbsorbPointer(
                      absorbing: _isDrawerOpen,
                      child: Scaffold(
                        appBar: AppBar(
                          leading: IconButton(
                            icon: AnimatedIcon(
                              icon: AnimatedIcons.menu_close,
                              progress: _animationController,
                            ),
                            onPressed: _toggleDrawer,
                          ),
                          title: const Text('Kolkata Metro'),
                        ),
                        body: ListView(
                          padding: const EdgeInsets.all(16.0),
                          children: [
                            _buildWeatherWidget(context),
                            _buildSectionHeader(context, 'Quick Actions'),
                            _buildActionsGrid(context),
                            _buildSectionHeader(context, 'Promotions & Offers'),
                            _buildPromotionsList(context),
                            _buildSectionHeader(context, 'Recent Activity'),
                            _buildRecentActivityList(context),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildWeatherWidget(BuildContext context) {
    String lastUpdated = DateFormat('h:mm a').format(DateTime.now());

    Widget content;
    if (_isLoadingLocation) {
      content = const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(width: 16),
          Text('Fetching location...'),
        ],
      );
    } else if (_locationError != null) {
      content = Text(_locationError!,
          style: TextStyle(color: Theme.of(context).colorScheme.error));
    } else {
      // Placeholder weather data
      content = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _currentCity ?? 'Unknown Location',
            style: Theme.of(context)
                .textTheme
                .headlineSmall
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Partly Cloudy', // Placeholder
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7)),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '26°C', // Placeholder
                style: Theme.of(context)
                    .textTheme
                    .displaySmall
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              Text(
                'last updated @$lastUpdated',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ],
      );
    }

    return GlassmorphicContainer(
      blur: 15,
      padding: const EdgeInsets.all(20),
      child: content,
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4.0, bottom: 8.0, top: 24.0),
      child: Text(
        title.toUpperCase(),
        style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.white),
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
          icon: Icons.map_outlined,
          label: 'Maps',
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text('Maps functionality coming soon!'),
            ));
          },
        ),
      ],
    );
  }

  Widget _buildActionItem(BuildContext context, {required IconData icon, required String label, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(15),
      child: GlassmorphicContainer(
        borderRadius: 15,
        blur: 15,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 40, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 12),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white),
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
        // The outer ListView already provides padding.
        scrollDirection: Axis.horizontal,
        children: [
          _buildPromotionCard(context, '20% Cashback', 'On recharges above ₹500',
              [Colors.orange.withOpacity(0.3), Colors.deepOrange.withOpacity(0.4)]),
          const SizedBox(width: 16),
          _buildPromotionCard(context, 'Weekend Pass', 'Unlimited travel on Sat & Sun',
              [Colors.teal.withOpacity(0.3), Colors.green.withOpacity(0.4)]),
          const SizedBox(width: 16),
          _buildPromotionCard(context, 'Student Offer', '50% off on monthly passes',
              [Colors.pink.withOpacity(0.3), Colors.redAccent.withOpacity(0.4)]),
        ],
      ),
    );
  }

  Widget _buildPromotionCard(BuildContext context, String title, String subtitle, List<Color> gradientColors) {
    return SizedBox(
      width: 250,
      child: GlassmorphicContainer(
        borderRadius: 15,
        blur: 15,
        gradientColors: gradientColors,
        border: Border.all(color: Colors.white.withOpacity(0.3), width: 1.0),
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
    // This should be inside the ListView builder
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
class _AppDrawer extends StatelessWidget {
  final Map<String, dynamic> userData;

  const _AppDrawer({required this.userData});

  @override
  Widget build(BuildContext context) {
    final String fullName = userData['fullName'] ?? 'User';
    final String email = userData['email'] ?? 'No email provided';
    final String? photoUrl = FirebaseAuth.instance.currentUser?.photoURL;

    return Drawer(
      child: Container( // The color is now inherited from the theme's canvasColor
        // color: const Color(0xFF1C1C2D), // No longer needed
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildProfileCard(context, fullName, email, photoUrl),
              Expanded(
                child: ListView(
                  padding: EdgeInsets.zero,
                  children: [
                    const Divider(color: Colors.white24, height: 1),
                    _buildDrawerItem(
                      context,
                      icon: Icons.home_outlined,
                      text: 'Home',
                      onTap: () => Navigator.pop(context),
                    ),
                    _buildDrawerItem(
                      context,
                      icon: Icons.add_card_outlined,
                      text: 'Recharge',
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.of(context).push(MaterialPageRoute(
                          builder: (_) => const RechargeScreen(),
                        ));
                      },
                    ),
                    _buildDrawerItem(
                      context,
                      icon: Icons.receipt_long_outlined,
                      text: 'Tickets',
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.of(context).push(MaterialPageRoute(
                          builder: (_) => const TicketsScreen(),
                        ));
                      },
                    ),
                  ],
                ),
              ),
              const Divider(color: Colors.white24, height: 1),
              _buildDrawerItem(
                context,
                icon: Icons.logout,
                text: 'Logout',
                onTap: () async {
                  Navigator.pop(context);
                  final bool? confirmLogout = await showDialog<bool>(
                    context: context,
                    builder: (BuildContext context) => AlertDialog(
                      title: const Text('Confirm Logout'),
                      content: const Text('Are you sure you want to log out?'),
                      actions: <Widget>[
                        TextButton(
                          child: const Text('Cancel'),
                          onPressed: () => Navigator.of(context).pop(false),
                        ),
                        TextButton(
                          child: const Text('Logout'),
                          onPressed: () => Navigator.of(context).pop(true),
                        ),
                      ],
                    ),
                  );
                  if (confirmLogout == true) {
                    await GoogleSignIn().signOut();
                    await FirebaseAuth.instance.signOut();
                  }
                },
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileCard(BuildContext context, String fullName, String email, String? photoUrl) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      child: InkWell(
        onTap: () {
          Navigator.pop(context); // Close drawer first
          Navigator.of(context).push(MaterialPageRoute(
            builder: (_) => const ProfileScreen(),
          ));
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: const LinearGradient(
              colors: [Color(0xFF4A00E0), Color(0xFF8E2DE2)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.purple.withOpacity(0.4),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: Colors.white24,
                backgroundImage: photoUrl != null ? NetworkImage(photoUrl) : null,
                child: photoUrl == null
                    ? Text(
                        fullName.isNotEmpty ? fullName[0].toUpperCase() : 'U',
                        style: const TextStyle(fontSize: 24, color: Colors.white, fontWeight: FontWeight.bold),
                      )
                    : null,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(fullName, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold,), overflow: TextOverflow.ellipsis,),
                    const SizedBox(height: 4),
                    Text('View Profile & Settings', style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 14,),),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios, color: Colors.white70, size: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDrawerItem(BuildContext context,
      {required IconData icon, required String text, required VoidCallback onTap}) {
    return ListTile(
      leading: Icon(icon, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7)),
      title: Text(
        text,
        // Use the theme's text style for consistency
        style: Theme.of(context).textTheme.titleMedium,
      ),
      onTap: onTap,
    );
  }
}