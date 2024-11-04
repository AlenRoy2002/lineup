import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher_string.dart';

class ManageBookingsPage extends StatelessWidget {
  final String turfId;

  ManageBookingsPage({required this.turfId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Manage Bookings'),
        backgroundColor: Colors.green,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('bookings')
            .where('turfId', isEqualTo: turfId)
            .orderBy('date', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.calendar_today, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'No bookings found',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              var bookingDoc = snapshot.data!.docs[index];
              var booking = bookingDoc.data() as Map<String, dynamic>;
              DateTime bookingDate = booking['date'].toDate();
              DateTime createdAt = booking['createdAt']?.toDate() ?? DateTime.now();

              return Card(
                margin: EdgeInsets.all(8),
                child: ListTile(
                  title: Text(
                    'Booking #${bookingDoc.id.substring(0, 8)}',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Play Date: ${DateFormat('MMM d, yyyy').format(bookingDate)}',
                        style: TextStyle(color: Colors.black87),
                      ),
                      Text(
                        'Booked on: ${DateFormat('MMM d, yyyy HH:mm').format(createdAt)}',
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      ),
                    ],
                  ),
                  trailing: Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: booking['status'] == 'confirmed' 
                          ? Colors.green 
                          : booking['status'] == 'cancelled'
                              ? Colors.red
                              : Colors.orange,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      booking['status']?.toUpperCase() ?? 'PENDING',
                      style: TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ),
                  onTap: () {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                      ),
                      builder: (context) => Container(
                        padding: EdgeInsets.all(16),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Booking Details',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                IconButton(
                                  icon: Icon(Icons.close),
                                  onPressed: () => Navigator.pop(context),
                                ),
                              ],
                            ),
                            Divider(),
                            _buildDetailRow('Customer', booking['userName'] ?? 'Unknown'),
                            _buildDetailRow('Phone', booking['userPhone'] ?? 'N/A'),
                            _buildDetailRow('Sport', booking['sport']),
                            _buildDetailRow('Box', booking['box']),
                            _buildDetailRow('Booked Date', DateFormat('MMMM d, yyyy').format(bookingDate)),
                            _buildDetailRow('Time Slots', (booking['timeSlots'] as List).join(', ')),
                            _buildDetailRow('Amount', '₹${booking['totalAmount']}'),
                            _buildDetailRow('Booking Date', DateFormat('MMM d, yyyy HH:mm').format(createdAt)),
                            SizedBox(height: 16),
                            if (booking['status'] == 'pending')
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                children: [
                                  ElevatedButton(
                                    onPressed: () {
                                      _updateBookingStatus(bookingDoc.id, 'confirmed');
                                      Navigator.pop(context);
                                    },
                                    child: Text('Confirm'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.green,
                                    ),
                                  ),
                                  ElevatedButton(
                                    onPressed: () {
                                      _updateBookingStatus(bookingDoc.id, 'cancelled');
                                      Navigator.pop(context);
                                    },
                                    child: Text('Cancel'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.red,
                                    ),
                                  ),
                                ],
                              ),
                            if (booking['userPhone'] != null)
                              Center(
                                child: ElevatedButton(
                                  onPressed: () => _launchCall(booking['userPhone']),
                                  child: Text('Call Customer'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.blue,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '$label:',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          Text(
            value,
            style: TextStyle(fontSize: 16),
          ),
        ],
      ),
    );
  }

  Future<void> _updateBookingStatus(String bookingId, String newStatus) async {
    await FirebaseFirestore.instance
        .collection('bookings')
        .doc(bookingId)
        .update({'status': newStatus});
  }

  Future<void> _launchCall(String? phone) async {
    if (phone == null) return;
    final url = 'tel:$phone';
    if (await canLaunchUrlString(url)) {
      await launchUrlString(url);
    }
  }
}

