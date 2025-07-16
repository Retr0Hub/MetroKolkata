import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'data/metro_station_data.dart';
import 'models/metro_station.dart';

// --- Main Home Screen Widget ---
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  DateTime? _lastBackPressed;
  String? _currentCity;
  String? _locationError;
  bool _isLoadingLocation = true;
  // New state variables for metro proximity
  String? _closestMetroName;
  double? _distanceToClosestMetro; // in meters

  @override
  void initState() {
    super.initState();
    _determinePosition();
  }

  // --- Logic Methods ---

  Future<void> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    setState(() {
      _isLoadingLocation = true;
      _locationError = null;
    });

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
        _locationError = 'Permissions are permanently denied.';
        _isLoadingLocation = false;
      });
      return;
    }

    try {
      final position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);

      // Get city name
      List<Placemark> placemarks =
          await placemarkFromCoordinates(position.latitude, position.longitude);
      Placemark place = placemarks[0];

      // Find closest metro station
      MetroStation? closestStation;
      double? minDistance;

      for (final station in kolkataMetroStations) {
        final distance = Geolocator.distanceBetween(
          position.latitude,
          position.longitude,
          station.latitude,
          station.longitude,
        );

        if (minDistance == null || distance < minDistance) {
          minDistance = distance;
          closestStation = station;
        }
      }

      setState(() {
        _currentCity = place.locality ?? 'Unknown City';
        _closestMetroName = closestStation?.name;
        _distanceToClosestMetro = minDistance;
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
    if (Navigator.of(context).canPop()) {
      return true;
    }
    final now = DateTime.now();
    final timeSinceLastPress =
        _lastBackPressed != null ? now.difference(_lastBackPressed!) : null;

    if (timeSinceLastPress == null ||
        timeSinceLastPress > const Duration(seconds: 2)) {
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
  
  // Added sign-out method for the drawer
  Future<void> _signOut() async {
    await GoogleSignIn().signOut();
    await FirebaseAuth.instance.signOut();
    // You might want to navigate to the login screen after this
  }

  // --- Build Methods ---

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
        onWillPop: _onWillPop,
        child: StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance
              .collection('users')
              .doc(FirebaseAuth.instance.currentUser!.uid)
              .snapshots(),
          builder: (context, userSnapshot) {
            if (userSnapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                  backgroundColor: Color(0xFF1C1C2D),
                  body: Center(child: CircularProgressIndicator()));
            }
            if (userSnapshot.hasError) {
              return Scaffold(
                  backgroundColor: const Color(0xFF1C1C2D),
                  body: Center(
                      child: Text("Error fetching user data.",
                          style: TextStyle(color: Colors.red))));
            }
            if (!userSnapshot.hasData || !userSnapshot.data!.exists) {
              return const Scaffold(
                  backgroundColor: Color(0xFF1C1C2D),
                  body: Center(
                      child: Text("User data not found.",
                          style: TextStyle(color: Colors.white))));
            }

            final userData = userSnapshot.data!.data() as Map<String, dynamic>;

            return Scaffold(
              backgroundColor: const Color(0xFF1C1C2D),
              appBar: AppBar(
                title: Text(
                  'Kolkata Metro',
                  style: GoogleFonts.inter(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                backgroundColor: Colors.transparent,
                elevation: 0,
                automaticallyImplyLeading: false,
                actions: [
                  Builder(
                    builder: (context) => IconButton(
                      icon: const Icon(Icons.menu, color: Colors.white),
                      onPressed: () => Scaffold.of(context).openEndDrawer(),
                    ),
                  ),
                ],
              ),
              endDrawer: _buildDrawer(userData),
              body: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                children: [
                  const SizedBox(height: 8),
                  _buildLocationDisplay(),
                  const SizedBox(height: 20),
                  // --- Search Bar ---
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2C2C2E),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.search, color: Colors.white70),
                        const SizedBox(width: 10),
                        Text("Enter your destination",
                            style: GoogleFonts.inter(
                                color: Colors.white70, fontSize: 16)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  // --- Services Section ---
                  _buildSectionHeader("Services"),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 110, // Give the horizontal list a fixed height
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        // NOTE: Replace 'assets/...' with your actual image paths
                        _buildServiceBox("Ride", Icons.local_taxi),
                        _buildServiceBox("Package", Icons.card_giftcard),
                        _buildServiceBox("Reserve", Icons.event_seat,
                            tag: "New"),
                        _buildServiceBox("Metro", Icons.train),
                        _buildServiceBox("More", Icons.apps),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  // --- Recent Stations Section ---
                  _buildSectionHeader("Recent Stations"),
                  const SizedBox(height: 16),
                  _buildRecentStationCard(
                      "Kalyani", "Line 1, Platform 2", Icons.history),
                  const SizedBox(height: 12),
                  // --- Ad Banner ---
                  _buildAdBanner("Travel Safely", "Learn More",
                      Icons.health_and_safety_outlined),
                  const SizedBox(height: 20),
                ],
              ),
            );
          },
        ));
  }

  Widget _buildLocationDisplay() {
    Widget locationText;

    if (_isLoadingLocation) {
      locationText = Text('Fetching location...',
          style: GoogleFonts.inter(color: Colors.white70));
    } else if (_locationError != null) {
      locationText =
          Text(_locationError!, style: GoogleFonts.inter(color: Colors.redAccent));
    } else if (_closestMetroName != null && _distanceToClosestMetro != null) {
      // If user is within 50 meters, they are at the station
      if (_distanceToClosestMetro! < 50) {
        locationText = Text('Welcome to $_closestMetroName Station',
            style: GoogleFonts.inter(
                color: Colors.white, fontWeight: FontWeight.w600));
      } else {
        final distanceInKm = (_distanceToClosestMetro! / 1000).toStringAsFixed(1);
        locationText = Text('$distanceInKm km away from $_closestMetroName',
            style: GoogleFonts.inter(
                color: Colors.white, fontWeight: FontWeight.w600));
      }
    } else {
      locationText = Text(_currentCity ?? 'Location not available',
          style:
              GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w600));
    }

    return Row(
      children: [
        const Icon(Icons.location_on, color: Colors.white70, size: 16),
        const SizedBox(width: 8),
        Expanded(child: locationText),
      ],
    );
  }

  Widget _buildDrawer(Map<String, dynamic> userData) {
    return Drawer(
      child: Container(
        color: const Color(0xFF121223),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 80, 20, 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 40,
                backgroundImage: NetworkImage(
                    userData['photoURL'] ?? 'https://via.placeholder.com/150'),
              ),
              const SizedBox(height: 16),
              Text(
                userData['name'] ?? 'Guest User',
                style: GoogleFonts.inter(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white),
              ),
              Text(
                userData['email'] ?? '',
                style: GoogleFonts.inter(fontSize: 16, color: Colors.white70),
              ),
              const Spacer(),
              ListTile(
                leading: const Icon(Icons.logout, color: Colors.white70),
                title: Text('Sign Out',
                    style: GoogleFonts.inter(color: Colors.white70)),
                onTap: _signOut,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecentStationCard(String title, String subtitle, IconData icon) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF2C2C2E),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Icon(icon, color: Colors.white),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: GoogleFonts.inter(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 16)),
                Text(subtitle,
                    style: GoogleFonts.inter(
                        color: Colors.white70, fontSize: 14)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title,
            style: GoogleFonts.inter(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600)),
        Text("See all",
            style: GoogleFonts.inter(color: Colors.white54, fontSize: 14))
      ],
    );
  }

  // Modified to take IconData for easier use without assets
  Widget _buildServiceBox(String label, IconData icon, {String? tag}) {
    return Container(
      width: 80,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF2C2C2E),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Using a simple Stack to overlay the tag
          Expanded(
            child: Stack(
              alignment: Alignment.topCenter,
              children: [
                if (tag != null)
                  Positioned(
                    top: -2,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.green,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(tag, style: GoogleFonts.inter(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                    ),
                  ),
                Center(child: Icon(icon, color: Colors.white, size: 36)),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Text(label,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                  color: Colors.white70, fontSize: 14, height: 1.2)),
        ],
      ),
    );
  }

  // Modified to take IconData for easier use without assets
  Widget _buildAdBanner(String title, String buttonText, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: GoogleFonts.inter(
                        color: Colors.black,
                        fontWeight: FontWeight.w600,
                        fontSize: 16)),
                const SizedBox(height: 8),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20)),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 8),
                  ),
                  onPressed: () {},
                  child: Text(buttonText,
                      style: GoogleFonts.inter(color: Colors.white)),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Icon(icon, color: Colors.blueAccent, size: 70),
        ],
      ),
    );
  }
}