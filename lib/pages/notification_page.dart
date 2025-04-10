// ignore_for_file: use_super_parameters

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher_string.dart';

class NotificationPage extends StatefulWidget {
  final String userId;

  const NotificationPage({Key? key, required this.userId}) : super(key: key);

  @override
  State<NotificationPage> createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> with AutomaticKeepAliveClientMixin {
  late Stream<QuerySnapshot> bookingsStream;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _initializeBookingsStream();
    print('NotificationPage initialized for user: ${widget.userId}');
  }

  void _initializeBookingsStream() {
    bookingsStream = FirebaseFirestore.instance
        .collection('bookings')
        .where('userId', isEqualTo: widget.userId)
        .snapshots();
    
    bookingsStream.listen(
      (snapshot) {
        print('Debug: Got ${snapshot.docs.length} bookings');
        snapshot.docs.forEach((doc) {
          print('Debug: Booking data - ${doc.data()}');
        });
      },
      onError: (error) => print('Debug: Stream error - $error'),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.green,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'My Bookings',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              'View and manage your turf bookings',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.filter_list),
            onPressed: () {
              // TODO: Implement filtering
            },
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: bookingsStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.sports_soccer_outlined, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'No bookings yet',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[800],
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Book your favorite turf now!',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
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
              booking['bookingId'] = bookingDoc.id;
              DateTime bookingDate = booking['date'].toDate();

              return Card(
                margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                elevation: 3,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Stack(
                  children: [
                    InkWell(
                      onTap: () => _showBookingTicket(context, booking),
                      child: Container(
                        padding: EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        booking['turfName'] ?? 'Unknown Turf',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 18,
                                          color: Colors.green[800],
                                        ),
                                      ),
                                      SizedBox(height: 4),
                                      Text(
                                        'Box ${booking['box']} • ${booking['sport']}',
                                        style: TextStyle(
                                          color: Colors.grey[600],
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: booking['status'] == 'confirmed' 
                                        ? Colors.green.withOpacity(0.1)
                                        : booking['status'] == 'cancelled'
                                            ? Colors.red.withOpacity(0.1)
                                            : Colors.orange.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: booking['status'] == 'confirmed' 
                                          ? Colors.green
                                          : booking['status'] == 'cancelled'
                                              ? Colors.red
                                              : Colors.orange,
                                    ),
                                  ),
                                  child: Text(
                                    booking['status']?.toUpperCase() ?? 'PENDING',
                                    style: TextStyle(
                                      color: booking['status'] == 'confirmed' 
                                          ? Colors.green
                                          : booking['status'] == 'cancelled'
                                              ? Colors.red
                                              : Colors.orange,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 16),
                            Row(
                              children: [
                                Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
                                SizedBox(width: 8),
                                Text(
                                  DateFormat('MMM d, yyyy').format(bookingDate),
                                  style: TextStyle(
                                    color: Colors.grey[800],
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                SizedBox(width: 16),
                                Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
                                SizedBox(width: 8),
                                Text(
                                  (booking['timeSlots'] as List).join(', '),
                                  style: TextStyle(
                                    color: Colors.grey[800],
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  '₹${booking['totalAmount']}',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green[700],
                                  ),
                                ),
                                TextButton(
                                  onPressed: () => _showBookingTicket(context, booking),
                                  child: Row(
                                    children: [
                                      Text(
                                        'View Details',
                                        style: TextStyle(
                                          color: Colors.green,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Icon(Icons.arrow_forward_ios, size: 14, color: Colors.green),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            if (_isBookingCompleted(bookingDate, List<String>.from(booking['timeSlots'])))
                              Padding(
                                padding: EdgeInsets.only(top: 8),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    if (booking['hasReview'] != true)
                                      TextButton.icon(
                                        icon: Icon(Icons.rate_review, color: Colors.amber),
                                        label: Text(
                                          'Leave Review',
                                          style: TextStyle(
                                            color: Colors.amber,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        onPressed: () => _showReviewDialog(context, booking),
                                      )
                                    else
                                      TextButton.icon(
                                        icon: Icon(Icons.visibility, color: Colors.blue),
                                        label: Text(
                                          'View Review',
                                          style: TextStyle(
                                            color: Colors.blue,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        onPressed: () => _showViewReviewDialog(context, booking),
                                      ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                    if (_isWithinTwoHours(bookingDate, List<String>.from(booking['timeSlots'])) && 
                        booking['status'] == 'confirmed')
                      Positioned(
                        top: 0,
                        left: 0,
                        right: 0,
                        child: Container(
                          padding: EdgeInsets.symmetric(vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(15),
                              topRight: Radius.circular(15),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.access_alarm,
                                color: Colors.white,
                                size: 16,
                              ),
                              SizedBox(width: 8),
                              Text(
                                'Upcoming booking in less than 2 hours!',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _showBookingTicket(BuildContext context, Map<String, dynamic> booking) {
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
              topLeft: Radius.circular(25.0),
              topRight: Radius.circular(25.0),
            ),
          ),
          child: SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header with glowing effect
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(15),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.green.withOpacity(0.2),
                          blurRadius: 10,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Booking Details',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.green[400],
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.close, color: Colors.white70),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                  ),
                  Divider(color: Colors.green[800], thickness: 1),

                  // Turf Info Section
                  Container(
                    margin: EdgeInsets.symmetric(vertical: 10),
                    padding: EdgeInsets.all(15),
                    decoration: BoxDecoration(
                      color: Color(0xFF2A2A2A),
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(color: Colors.green[800]!, width: 1),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          booking['turfName'] ?? 'Unknown Turf',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.green[400],
                          ),
                        ),
                        SizedBox(height: 10),
                        _buildDarkDetailRow(Icons.sports_soccer, 'Sport', booking['sport']),
                        _buildDarkDetailRow(Icons.grid_view, 'Box', booking['box']),
                      ],
                    ),
                  ),

                  // Date and Time Section
                  Container(
                    margin: EdgeInsets.symmetric(vertical: 10),
                    padding: EdgeInsets.all(15),
                    decoration: BoxDecoration(
                      color: Color(0xFF2A2A2A),
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(color: Colors.blue[800]!, width: 1),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Schedule',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue[400],
                          ),
                        ),
                        SizedBox(height: 10),
                        _buildDarkDetailRow(
                          Icons.calendar_today,
                          'Date',
                          DateFormat('MMMM d, yyyy').format(booking['date'].toDate()),
                        ),
                        _buildDarkDetailRow(
                          Icons.access_time,
                          'Time Slots',
                          (booking['timeSlots'] as List).join(', '),
                        ),
                      ],
                    ),
                  ),

                  // Payment Section
                  Container(
                    margin: EdgeInsets.symmetric(vertical: 10),
                    padding: EdgeInsets.all(15),
                    decoration: BoxDecoration(
                      color: Color(0xFF2A2A2A),
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(color: Colors.orange[800]!, width: 1),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Payment Details',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.orange[400],
                          ),
                        ),
                        SizedBox(height: 10),
                        _buildDarkDetailRow(
                          Icons.payment,
                          'Amount',
                          '₹${booking['totalAmount']}',
                        ),
                        _buildDarkDetailRow(
                          Icons.info_outline,
                          'Status',
                          booking['status']?.toUpperCase() ?? 'PENDING',
                          valueColor: booking['status'] == 'confirmed'
                              ? Colors.green[400]
                              : booking['status'] == 'cancelled'
                                  ? Colors.red[400]
                                  : Colors.orange[400],
                        ),
                      ],
                    ),
                  ),

                  // Contact Section
                  Container(
                    margin: EdgeInsets.symmetric(vertical: 10),
                    padding: EdgeInsets.all(15),
                    decoration: BoxDecoration(
                      color: Color(0xFF2A2A2A),
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(color: Colors.purple[800]!, width: 1),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Contact Information',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.purple[400],
                          ),
                        ),
                        SizedBox(height: 10),
                        _buildDarkDetailRow(
                          Icons.person_outline,
                          'Owner',
                          booking['ownerName'] ?? 'Unknown',
                        ),
                        _buildDarkDetailRow(
                          Icons.phone,
                          'Phone',
                          booking['ownerPhone'] ?? 'N/A',
                        ),
                      ],
                    ),
                  ),

                  // Action Buttons
                  if (booking['status'] == 'confirmed')
                    Padding(
                      padding: EdgeInsets.symmetric(vertical: 20),
                      child: Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              icon: Icon(Icons.phone, color: Colors.black),
                              label: Text('Call Owner', 
                                style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                              onPressed: () => _launchCall(booking['ownerPhone']),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green[400],
                                padding: EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                            ),
                          ),
                          SizedBox(width: 10),
                          Expanded(
                            child: ElevatedButton.icon(
                              icon: Icon(Icons.message, color: Colors.black),
                              label: Text('WhatsApp', 
                                style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                              onPressed: () => _launchWhatsApp(booking['ownerPhone']),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green[400],
                                padding: EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  if (_isWithinTwoHours(booking['date'].toDate(), 
                      List<String>.from(booking['timeSlots'])) && 
                      booking['status'] == 'confirmed')
                    Container(
                      margin: EdgeInsets.only(bottom: 20),
                      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.red[800]!, width: 1),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.warning_amber_rounded,
                            color: Colors.red[400],
                            size: 24,
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Upcoming Booking Alert!',
                                  style: TextStyle(
                                    color: Colors.red[400],
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  'This booking is scheduled to start in less than 2 hours.',
                                  style: TextStyle(
                                    color: Colors.red[300],
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // New dark theme detail row builder
  Widget _buildDarkDetailRow(IconData icon, String label, String value, {Color? valueColor}) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey[400]),
          SizedBox(width: 10),
          Text(
            '$label:',
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 16,
            ),
          ),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: valueColor ?? Colors.white,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _launchCall(String? phone) async {
    if (phone == null) return;
    final url = 'tel:$phone';
    if (await canLaunchUrlString(url)) {
      await launchUrlString(url);
    }
  }

  Future<void> _launchWhatsApp(String? phone) async {
    if (phone == null) return;
    final url = 'https://wa.me/$phone';
    if (await canLaunchUrlString(url)) {
      await launchUrlString(url);
    }
  }

  // Add this method to check if booking is within 2 hours
  bool _isWithinTwoHours(DateTime bookingDate, List<String> timeSlots) {
    if (timeSlots.isEmpty) return false;
    
    try {
      // Get the first time slot
      String firstSlot = timeSlots.first;
      
      // Convert 12-hour format to 24-hour format
      DateFormat inputFormat = DateFormat('h:mm a');
      DateFormat outputFormat = DateFormat('HH:mm');
      DateTime parsedTime = inputFormat.parse(firstSlot);
      String militaryTime = outputFormat.format(parsedTime);
      
      // Split the time into hours and minutes
      List<String> timeParts = militaryTime.split(':');
      int startHour = int.parse(timeParts[0]);
      int startMinute = int.parse(timeParts[1]);
      
      // Create DateTime for the start of the booking
      DateTime bookingStartTime = DateTime(
        bookingDate.year,
        bookingDate.month,
        bookingDate.day,
        startHour,
        startMinute,
      );
      
      // Get current time
      DateTime now = DateTime.now();
      
      // Calculate difference
      Duration difference = bookingStartTime.difference(now);
      
      // Debug prints
      print('Debug - First time slot: $firstSlot');
      print('Debug - Military time: $militaryTime');
      print('Debug - Booking date: $bookingDate');
      print('Debug - Booking start time: $bookingStartTime');
      print('Debug - Current time: $now');
      print('Debug - Time difference (hours): ${difference.inHours}');
      
      // Return true if booking is within next 2 hours and hasn't started yet
      return difference.inHours >= 0 && difference.inHours <= 2;
    } catch (e) {
      print('Error checking within two hours: $e');
      return false;
    }
  }

  // Add this method to check if booking is completed
  bool _isBookingCompleted(DateTime bookingDate, List<String> timeSlots) {
    if (timeSlots.isEmpty) return false;
    
    try {
      // Get the last time slot
      String lastSlot = timeSlots.last;
      
      // Convert 12-hour format to 24-hour format
      DateFormat inputFormat = DateFormat('h:mm a');
      DateFormat outputFormat = DateFormat('HH:mm');
      DateTime parsedTime = inputFormat.parse(lastSlot);
      String militaryTime = outputFormat.format(parsedTime);
      
      // Split the time into hours and minutes
      List<String> timeParts = militaryTime.split(':');
      int lastHour = int.parse(timeParts[0]);
      int lastMinute = int.parse(timeParts[1]);
      
      // Create DateTime for the end of the booking
      DateTime bookingEndTime = DateTime(
        bookingDate.year,
        bookingDate.month,
        bookingDate.day,
        lastHour,
        lastMinute,
      );
      
      // Compare with current time
      DateTime now = DateTime.now();
      
      // Debug prints
      print('Debug - Last time slot: $lastSlot');
      print('Debug - Military time: $militaryTime');
      print('Debug - Booking date: $bookingDate');
      print('Debug - Booking end time: $bookingEndTime');
      print('Debug - Current time: $now');
      print('Debug - Is completed: ${now.isAfter(bookingEndTime)}');
      
      return now.isAfter(bookingEndTime);
    } catch (e) {
      print('Error checking booking completion: $e');
      return false;
    }
  }

  // Add this method to show review dialog
  void _showReviewDialog(BuildContext context, Map<String, dynamic> booking) {
    // Don't show dialog if booking has a review
    if (booking['hasReview'] == true) {
      return;
    }

    final TextEditingController reviewController = TextEditingController();
    double rating = 3.0;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: Color(0xFF2A2A2A),
              title: Text(
                'Review Your Experience',
                style: TextStyle(color: Colors.white),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (index) {
                      return IconButton(
                        icon: Icon(
                          index < rating ? Icons.star : Icons.star_border,
                          color: Colors.amber,
                          size: 32,
                        ),
                        onPressed: () {
                          setState(() {
                            rating = index + 1.0;
                          });
                        },
                      );
                    }),
                  ),
                  SizedBox(height: 16),
                  TextField(
                    controller: reviewController,
                    maxLines: 3,
                    style: TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Share your experience...',
                      hintStyle: TextStyle(color: Colors.grey),
                      border: OutlineInputBorder(),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.grey),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.amber),
                      ),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  child: Text('Cancel', style: TextStyle(color: Colors.grey)),
                  onPressed: () => Navigator.pop(context),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.amber,
                  ),
                  child: Text('Submit'),
                  onPressed: () => _submitReview(
                    context,
                    booking,
                    rating,
                    reviewController.text,
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // Add this method to submit the review
  Future<void> _submitReview(
    BuildContext context,
    Map<String, dynamic> booking,
    double rating,
    String review,
  ) async {
    try {
      print('Debug - Starting review submission');
      print('Debug - Booking data: $booking');

      // Get user data
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .get();
      final userData = userDoc.data() as Map<String, dynamic>;

      // Create review document
      final reviewData = {
        'userId': widget.userId,
        'userName': userData['name'] ?? 'Anonymous',
        'turfId': booking['turfId'],
        'turfName': booking['turfName'],
        'bookingId': booking['bookingId'],
        'rating': rating,
        'review': review,
        'createdAt': FieldValue.serverTimestamp(),
      };

      print('Debug - Review data to be submitted: $reviewData');

      await FirebaseFirestore.instance
          .collection('reviews')
          .add(reviewData);

      // Update booking
      await FirebaseFirestore.instance
          .collection('bookings')
          .doc(booking['bookingId'])
          .update({
            'hasReview': true,
          });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Thank you for your review!'),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pop(context);
    } catch (e) {
      print('Error submitting review: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to submit review. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showViewReviewDialog(BuildContext context, Map<String, dynamic> booking) {
    FirebaseFirestore.instance
        .collection('reviews')
        .where('bookingId', isEqualTo: booking['bookingId'])
        .get()
        .then((querySnapshot) {
      if (querySnapshot.docs.isNotEmpty) {
        final reviewData = querySnapshot.docs.first.data();
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              backgroundColor: Color(0xFF2A2A2A),
              title: Text(
                'Your Review',
                style: TextStyle(color: Colors.white),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      RatingBarIndicator(
                        rating: (reviewData['rating'] ?? 0).toDouble(),
                        itemBuilder: (context, index) => Icon(
                          Icons.star,
                          color: Colors.amber,
                        ),
                        itemCount: 5,
                        itemSize: 24.0,
                      ),
                    ],
                  ),
                  SizedBox(height: 16),
                  Text(
                    reviewData['review'] ?? '',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Posted on: ${_formatDate(reviewData['createdAt'])}',
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  child: Text('Close', style: TextStyle(color: Colors.white)),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            );
          },
        );
      }
    });
  }

  // Add this method to format dates
  String _formatDate(dynamic date) {
    if (date == null) return '';
    
    if (date is Timestamp) {
      return DateFormat('MMM d, yyyy, h:mm a').format(date.toDate());
    }
    
    if (date is DateTime) {
      return DateFormat('MMM d, yyyy, h:mm a').format(date);
    }
    
    return '';
  }
}
