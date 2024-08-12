// ignore_for_file: prefer_const_constructors

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:lineup/admin/adminpage.dart';
import 'package:lineup/pages/auth_page.dart';
import 'package:lineup/pages/profileeditscreen.dart';

import 'package:lineup/pages/turfdetailspage_user.dart';
import 'package:lineup/turf_management/turfmanagementpage.dart';

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

  @override
  void initState() {
    super.initState();
    _fetchUserData();
    _initializeTurfStream();
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

  void _initializeTurfStream() {
    turfStream = FirebaseFirestore.instance
        .collection('turfs')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => doc.data() as Map<String, dynamic>)
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

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  Widget _buildContent() {
    switch (_selectedIndex) {
      case 0:
        return _buildTurfList(); // Display turfs in the home section
      case 1:
        return Center(child: Text('Search Content', style: TextStyle(fontSize: 24)));
      case 2:
        return Center(child: Text('Notifications Content', style: TextStyle(fontSize: 24)));
      case 3:
        return _buildProfileContent();
      default:
        return Center(child: Text('Home Content', style: TextStyle(fontSize: 24)));
    }
  }

  Widget _buildProfileContent() {
    return userData.isEmpty
        ? Center(child: CircularProgressIndicator())
        : Padding(
            padding: const EdgeInsets.all(16.0),
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SizedBox(height: 20),
                  CircleAvatar(
                    radius: 60,
                    backgroundColor: Colors.grey.shade300,
                    backgroundImage: userData['profile_image_url'] != null
                        ? NetworkImage(userData['profile_image_url'])
                        : null,
                    child: userData['profile_image_url'] == null
                        ? Icon(Icons.person, size: 60, color: Colors.white)
                        : null,
                  ),
                  SizedBox(height: 20),
                  Text(
                    userData['name'] ?? 'User',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 10),
                  Text(
                    "Email: ${userData['email'] ?? user.email!}",
                    style: TextStyle(fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 10),
                  Text(
                    "Role: ${userData['role'] ?? 'N/A'}",
                    style: TextStyle(fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 10),
                  Text(
                    "Country: ${userData['country'] ?? 'N/A'}",
                    style: TextStyle(fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 10),
                  Text(
                    "State: ${userData['state'] ?? 'N/A'}",
                    style: TextStyle(fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 10),
                  Text(
                    "City: ${userData['city'] ?? 'N/A'}",
                    style: TextStyle(fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 10),
                  Text(
                    "Local Place: ${userData['local_place'] ?? 'N/A'}",
                    style: TextStyle(fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 10),
                  Text(
                    "Phone Number: ${userData['phone_number'] ?? 'N/A'}",
                    style: TextStyle(fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 20),
                  if (userData['role'] == 'Admin')
                    ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => AdminPage()),
                        );
                      },
                      child: Text('Admin Panel'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        padding: EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                      ),
                    ),
                  if (userData['role'] == 'Turf Owner')
                    ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => TurfHomePage(userId: user.uid)),
                        );
                      },
                      child: Text('Manage Turf'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        padding: EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                      ),
                    ),
                  SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ProfileEditScreen(
                            userData: userData,
                            onProfileUpdated: _fetchUserData,
                          ),
                        ),
                      );
                    },
                    child: Text('Edit Profile'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      padding: EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                    ),
                  ),
                  SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: signUserOut,
                    child: Text('Sign Out'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      padding: EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                    ),
                  ),
                ],
              ),
            ),
          );
  }

  Widget _buildTurfListItem(Map<String, dynamic> turf) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      elevation: 5,
      child: ListTile(
        contentPadding: const EdgeInsets.all(16.0),
        leading: CircleAvatar(
          radius: 30,
          backgroundImage: NetworkImage(turf['images'][0]), // Displaying the first image from the list
        ),
        title: Text(
          turf['name'] ?? 'Unknown',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(turf['city'] ?? 'Unknown Location'),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => TurfViewPage(turfData: turf),
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
            return _buildTurfListItem(turf);
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
}
