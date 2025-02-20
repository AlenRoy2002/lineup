// ignore_for_file: prefer_const_constructors, unused_import

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:lineup/admin/adminpage.dart';
import 'package:lineup/pages/auth_page.dart';
import 'package:lineup/pages/profileeditscreen.dart';

import 'package:lineup/pages/turfdetailspage_user.dart';
import 'package:lineup/turf_management/turfmanagementpage.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:intl/intl.dart';

import 'package:url_launcher/url_launcher_string.dart';
import 'package:lineup/pages/notification_page.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class Homepage extends StatefulWidget {
  const Homepage({super.key});

  @override
  State<Homepage> createState() => _HomepageState();
}

class _HomepageState extends State<Homepage> {
  final user = FirebaseAuth.instance.currentUser!;
  late Map<String, dynamic> userData = {};
  int _selectedIndex = 0;
  late Stream<List<Map<String, dynamic>>> turfStream;
  bool isLoadingTurfs = true;
  String _currentLocationName = 'Fetching location...';

  // Add this list of image URLs for the slider
  final List<String> imageSliderUrls = [
    'images/0001.jpg',
    'images/0002.jpg',
    'images/0003.jpg',
    'images/0004.jpg',
  ];

  // Add these stream controllers at the top of the class
  late Stream<QuerySnapshot> bookingsStream;
  bool isNotificationVisible = false;

  // Add these new variables
  final TextEditingController _chatController = TextEditingController();
  bool _isChatOpen = false;

  // Add these to your existing variables
  List<Map<String, dynamic>> chatMessages = [];
  bool _isProcessingMessage = false;

  // Update the API variables
  final String _apiKey = "g4a-THXUe7zcObEXf99p5OtsfLTHSTpFaonnad7"; // Your actual API key
  final String _baseUrl = "https://api.gpt4-all.xyz/v1";

  // Add these variables at the class level
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    _fetchUserData();
    _initializeTurfStream();
    _getCurrentLocation();
    _initializeBookingsStream();
    print('API Key: $_apiKey');
    print('Base URL: $_baseUrl');
  }

  Future<void> _fetchUserData() async {
    try {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      setState(() {
        userData = userDoc.data() as Map<String, dynamic>;
      });
    } catch (e) {
      _showErrorDialog("Failed to load user data: $e");
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
        return '${place.locality}, ${place.administrativeArea}';
      }
    } catch (e) {
      print('Error getting place name: $e');
    }
    return 'Unknown location';
  }

  void _initializeTurfStream() {
    turfStream = FirebaseFirestore.instance
        .collection('turfs')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) {
              Map<String, dynamic> data = doc.data();
              data['id'] = doc.id;
              return data;
            })
            .toList());
  }

  Future<void> signUserOut() async {
    try {
      await FirebaseAuth.instance.signOut();
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => AuthPage()),
        (route) => false,
      );
    } catch (e) {
      _showErrorDialog("Failed to sign out: $e");
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Error"),
        content: Text(message),
        actions: [
          TextButton(
            child: Text("OK"),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  void _initializeBookingsStream() {
    bookingsStream = FirebaseFirestore.instance
        .collection('bookings')
        .where('userId', isEqualTo: user.uid)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
      if (index == 2) { // Notifications tab
        isNotificationVisible = true;
      }
    });
  }

  Widget _buildContent() {
    return IndexedStack(
      index: _selectedIndex,
      children: [
        _buildHomeContent(),
        Center(child: Text('Search Content', style: TextStyle(fontSize: 24))),
        NotificationPage(key: PageStorageKey('notifications'), userId: user.uid),
        _buildProfileContent(),
      ],
    );
  }

  Widget _buildHomeContent() {
    return Column(
      children: [
        _buildImageSlider(),
        Expanded(child: _buildTurfList()),
      ],
    );
  }

  Widget _buildImageSlider() {
    return CarouselSlider(
      options: CarouselOptions(
        height: 200.0,
        enlargeCenterPage: true,
        autoPlay: true,
        aspectRatio: 16 / 9,
        autoPlayCurve: Curves.fastOutSlowIn,
        enableInfiniteScroll: true,
        autoPlayAnimationDuration: Duration(milliseconds: 800),
        viewportFraction: 0.8,
      ),
      items: imageSliderUrls.map((url) {
        return Builder(
          builder: (BuildContext context) {
            return Container(
              width: MediaQuery.of(context).size.width,
              margin: EdgeInsets.symmetric(horizontal: 5.0),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8.0),
                image: DecorationImage(
                  image: AssetImage(url),
                  fit: BoxFit.cover,
                ),
              ),
            );
          },
        );
      }).toList(),
    );
  }
  

  Widget _buildProfileContent() {
    return userData.isEmpty
        ? Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
            child: Column(
              children: [
                Container(
                  height: 200,
                  child: SafeArea(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircleAvatar(
                            radius: 60,
                            backgroundColor: Colors.white,
                            backgroundImage: userData['profile_image_url'] != null
                                ? NetworkImage(userData['profile_image_url'])
                                : null,
                            child: userData['profile_image_url'] == null
                                ? Icon(Icons.person, size: 60, color: Colors.green)
                                : null,
                          ),
                          SizedBox(height: 10),
                          Text(
                            userData['name'] ?? 'User',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                             
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildInfoRow(Icons.email, 'Email', userData['email'] ?? 'N/A'),
                          _buildInfoRow(Icons.phone, 'Phone', userData['phone_number'] ?? 'N/A'),
                          _buildInfoRow(Icons.person, 'Role', userData['role'] ?? 'N/A'),
                          _buildInfoRow(Icons.location_on, 'Location', _currentLocationName),
                        ],
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 20),
                if (userData['role'] == 'Admin')
                  _buildActionButton('Admin Panel', () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => AdminPage()),
                    );
                  }, Colors.blue),
                if (userData['role'] == 'Turf Owner')
                  _buildActionButton('Manage Turf', () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => TurfHomePage(userId: user.uid)),
                    );
                  }, Colors.green),
                SizedBox(height: 10),
                _buildActionButton('Edit Profile', () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ProfileEditScreen(
                        userData: userData,
                        onProfileUpdated: _fetchUserData,
                      ),
                    ),
                  );
                }, Colors.green),
                SizedBox(height: 10),
                _buildActionButton('Sign Out', signUserOut, Colors.red),
                SizedBox(height: 20),
              ],
            ),
          );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, color: Colors.green, size: 24),
          SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(String label, VoidCallback onPressed, Color color) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onPressed,
        child: Text(label),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          padding: EdgeInsets.symmetric(vertical: 12),
          textStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
    );
    
  }

  Widget _buildTurfListItem(Map<String, dynamic> turf, String locationName) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      elevation: 5,
      child: ListTile(
        contentPadding: const EdgeInsets.all(16.0),
        leading: CircleAvatar(
          radius: 30,
          backgroundImage: NetworkImage(turf['images'][0]),
        ),
        title: Text(
          turf['name'] ?? 'Unknown',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(locationName),
        onTap: () {
          print('Debug - Turf ID: ${turf['id']}');
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => TurfViewPage(
                turfData: turf,
                userId: user.uid,
                userData: userData,
                turfId: turf['id'],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTurfList() {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: turfStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final allTurfs = snapshot.data ?? [];

        if (allTurfs.isEmpty) {
          return Center(child: Text('No turfs found.'));
        }

        return ListView.builder(
          itemCount: allTurfs.length,
          itemBuilder: (context, index) {
            final turf = allTurfs[index];
            return FutureBuilder<String>(
              future: _getPlaceNameFromCoordinates(turf['location'] as GeoPoint),
              builder: (context, snapshot) {
                final locationName = snapshot.data ?? 'Loading...';
                return _buildTurfListItem(turf, locationName);
              },
            );
          },
        );
      },
    );
  }

  Future<void> _getCurrentLocation() async {
    try {
      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
      List<Placemark> placemarks = await placemarkFromCoordinates(
          position.latitude, position.longitude);

      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        setState(() {
          _currentLocationName =
              '${place.name}, ${place.subLocality}, ${place.locality}, ${place.administrativeArea}';
        });
      }
    } catch (e) {
      print('Error getting location: $e');
      setState(() {
        _currentLocationName = 'Unable to fetch location';
      });
    }
  }

  Widget _buildUserBookings() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('bookings')
          .where('userId', isEqualTo: user.uid)
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
              title: Text('Booking for ${booking['turfId']}'),
              subtitle: Text('Date: ${booking['date'].toDate().toString().split(' ')[0]}'),
              trailing: Text('Status: ${booking['status']}'),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('LineUp'),
        backgroundColor: Theme.of(context).brightness == Brightness.light
            ? Colors.green
            : Theme.of(context).appBarTheme.backgroundColor,
      ),
      body: _buildContent(),
      bottomNavigationBar: BottomNavigationBar(
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home, color: Color.fromARGB(255, 70, 176, 75)),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.search, color: Color.fromARGB(255, 70, 176, 75)),
            label: 'Search',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.notifications, color: Color.fromARGB(255, 70, 176, 75)),
            label: 'Notifications',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person, color: Color.fromARGB(255, 70, 176, 75)),
            label: 'Profile',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Theme.of(context).primaryColor,
        unselectedItemColor: Colors.grey,
        onTap: _onItemTapped,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          setState(() {
            _isChatOpen = !_isChatOpen;
          });
        },
        backgroundColor: Colors.green,
        child: Icon(_isChatOpen ? Icons.close : Icons.chat),
      ),
      bottomSheet: _isChatOpen ? _buildChatInterface() : null,
    );
  }

  @override
  void dispose() {
    _chatController.dispose();
    super.dispose();
  }

  Future<String> _processMessage(String userMessage) async {
    try {
      // Fetch all relevant user data
      final userProfile = await _getUserProfile();
      final bookings = await _getUserBookings();
      final reviews = await _getUserReviews();
      
      // Create comprehensive context
      String contextPrompt = """
You are an AI assistant for the LineUp turf booking app. Here's the current user's complete profile:

User Details:
- Name: ${userProfile['name']}
- Email: ${userProfile['email']}
- Phone: ${userProfile['phone_number']}
- Role: ${userProfile['role']}
- Location: ${_currentLocationName}

Recent Bookings:
${_formatBookings(bookings)}

Reviews Given:
${_formatReviews(reviews)}

Please provide personalized responses based on this user's data and history.
""";

      final response = await http.post(
        Uri.parse('$_baseUrl/chat/completions'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
        },
        body: jsonEncode({
          'model': 'gpt-3.5-turbo',
          'messages': [
            {'role': 'system', 'content': contextPrompt},
            {'role': 'user', 'content': userMessage}
          ],
          'temperature': 0.7,
          'max_tokens': 500,
        }),
      );

      print('API Response Status: ${response.statusCode}');
      print('API Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        String aiResponse = data['choices'][0]['message']['content'];
        return await _enrichResponseWithData(aiResponse);
      } else {
        throw Exception('API Error: ${response.statusCode}');
      }
    } catch (e) {
      print('Error: $e');
      return 'I apologize, but I encountered an error. Please try again.';
    }
  }

  Future<Map<String, dynamic>> _getUserProfile() async {
    try {
      DocumentSnapshot doc = await _firestore
          .collection('users')
          .doc(user.uid)
          .get();
      return doc.data() as Map<String, dynamic>;
    } catch (e) {
      print('Error fetching user profile: $e');
      return {};
    }
  }

  Future<List<Map<String, dynamic>>> _getUserBookings() async {
    try {
      QuerySnapshot bookings = await _firestore
          .collection('bookings')
          .where('userId', isEqualTo: user.uid)
          .orderBy('createdAt', descending: true)
          .limit(5)
          .get();
      
      return bookings.docs.map((doc) => doc.data() as Map<String, dynamic>).toList();
    } catch (e) {
      print('Error fetching bookings: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> _getUserReviews() async {
    try {
      QuerySnapshot reviews = await _firestore
          .collection('reviews')
          .where('userId', isEqualTo: user.uid)
          .orderBy('createdAt', descending: true)
          .get();
      
      return reviews.docs.map((doc) => doc.data() as Map<String, dynamic>).toList();
    } catch (e) {
      print('Error fetching reviews: $e');
      return [];
    }
  }

  String _formatBookings(List<Map<String, dynamic>> bookings) {
    if (bookings.isEmpty) return "No recent bookings";
    
    return bookings.map((booking) => """
• Turf: ${booking['turfName']}
  Date: ${DateFormat('MMM d, yyyy').format(booking['date'].toDate())}
  Time: ${booking['timeSlots'].join(', ')}
  Status: ${booking['status']}""").join('\n');
  }

  String _formatReviews(List<Map<String, dynamic>> reviews) {
    if (reviews.isEmpty) return "No reviews given";
    
    return reviews.map((review) => """
• Turf: ${review['turfName']}
  Rating: ${review['rating']} stars
  Comment: ${review['review']}""").join('\n');
  }

  Future<String> _getAvailableSlots() async {
    try {
      // Get current date
      DateTime now = DateTime.now();
      
      // Get all bookings for the selected turf
      QuerySnapshot bookingsSnapshot = await _firestore
          .collection('bookings')
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(now))
          .get();

      // Get all booked time slots
      Set<String> bookedSlots = {};
      for (var doc in bookingsSnapshot.docs) {
        Map<String, dynamic> booking = doc.data() as Map<String, dynamic>;
        List<String> timeSlots = List<String>.from(booking['timeSlots'] ?? []);
        bookedSlots.addAll(timeSlots);
      }

      // Get all available time slots (assuming you have predefined time slots)
      List<String> allTimeSlots = [
        '9:00 AM', '10:00 AM', '11:00 AM', '12:00 PM',
        '1:00 PM', '2:00 PM', '3:00 PM', '4:00 PM',
        '5:00 PM', '6:00 PM', '7:00 PM', '8:00 PM'
      ];

      // Filter out booked slots
      List<String> availableSlots = allTimeSlots
          .where((slot) => !bookedSlots.contains(slot))
          .toList();

      if (availableSlots.isEmpty) {
        return "No slots available for today.";
      }

      return "Available slots:\n${availableSlots.join('\n')}";
    } catch (e) {
      print('Error getting available slots: $e');
      return "Error fetching available slots.";
    }
  }

  Future<String> _enrichResponseWithData(String response) async {
    try {
      if (response.contains('[AVAILABLE_SLOTS]')) {
        final slots = await _getAvailableSlots();
        response = response.replaceAll('[AVAILABLE_SLOTS]', slots);
      }

      if (response.contains('[BOOKINGS]')) {
        final bookings = await _getUserBookings();
        String bookingsText = _formatBookings(bookings);
        response = response.replaceAll('[BOOKINGS]', bookingsText);
      }

      if (response.contains('[PROFILE]')) {
        final profile = await _getUserProfile();
        String profileText = """
Name: ${profile['name']}
Email: ${profile['email']}
Phone: ${profile['phone_number']}
Role: ${profile['role']}""";
        response = response.replaceAll('[PROFILE]', profileText);
      }

      return response;
    } catch (e) {
      print('Error enriching response: $e');
      return response;
    }
  }

  void _handleMessage(String message) async {
    if (message.trim().isEmpty) return;

    setState(() {
      chatMessages.add({
        'role': 'user',
        'content': message,
      });
      _isProcessingMessage = true;
    });

    try {
      final response = await _processMessage(message);
      
      setState(() {
        chatMessages.add({
          'role': 'assistant',
          'content': response,
        });
      });
    } catch (e) {
      print('Error in message handling: $e');
      setState(() {
        chatMessages.add({
          'role': 'assistant',
          'content': 'I apologize, but I encountered an error. Please try again.',
        });
      });
    } finally {
      setState(() {
        _isProcessingMessage = false;
      });
    }
  }

  Widget _buildChatInterface() {
    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            itemCount: chatMessages.length,
            itemBuilder: (context, index) {
              final message = chatMessages[index];
              final isUser = message['role'] == 'user';
              
              return Container(
                margin: EdgeInsets.symmetric(
                  vertical: 8,
                  horizontal: 16,
                ),
                alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                child: Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isUser ? Colors.green : Colors.grey[200],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    message['content'] ?? '',
                    style: TextStyle(
                      color: isUser ? Colors.white : Colors.black,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        if (_isProcessingMessage)
          Padding(
            padding: EdgeInsets.all(8.0),
            child: CircularProgressIndicator(),
          ),
        _buildMessageInput(),
      ],
    );
  }

  Widget _buildMessageInput() {
    final TextEditingController _controller = TextEditingController();
    
    return Padding(
      padding: EdgeInsets.all(8.0),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              decoration: InputDecoration(
                hintText: 'Ask me anything about turf booking...',
                border: OutlineInputBorder(),
              ),
            ),
          ),
          IconButton(
            icon: Icon(Icons.send),
            onPressed: () {
              if (_controller.text.isNotEmpty) {
                _handleMessage(_controller.text);
                _controller.clear();
              }
            },
          ),
        ],
      ),
    );
  }
}
