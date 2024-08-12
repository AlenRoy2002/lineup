import 'package:flutter/material.dart';

class TurfDetailsPage extends StatelessWidget {
  final Map<String, dynamic> turfData;

  TurfDetailsPage({required this.turfData});

  Widget _buildInfoCard(String title, String value) {
    return Card(
      margin: EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            Text(
              value,
              style: TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(turfData['name']),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(turfData['name'], style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            SizedBox(height: 20),
            _buildInfoCard('Rate per Hour', '₹${turfData['rate_per_hour']}'),
            _buildInfoCard('Country', turfData['country'] ?? 'N/A'),
            _buildInfoCard('State', turfData['state'] ?? 'N/A'),
            _buildInfoCard('City', turfData['city'] ?? 'N/A'),
            _buildInfoCard('Status', turfData['status']),
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
          ],
        ),
      ),
    );
  }
}
