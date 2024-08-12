// ignore_for_file: prefer_const_constructors, sort_child_properties_last, use_key_in_widget_constructors, prefer_const_constructors_in_immutables

import 'package:flutter/material.dart';

class TurfViewPage extends StatelessWidget {
  final Map<String, dynamic> turfData;

  TurfViewPage({required this.turfData});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(turfData['name'] ?? 'Turf Details'),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(turfData['name'] ?? 'Unknown', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            SizedBox(height: 20),
            _buildInfoCard('Rate per Hour', '₹${turfData['rate_per_hour']}'),
            _buildInfoCard('Country', turfData['country'] ?? 'N/A'),
            _buildInfoCard('State', turfData['state'] ?? 'N/A'),
            _buildInfoCard('City', turfData['city'] ?? 'N/A'),
            
            SizedBox(height: 20),
            Text('Turf Images:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 10),
            GridView.builder(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
              ),
              itemCount: (turfData['images'] as List).length,
              itemBuilder: (context, index) {
                return ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(turfData['images'][index], fit: BoxFit.cover),
                );
              },
            ),
            SizedBox(height: 20),
            Center(
              child: ElevatedButton(
                onPressed: () {
                  // Implement the book slots functionality here
                  _bookSlots(context);
                },
                child: Text('Book Slots'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  padding: EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(String title, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          Text(value, style: TextStyle(fontSize: 16)),
        ],
      ),
    );
  }

  void _bookSlots(BuildContext context) {
    // Replace this with your booking logic
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Booking slots for ${turfData['name']}'),
      ),
    );
  }
}
