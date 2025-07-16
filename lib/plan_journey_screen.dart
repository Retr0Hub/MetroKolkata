import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class PlanJourneyScreen extends StatefulWidget {
  const PlanJourneyScreen({super.key});

  @override
  State<PlanJourneyScreen> createState() => _PlanJourneyScreenState();
}

class _PlanJourneyScreenState extends State<PlanJourneyScreen> {
  final _fromController = TextEditingController();
  final _toController = TextEditingController();

  // Dummy data for frequent stations, inspired by the design
  final List<String> _frequentStations = [
    'Huda City Center',
    'INA',
    'Dwarka Sec 41',
    'Akshardham',
    'Vaishali',
    'Rajiv Chowk',
  ];

  @override
  void dispose() {
    _fromController.dispose();
    _toController.dispose();
    super.dispose();
  }

  void _swapStations() {
    final fromText = _fromController.text;
    _fromController.text = _toController.text;
    _toController.text = fromText;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7), // A light grey background
      appBar: AppBar(
        backgroundColor: const Color(0xFFF7F7F7),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        title: Text(
          'Plan Journey',
          style: GoogleFonts.inter(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          _buildStationInputFields(),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              // TODO: Implement route finding logic
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF3D74F5), // Blue color from design
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              'Find Route',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 32),
          _buildSectionHeader('Frequent Stations'),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8.0,
            runSpacing: 8.0,
            children: _frequentStations
                .map((station) => _buildStationChip(station))
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildStationInputFields() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          )
        ],
      ),
      child: Row(
        children: [
          const Column(
            children: [
              Icon(Icons.trip_origin, color: Colors.blue, size: 20),
              SizedBox(height: 2),
              Icon(Icons.more_vert, color: Colors.grey, size: 20),
              SizedBox(height: 2),
              Icon(Icons.location_on, color: Colors.red, size: 20),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              children: [
                TextField(controller: _fromController, decoration: const InputDecoration(hintText: 'From Station', border: InputBorder.none)),
                const Divider(),
                TextField(controller: _toController, decoration: const InputDecoration(hintText: 'To Station', border: InputBorder.none)),
              ],
            ),
          ),
          IconButton(icon: const Icon(Icons.swap_vert, color: Colors.grey), onPressed: _swapStations),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) => Text(title, style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87));

  Widget _buildStationChip(String stationName) {
    return ActionChip(
      label: Text(stationName, style: GoogleFonts.inter(fontWeight: FontWeight.w500)),
      onPressed: () => _toController.text = stationName,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: Colors.grey.shade300)),
    );
  }
}