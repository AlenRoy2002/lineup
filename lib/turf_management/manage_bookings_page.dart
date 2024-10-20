import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ManageBookingsPage extends StatelessWidget {
  final String turfId;

  ManageBookingsPage({required this.turfId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Manage Bookings'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('bookings')
            .where('turfId', isEqualTo: turfId)
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(child: Text('No bookings found'));
          }
          return ListView.builder(
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              var booking = snapshot.data!.docs[index].data() as Map<String, dynamic>;
              return ListTile(
                title: Text('Booking by ${booking['userId']}'),
                subtitle: Text('Date: ${booking['date'].toDate().toString().split(' ')[0]}'),
                trailing: Text('Status: ${booking['status']}'),
              );
            },
          );
        },
      ),
    );
  }
}

