// ignore_for_file: unused_import, dead_code

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:lineup/pages/booking_details_page.dart';

class SlotBookingPage extends StatefulWidget {
  final Map<String, dynamic> turfData;
  final String userId; // Add userId to the constructor

  SlotBookingPage({required this.turfData, required this.userId});

  @override
  _SlotBookingPageState createState() => _SlotBookingPageState();
}

class _SlotBookingPageState extends State<SlotBookingPage> {
  late DateTime selectedDate;
  String? selectedSport;
  String? selectedBox;
  List<String> selectedTimeSlots = [];
  double totalAmount = 0;
  List<DateTime> dateList = [];
  List<String> availableSports = [];
  List<String> availableTimeSlots = [];
  List<String> bookedTimeSlots = [];

  @override
  void initState() {
    super.initState();
    selectedDate = DateTime.now();
    _generateDateList();
    _getAvailableSports();
    _getAvailableTimeSlots();
  }

  void _generateDateList() {
    dateList = List.generate(10, (index) => DateTime.now().add(Duration(days: index)));
  }

  void _getAvailableSports() {
    availableSports = List<String>.from(widget.turfData['sports_categories']);
  }

  Future<void> _getAvailableTimeSlots() async {
    final startTime = _parseTime(widget.turfData['start_time']);
    final endTime = _parseTime(widget.turfData['end_time']);
    final slots = <String>[];
    var currentTime = startTime;

    // Get current date and time
    DateTime now = DateTime.now();
    
    // If selected date is today, start from next hour
    DateTime minimumTime;
    if (selectedDate.year == now.year && 
        selectedDate.month == now.month && 
        selectedDate.day == now.day) {
      // Round up to the next hour and add 1 hour buffer
      minimumTime = DateTime(
        now.year, 
        now.month, 
        now.day, 
        now.hour + 1, 
        0
      ).add(Duration(hours: 1));
    } else {
      // If future date, start from turf's opening time
      minimumTime = DateTime(
        selectedDate.year,
        selectedDate.month,
        selectedDate.day,
        startTime.hour,
        startTime.minute
      );
    }

    // Create slots
    while (currentTime.isBefore(endTime)) {
      DateTime slotDateTime = DateTime(
        selectedDate.year,
        selectedDate.month,
        selectedDate.day,
        currentTime.hour,
        currentTime.minute
      );

      // Only add future slots
      if (slotDateTime.isAfter(minimumTime) || slotDateTime.isAtSameMomentAs(minimumTime)) {
        slots.add(DateFormat('h:mm a').format(currentTime));
      }
      
      currentTime = currentTime.add(Duration(hours: 1));
    }

    // Fetch booked slots from the database
    await _getBookedTimeSlots();

    // Filter out booked slots
    setState(() {
      availableTimeSlots = slots.where((slot) => !bookedTimeSlots.contains(slot)).toList();
    });
  }

  Future<void> _getBookedTimeSlots() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('bookings')
          .where('turfId', isEqualTo: widget.turfData['id'])
          .where('date', isEqualTo: selectedDate)
          .get();

      bookedTimeSlots = snapshot.docs
          .expand((doc) => List<String>.from(doc['timeSlots']))
          .toList();
    } catch (e) {
      print('Error fetching booked time slots: $e');
    }
  }

  DateTime _parseTime(String time) {
    final parts = time.split(':');
    return DateTime(2022, 1, 1, int.parse(parts[0]), int.parse(parts[1]));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Book a Slot'),
        backgroundColor: Colors.green,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 20),
            _buildDateSlider(),
            SizedBox(height: 20),
            _buildSportSelection(),
            SizedBox(height: 20),
            if (selectedSport != null) _buildBoxSelection(),
            SizedBox(height: 20),
            if (selectedBox != null) _buildTimeSlotSelection(),
            SizedBox(height: 30),
            if (selectedTimeSlots.isNotEmpty) _buildBookingButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildDateSlider() {
    return Container(
      height: 100,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: dateList.length,
        itemBuilder: (context, index) {
          final date = dateList[index];
          final isSelected = date.day == selectedDate.day && date.month == selectedDate.month;
          return GestureDetector(
            onTap: () {
              setState(() {
                selectedDate = date;
                _getAvailableTimeSlots(); // Refresh available time slots for the selected date
              });
            },
            child: Container(
              width: 70,
              margin: EdgeInsets.symmetric(horizontal: 5),
              decoration: BoxDecoration(
                color: isSelected ? Colors.green : Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.green),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    DateFormat('dd').format(date),
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? Colors.white : Colors.black,
                    ),
                  ),
                  Text(
                    DateFormat('MMM').format(date),
                    style: TextStyle(
                      fontSize: 14,
                      color: isSelected ? Colors.white : Colors.black,
                    ),
                  ),
                  Text(
                    DateFormat('E').format(date),
                    style: TextStyle(
                      fontSize: 14,
                      color: isSelected ? Colors.white : Colors.black,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSportSelection() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Select Sport:',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 10),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: availableSports.map((sport) {
              final isSelected = sport == selectedSport;
              return GestureDetector(
                onTap: () {
                  setState(() {
                    selectedSport = sport;
                    selectedBox = null;
                    selectedTimeSlots.clear();
                    _updateTotalAmount();
                  });
                },
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.green : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.green),
                  ),
                  child: Text(
                    sport,
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.black,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildBoxSelection() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Select Box:',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 10),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: (widget.turfData['boxes'] as List).map((box) {
              final isSelected = 'Box ${box['number']}' == selectedBox;
              return GestureDetector(
                onTap: () {
                  setState(() {
                    selectedBox = 'Box ${box['number']}';
                    selectedTimeSlots.clear();
                    _updateTotalAmount();
                  });
                },
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.green : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.green),
                  ),
                  child: Text(
                    'Box ${box['number']} - ₹${box['price']}',
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.black,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeSlotSelection() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Select Time Slot(s):',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 10),
          if (availableTimeSlots.isEmpty)
            Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  selectedDate.year == DateTime.now().year &&
                          selectedDate.month == DateTime.now().month &&
                          selectedDate.day == DateTime.now().day
                      ? 'No slots available for today. Please book at least 2 hours in advance.'
                      : 'No slots available for this date.',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            )
          else
            GridView.builder(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                childAspectRatio: 2,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
              ),
              itemCount: availableTimeSlots.length,
              itemBuilder: (context, index) {
                final time = availableTimeSlots[index];
                final isSelected = selectedTimeSlots.contains(time);
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      if (isSelected) {
                        selectedTimeSlots.remove(time);
                      } else {
                        selectedTimeSlots.add(time);
                      }
                      _updateTotalAmount();
                    });
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.green : Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 4,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        time,
                        style: TextStyle(
                          color: isSelected ? Colors.white : Colors.black,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  void _updateTotalAmount() {
    if (selectedBox != null) {
      double boxPrice = double.parse((widget.turfData['boxes'] as List)
          .firstWhere((box) => 'Box ${box['number']}' == selectedBox)['price'].toString());
      totalAmount = boxPrice * selectedTimeSlots.length;
    } else {
      totalAmount = 0;
    }
  }

  Widget _buildBookingButton() {
    return Center(
      child: ElevatedButton(
        onPressed: selectedTimeSlots.isNotEmpty ? () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => BookingDetailsPage(
                turfData: widget.turfData,
                selectedDate: selectedDate,
                selectedSport: selectedSport!,
                selectedBox: selectedBox!,
                selectedTimeSlots: selectedTimeSlots,
                totalAmount: totalAmount,
                userId: widget.userId, // Pass userId to BookingDetailsPage
              ),
            ),
          );
        } : null,
        child: Text('View Booking Details'),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green,
          padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          textStyle: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
