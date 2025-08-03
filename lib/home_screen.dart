import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_svg/flutter_svg.dart';

// --- Color Constants ---
const Color kScaffoldBackground = Color(0xFF1A1A52);
const Color kCardColor = Color(0xFF2C2B5A);
const Color kLightBlue = Color(0xFF5AB9E8);
const Color kDarkButtonColor = Color(0xFF3C3C6E);
const Color kBalanceColor = Color(0xFF40E0D0);
const Color kChipColor = Color(0xFF5A5A82);
const Color kSubtleTextColor = Colors.white70;

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ));

    return MaterialApp(
      title: 'Metro App UI',
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: Colors.transparent,
        textTheme: GoogleFonts.poppinsTextTheme(ThemeData.dark().textTheme),
      ),
      home: const HomeScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  bool _isHistoryVisible = false;
  int _selectedIndex = 1;

  Widget _navItem({required IconData icon, required String label, required int index}) {
    final isSelected = _selectedIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedIndex = index),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            color: isSelected ? Colors.blueAccent : Colors.white70,
            size: 26,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: isSelected ? Colors.blueAccent : Colors.white70,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDarkMode ? Colors.black : Colors.white;
    final textColor = isDarkMode ? Colors.white : Colors.black;
    final borderColor = isDarkMode ? Colors.white : Colors.black;
    final metroColor = isDarkMode ? const Color.fromARGB(255, 255, 255, 255) : const Color.fromARGB(255, 0, 0, 0);

    return Stack(
      children: [
        // 🔹 Background Gradient
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isDarkMode
                  ? [Colors.black, kScaffoldBackground]
                  : [Colors.white, Colors.grey[300]!],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),

        // 🔹 Main content
        Scaffold(
          backgroundColor: Colors.transparent,
          body: SafeArea(
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 15.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildHeader(textColor),
                        const SizedBox(height: 20.0),
                        Stack(
                          clipBehavior: Clip.none,
                          children: [
                            gradientCardSample(),
                            Positioned(
                              bottom: -35,
                              left: 0,
                              child: _buildViewInOutButton(),
                            ),
                          ],
                        ),
                        AnimatedSize(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                          child: _isHistoryVisible
                              ? Padding(
                                  padding: const EdgeInsets.only(top: 30.0),
                                  child: _buildHistorySection(),
                                )
                              : const SizedBox(),
                        ),
                        const SizedBox(height: 30),
                        _buildActionGrid(),
                        const SizedBox(height: 100),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        // 🔹 Glass Dock Overlay
        Positioned(
          bottom: 16,
          left: 0,
          right: 0,
          child: Center(
            child: FractionallySizedBox(
              widthFactor: 0.85,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(40),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
                  child: Container(
                    height: 80,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(40),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.3),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _navItem(icon: Icons.credit_card, label: "Pass", index: 0),
                        _navItem(icon: Icons.home_outlined, label: "Home", index: 1),
                        _navItem(icon: Icons.explore_outlined, label: "Navigate", index: 2),
                        _navItem(icon: Icons.call_outlined, label: "Contact", index: 3),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader(Color textColor) {
    return Row(
      children: [
        const CircleAvatar(
          radius: 22,
          backgroundImage: NetworkImage('https://i.pravatar.cc/150?img=1'),
        ),
        const SizedBox(width: 15),
        Text(
          'Location from nearest metro',
          style: TextStyle(
            color: textColor.withOpacity(0.7),
            fontSize: 15,
          ),
        ),
      ],
    );
  }

  Widget gradientCardSample() {
    return Container(
      height: 200,
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF846AFF),
            Color(0xFF755EE8),
            Colors.purpleAccent,
            Colors.amber,
          ],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    'Metro Card',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'monospace',
                    ),
                  ),
                  const Spacer(),
                  SvgPicture.asset(
                    'lib/assets/logo.svg',
                    height: 35,
                    width: 35,
                    color: Colors.white54,
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                '4111 7679 8689 9700',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontFamily: 'monospace',
                ),
              ),
            ],
          ),
          const Text(
            '\$3,000',
            style: TextStyle(
              fontSize: 24,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildViewInOutButton() {
    return ClipPath(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.5,
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
        decoration: const BoxDecoration(
          color: kLightBlue,
          borderRadius: BorderRadius.only(
            bottomRight: Radius.circular(16),
            bottomLeft: Radius.circular(16),
          ),
        ),
        child: GestureDetector(
          onTap: () {
            setState(() {
              _isHistoryVisible = !_isHistoryVisible;
            });
          },
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                _isHistoryVisible ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                color: Colors.black,
              ),
              const SizedBox(width: 4),
              const Text(
                'View In & Out',
                style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHistorySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'History',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 15),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
          decoration: BoxDecoration(
            color: kCardColor,
            borderRadius: BorderRadius.circular(25),
          ),
          child: Column(
            children: const [
              _HistoryItem(station: 'Dumdum', type: 'Entry', time: '16:50'),
              _HistoryItem(station: 'Park Street', type: 'Exit', time: '17:05'),
              _HistoryItem(station: 'Esplanade', type: 'Entry', time: '21:05'),
              _HistoryItem(station: 'Dumdum', type: 'Exit', time: '21:25'),
            ],
          ),
        )
      ],
    );
  }

  Widget _buildActionGrid() {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 20,
      mainAxisSpacing: 20,
      childAspectRatio: 1,
      children: const [
        _ActionButton(text: 'Book QR Ticket', color: kDarkButtonColor),
        _ActionButton(text: 'Train Time', color: kLightBlue),
        _ActionButton(text: 'Ticket History', color: kLightBlue),
        _ActionButton(text: 'Live Station', color: kDarkButtonColor),
      ],
    );
  }
}

class _HistoryItem extends StatelessWidget {
  final String station;
  final String type;
  final String time;

  const _HistoryItem({required this.station, required this.type, required this.time});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: kChipColor,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              station,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text(type, style: TextStyle(color: Colors.grey[400])),
          const Spacer(),
          Text(time, style: TextStyle(color: Colors.grey[400])),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String text;
  final Color color;

  const _ActionButton({required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
      ),
      padding: const EdgeInsets.all(12),
      child: Center(
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
