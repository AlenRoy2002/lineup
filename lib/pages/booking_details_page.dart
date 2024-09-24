import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:geocoding/geocoding.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:fluttertoast/fluttertoast.dart';

class BookingDetailsPage extends StatefulWidget {
  final Map<String, dynamic> turfData;
  final DateTime selectedDate;
  final String selectedSport;
  final String selectedBox;
  final List<String> selectedTimeSlots;
  final double totalAmount;
  final String userId; // Add userId to the constructor

  BookingDetailsPage({
    required this.turfData,
    required this.selectedDate,
    required this.selectedSport,
    required this.selectedBox,
    required this.selectedTimeSlots,
    required this.totalAmount,
    required this.userId, // Initialize userId
  });

  @override
  _BookingDetailsPageState createState() => _BookingDetailsPageState();
}

class _BookingDetailsPageState extends State<BookingDetailsPage> {
  String locationName = 'Loading...';
  late Razorpay _razorpay;

  @override
  void initState() {
    super.initState();
    _getLocationName();
    _initializeRazorpay();
  }

  @override
  void dispose() {
    _razorpay.clear();
    super.dispose();
  }

  void _initializeRazorpay() {
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) {
    Fluttertoast.showToast(
      msg: "Payment Successful: ${response.paymentId}",
      toastLength: Toast.LENGTH_LONG,
    );
    _updateDatabase(response.paymentId!).then((_) {
      _showTicket(response.paymentId!);
    });
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    Fluttertoast.showToast(
      msg: "Payment Failed: ${response.message}",
      toastLength: Toast.LENGTH_LONG,
    );
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    Fluttertoast.showToast(
      msg: "External Wallet Selected: ${response.walletName}",
      toastLength: Toast.LENGTH_LONG,
    );
  }

  void _startPayment() {
    var options = {
      'key': 'rzp_test_egmkY4Yvg5qGl6',
      'amount': (widget.totalAmount * 100).toInt(), // Amount in paise
      'name': 'Turf Booking',
      'description': 'Booking for ${widget.turfData['name']}',
      'prefill': {'contact': '', 'email': ''},
      'external': {
        'wallets': ['paytm']
      }
    };

    try {
      _razorpay.open(options);
    } catch (e) {
      print("Error: $e");
    }
  }

  Future<void> _updateDatabase(String paymentId) async {
    try {
      await FirebaseFirestore.instance.collection('bookings').add({
        'turfId': widget.turfData['id'],
        'userId': widget.userId, // Use userId from widget
        'date': widget.selectedDate,
        'sport': widget.selectedSport,
        'box': widget.selectedBox,
        'timeSlots': widget.selectedTimeSlots,
        'totalAmount': widget.totalAmount,
        'paymentId': paymentId,
        'status': 'confirmed',
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Navigate to a confirmation page or back to home
      Navigator.of(context).popUntil((route) => route.isFirst);
    } catch (e) {
      print("Error updating database: $e");
      Fluttertoast.showToast(
        msg: "Error updating booking. Please contact support.",
        toastLength: Toast.LENGTH_LONG,
      );
    }
  }

  Future<void> _getLocationName() async {
    try {
      GeoPoint location = widget.turfData['location'];
      String placeName = await _getPlaceNameFromCoordinates(location);
      setState(() {
        locationName = placeName;
      });
    } catch (e) {
      print('Error getting location name: $e');
      setState(() {
        locationName = 'Unknown location';
      });
    }
  }

  Future<String> _getPlaceNameFromCoordinates(GeoPoint location) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        location.latitude,
        location.longitude
      );
      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        return '${place.street}, ${place.subLocality}, ${place.locality}, ${place.administrativeArea}, ${place.country}';
      }
    } catch (e) {
      print('Error getting place name: $e');
    }
    return 'Unknown location';
  }

  void _showTicket(String paymentId) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Booking Confirmed'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text('Thank you for your booking!'),
                SizedBox(height: 10),
                Text('Turf: ${widget.turfData['name']}'),
                Text('Date: ${DateFormat('MMMM d, yyyy').format(widget.selectedDate)}'),
                Text('Sport: ${widget.selectedSport}'),
                Text('Box: ${widget.selectedBox}'),
                Text('Time Slots: ${widget.selectedTimeSlots.join(', ')}'),
                Text('Total Amount: ₹${widget.totalAmount}'),
                SizedBox(height: 10),
                Text('Payment ID: $paymentId'),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Back to Home'),
              onPressed: () {
                Navigator.of(context).popUntil((route) => route.isFirst);
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDarkMode ? Colors.white : Colors.black;
    final backgroundColor = isDarkMode ? Colors.grey[900] : Colors.white;

    return Scaffold(
      appBar: AppBar(
        title: Text('Booking Details'),
        backgroundColor: Colors.green,
      ),
      body: Container(
        color: backgroundColor,
        child: SingleChildScrollView(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionTitle('Turf Details', textColor),
              _buildDetailRow('Name', widget.turfData['name'], textColor),
              _buildDetailRow('Location', locationName, textColor),
              SizedBox(height: 20),
              _buildSectionTitle('Booking Details', textColor),
              _buildDetailRow('Date', DateFormat('MMMM d, yyyy').format(widget.selectedDate), textColor),
              _buildDetailRow('Sport', widget.selectedSport, textColor),
              _buildDetailRow('Box', widget.selectedBox, textColor),
              _buildDetailRow('Time Slots', widget.selectedTimeSlots.join(', '), textColor),
              SizedBox(height: 20),
              _buildSectionTitle('Bill Details', textColor),
              _buildDetailRow('Number of Slots', '${widget.selectedTimeSlots.length}', textColor),
              _buildDetailRow('Price per Slot', '₹${_getBoxPrice()}', textColor),
              _buildDetailRow('Total Amount', '₹${widget.totalAmount}', textColor, isTotal: true),
              SizedBox(height: 30),
              Center(
                child: ElevatedButton(
                  onPressed: _startPayment,
                  child: Text('Proceed to Payment'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                    textStyle: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, Color textColor) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Text(
        title,
        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: textColor),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, Color textColor, {bool isTotal = false}) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 16, color: textColor)),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              color: isTotal ? Colors.green : textColor,
            ),
          ),
        ],
      ),
    );
  }

  double _getBoxPrice() {
    return double.parse((widget.turfData['boxes'] as List)
        .firstWhere((box) => 'Box ${box['number']}' == widget.selectedBox)['price'].toString());
  }
}
