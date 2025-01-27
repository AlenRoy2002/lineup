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

  @override
  void initState() {
    super.initState();
    _fetchUserData();
    _initializeTurfStream();
    _getCurrentLocation();
    _initializeBookingsStream();
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
    );
  }

  @override
  void dispose() {
    super.dispose();
  }
}
