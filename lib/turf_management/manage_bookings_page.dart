import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher_string.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:url_launcher/url_launcher.dart';

class ManageBookingsPage extends StatelessWidget {
  final String turfId;

  ManageBookingsPage({required this.turfId});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text('Manage Turf'),
          backgroundColor: Colors.green,
          bottom: TabBar(
            tabs: [
              Tab(icon: Icon(Icons.calendar_today), text: 'Bookings'),
              Tab(icon: Icon(Icons.star_rate), text: 'Reviews'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildBookingsTab(),
            _buildReviewsTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildBookingsTab() {
    return StreamBuilder<QuerySnapshot>(
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
              margin: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              elevation: 3,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: InkWell(
                onTap: () => _showBookingDetails(context, booking, bookingDoc.id),
                child: Padding(
                  padding: EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              booking['userName'] ?? 'Unknown User',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          SizedBox(width: 8),
                          _buildStatusChip(booking['status']),
                        ],
                      ),
                      SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                          SizedBox(width: 4),
                          Text(
                            DateFormat('MMM d, yyyy').format(bookingDate),
                            style: TextStyle(color: Colors.grey[700]),
                          ),
                        ],
                      ),
                      SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.access_time, size: 16, color: Colors.grey),
                          SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              (booking['timeSlots'] as List).join(', '),
                              style: TextStyle(color: Colors.grey[700]),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '₹${booking['totalAmount']}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                              fontSize: 16,
                            ),
                          ),
                          if (booking['hasReview'] == true)
                            Icon(Icons.rate_review, color: Colors.amber, size: 20),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildReviewsTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('reviews')
          .where('turfId', isEqualTo: turfId)
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Error loading reviews',
              style: TextStyle(color: Colors.red),
            ),
          );
        }

        // Debug print
        print('Reviews data: ${snapshot.data?.docs.length ?? 0} reviews found');

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.rate_review_outlined, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  'No reviews yet',
                  style: TextStyle(fontSize: 18, color: Colors.grey),
                ),
              ],
            ),
          );
        }

        // Calculate average rating
        double totalRating = 0;
        snapshot.data!.docs.forEach((doc) {
          final review = doc.data() as Map<String, dynamic>;
          totalRating += (review['rating'] ?? 0).toDouble();
        });
        double averageRating = totalRating / snapshot.data!.docs.length;

        return Container(
          color: Color(0xFF1E1E1E), // Dark theme background
          child: Column(
            children: [
              // Average Rating Header
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  border: Border(
                    bottom: BorderSide(
                      color: Colors.green.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                ),
                child: Column(
                  children: [
                    Text(
                      'Average Rating',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        RatingBarIndicator(
                          rating: averageRating,
                          itemBuilder: (context, index) => Icon(
                            Icons.star,
                            color: Colors.amber,
                          ),
                          itemCount: 5,
                          itemSize: 24.0,
                        ),
                        SizedBox(width: 8),
                        Text(
                          averageRating.toStringAsFixed(1),
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.amber,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 4),
                    Text(
                      '${snapshot.data!.docs.length} reviews',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              ),
              // Reviews List
              Expanded(
                child: ListView.builder(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    final reviewDoc = snapshot.data!.docs[index];
                    final review = reviewDoc.data() as Map<String, dynamic>;
                    // Debug print
                    print('Building review card for index $index: ${review['userName']}');
                    return _buildReviewCard(review);
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatusChip(String? status) {
    Color chipColor;
    switch (status?.toLowerCase()) {
      case 'confirmed':
        chipColor = Colors.green;
        break;
      case 'cancelled':
        chipColor = Colors.red;
        break;
      default:
        chipColor = Colors.orange;
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: chipColor.withOpacity(0.1),
        border: Border.all(color: chipColor),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        (status ?? 'PENDING').toUpperCase(),
        style: TextStyle(
          color: chipColor,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildReviewCard(Map<String, dynamic> review) {
    // Debug print
    print('Review data: $review');
    
    // Validate required fields
    if (review['rating'] == null || review['createdAt'] == null) {
      print('Warning: Review missing required fields');
      return SizedBox(); // Skip invalid reviews
    }

    return Card(
      margin: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Padding(
        padding: EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: Colors.green.withOpacity(0.1),
                  child: Text(
                    (review['userName'] ?? 'A')[0].toUpperCase(),
                    style: TextStyle(color: Colors.green),
                  ),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        review['userName'] ?? 'Anonymous',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        DateFormat('MMM d, yyyy').format(
                          (review['createdAt'] as Timestamp).toDate(),
                        ),
                        style: TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 8),
            RatingBarIndicator(
              rating: (review['rating'] ?? 0).toDouble(),
              itemBuilder: (context, index) => Icon(
                Icons.star,
                color: Colors.amber,
              ),
              itemCount: 5,
              itemSize: 20.0,
            ),
            if (review['review']?.isNotEmpty ?? false) ...[
              SizedBox(height: 8),
              Text(review['review']),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              '$label:',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey[400],
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: TextStyle(
                fontSize: 16,
                color: Colors.white,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeSlots(List<dynamic> timeSlots) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              'Time Slots:',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey[400],
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Wrap(
              alignment: WrapAlignment.end,
              spacing: 4,
              runSpacing: 4,
              children: timeSlots.map((slot) => Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.green.withOpacity(0.3)),
                ),
                child: Text(
                  slot.toString(),
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                  ),
                ),
              )).toList(),
            ),
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

  void _showBookingDetails(BuildContext context, Map<String, dynamic> booking, String bookingId) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.85,
          decoration: BoxDecoration(
            color: Color(0xFF1E1E1E), // Dark background
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: Column(
            children: [
              // Header
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.2),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Booking Details',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.close, color: Colors.white),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                    _buildStatusChip(booking['status']),
                  ],
                ),
              ),
              
              // Booking Details
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // User Details Section
                      _buildSectionTitle('User Details'),
                      _buildDetailRow('Name', booking['userName'] ?? 'Unknown'),
                      _buildDetailRow('Phone', booking['userPhone'] ?? 'Not provided'),
                      if (booking['userPhone'] != null)
                        Padding(
                          padding: EdgeInsets.symmetric(vertical: 8),
                          child: Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              SizedBox(
                                width: MediaQuery.of(context).size.width * 0.4,
                                child: ElevatedButton.icon(
                                  icon: Icon(Icons.phone, size: 20),
                                  label: Text('Call'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green,
                                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                  ),
                                  onPressed: () => _launchCall(booking['userPhone']),
                                ),
                              ),
                              SizedBox(
                                width: MediaQuery.of(context).size.width * 0.4,
                                child: ElevatedButton.icon(
                                  icon: Icon(Icons.chat, size: 20),
                                  label: Text('WhatsApp'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Color(0xFF25D366),
                                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                  ),
                                  onPressed: () => _launchWhatsApp(booking['userPhone']),
                                ),
                              ),
                            ],
                          ),
                        ),

                    Divider(height: 32, color: Colors.grey[800]),

                    // Booking Details Section
                    _buildSectionTitle('Booking Details'),
                    _buildDetailRow(
                      'Date',
                      DateFormat('MMM d, yyyy').format(booking['date'].toDate()),
                    ),
                    _buildTimeSlots(booking['timeSlots'] as List),
                    _buildDetailRow(
                      'Amount',
                      '₹${booking['totalAmount']}',
                    ),
                    _buildDetailRow(
                      'Payment Status',
                      booking['status'] ?? 'Not Available',
                    ),

                    Divider(height: 32, color: Colors.grey[800]),

                    // Review Section
                    if (booking['hasReview'] == true) ...[
                      _buildSectionTitle('Review'),
                      StreamBuilder<QuerySnapshot>(
                        stream: FirebaseFirestore.instance
                            .collection('reviews')
                            .where('bookingId', isEqualTo: bookingId)
                            .limit(1)
                            .snapshots(),
                        builder: (context, snapshot) {
                          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                            return SizedBox();
                          }

                          final reviewData = snapshot.data!.docs.first.data() as Map<String, dynamic>;
                          return Container(
                            padding: EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.green.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.green.withOpacity(0.3)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    RatingBarIndicator(
                                      rating: (reviewData['rating'] ?? 0).toDouble(),
                                      itemBuilder: (context, index) => Icon(
                                        Icons.star,
                                        color: Colors.amber,
                                      ),
                                      itemCount: 5,
                                      itemSize: 20.0,
                                    ),
                                    SizedBox(width: 8),
                                    Text(
                                      DateFormat('MMM d, yyyy').format(
                                        (reviewData['createdAt'] as Timestamp).toDate(),
                                      ),
                                      style: TextStyle(
                                        color: Colors.grey[400],
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                                if (reviewData['review']?.isNotEmpty ?? false) ...[
                                  SizedBox(height: 8),
                                  Text(
                                    reviewData['review'],
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          );
                        },
                      ),
                      SizedBox(height: 16),
                    ],

                    // Actions Section
                    if (booking['status'] == 'pending') ...[
                      Divider(height: 32, color: Colors.grey[800]),
                      _buildSectionTitle('Actions'),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              child: Text('Confirm Booking'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                              ),
                              onPressed: () {
                                _updateBookingStatus(bookingId, 'confirmed');
                                Navigator.pop(context);
                              },
                            ),
                          ),
                          SizedBox(width: 8),
                          Expanded(
                            child: ElevatedButton(
                              child: Text('Cancel Booking'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                              ),
                              onPressed: () {
                                _updateBookingStatus(bookingId, 'cancelled');
                                Navigator.pop(context);
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.green[400],
        ),
      ),
    );
  }

  Future<void> _launchWhatsApp(String? phone) async {
    if (phone == null) return;
    final url = 'https://wa.me/${phone.replaceAll(RegExp(r'[^0-9]'), '')}';
    if (await canLaunchUrlString(url)) {
      await launchUrlString(url);
    }
  }
}