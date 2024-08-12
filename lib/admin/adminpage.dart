import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:lineup/admin/userdetailspage.dart';
import 'package:lineup/admin/turfdetailspage.dart';

class AdminPage extends StatefulWidget {
  @override
  _AdminPageState createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage> {
  List<Map<String, dynamic>> allUsers = [];
  List<Map<String, dynamic>> filteredUsers = [];
  List<Map<String, dynamic>> allTurfs = [];
  List<Map<String, dynamic>> filteredTurfs = [];
  bool isLoading = true;
  String searchQuery = '';
  String userTypeFilter = 'All';
  String statusFilter = 'All';
  String turfSearchQuery = ''; // For turf search
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    fetchAllUsers();
  }

  Future<void> fetchAllUsers() async {
    try {
      QuerySnapshot snapshot = await FirebaseFirestore.instance.collection('users').get();
      setState(() {
        allUsers = snapshot.docs
            .map((doc) => doc.data() as Map<String, dynamic>)
            .where((user) => user['role'] != 'Admin') // Exclude admins
            .toList();
        filteredUsers = allUsers;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      _showErrorDialog("Failed to fetch users: $e");
    }
  }

  Future<void> fetchAllTurfs() async {
    try {
      QuerySnapshot snapshot = await FirebaseFirestore.instance.collection('turfs').get();
      setState(() {
        allTurfs = snapshot.docs
            .map((doc) => doc.data() as Map<String, dynamic>)
            .toList();
        filteredTurfs = allTurfs;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      _showErrorDialog("Failed to fetch turfs: $e");
    }
  }

  void filterUsers() {
    setState(() {
      filteredUsers = allUsers.where((user) {
        final matchesQuery = user['name']?.toLowerCase().contains(searchQuery.toLowerCase()) ?? false;
        final matchesType = userTypeFilter == 'All' || user['role'] == userTypeFilter;
        final matchesStatus = statusFilter == 'All' || (user['disabled'] == (statusFilter == 'Disabled'));
        return matchesQuery && matchesType && matchesStatus;
      }).toList();
    });
  }

  void filterTurfs() {
    setState(() {
      filteredTurfs = allTurfs.where((turf) {
        final matchesQuery = turf['name']?.toLowerCase().contains(turfSearchQuery.toLowerCase()) ?? false;
        return matchesQuery;
      }).toList();
    });
  }

  Future<void> toggleUserStatus(Map<String, dynamic> user) async {
    try {
      await FirebaseFirestore.instance.collection('users').doc(user['uid']).update({
        'disabled': !(user['disabled'] ?? false),
      });
      fetchAllUsers(); // Refresh the user list after updating the status
    } catch (e) {
      _showErrorDialog("Failed to update user status: $e");
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
    if (_selectedIndex == 1) {
      fetchAllTurfs();
    }
  }

  Widget _buildSearchAndFilter() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            decoration: InputDecoration(
              labelText: 'Search by name',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(),
            ),
            onChanged: (value) {
              setState(() {
                searchQuery = value;
              });
              filterUsers();
            },
          ),
          SizedBox(height: 16.0),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  decoration: InputDecoration(border: OutlineInputBorder(), labelText: 'Filter by type'),
                  value: userTypeFilter,
                  items: ['All', 'Player', 'Turf Owner'].map((type) {
                    return DropdownMenuItem(
                      value: type,
                      child: Text(type),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      userTypeFilter = value!;
                    });
                    filterUsers();
                  },
                ),
              ),
              SizedBox(width: 16.0),
              Expanded(
                child: DropdownButtonFormField<String>(
                  decoration: InputDecoration(border: OutlineInputBorder(), labelText: 'Filter by status'),
                  value: statusFilter,
                  items: ['All', 'Enabled', 'Disabled'].map((status) {
                    return DropdownMenuItem(
                      value: status,
                      child: Text(status),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      statusFilter = value!;
                    });
                    filterUsers();
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTurfSearchAndFilter() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            decoration: InputDecoration(
              labelText: 'Search turfs by name',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(),
            ),
            onChanged: (value) {
              setState(() {
                turfSearchQuery = value;
              });
              filterTurfs();
            },
          ),
          // Add additional filters if needed here
        ],
      ),
    );
  }

  Widget _buildUserListItem(Map<String, dynamic> user) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      elevation: 5,
      child: ListTile(
        contentPadding: const EdgeInsets.all(16.0),
        leading: CircleAvatar(
          radius: 30,
          backgroundImage: NetworkImage(user['profile_image_url'] ?? 'https://via.placeholder.com/150'),
        ),
        title: Text(
          user['name'] ?? 'Unknown',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(user['role'] == 'Player' ? 'Player' : 'Turf Owner'),
        trailing: SizedBox(
          width: 100,
        ),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => UserDetailsPage(userData: user),
            ),
          );
        },
      ),
    );
  }

  Widget _buildUserList() {
    if (filteredUsers.isEmpty) {
      return Center(child: Text('No users found.'));
    }
    return ListView.builder(
      itemCount: filteredUsers.length,
      itemBuilder: (context, index) {
        final user = filteredUsers[index];
        return _buildUserListItem(user);
      },
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
              builder: (context) => TurfDetailsPage(turfData: turf),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTurfList() {
    if (filteredTurfs.isEmpty) {
      return Center(child: Text('No turfs found.'));
    }
    return ListView.builder(
      itemCount: filteredTurfs.length,
      itemBuilder: (context, index) {
        final turf = filteredTurfs[index];
        return _buildTurfListItem(turf);
      },
    );
  }

  Widget _buildUsersScreen() {
    return isLoading
        ? Center(child: CircularProgressIndicator())
        : Column(
            children: [
              _buildSearchAndFilter(),
              Expanded(child: _buildUserList()),
            ],
          );
  }

  Widget _buildTurfScreen() {
    return isLoading
        ? Center(child: CircularProgressIndicator())
        : Column(
            children: [
              _buildTurfSearchAndFilter(), // Add search and filter for turfs
              Expanded(child: _buildTurfList()),
            ],
          );
  }

  Widget _buildRequestsScreen() {
    return Center(child: Text('Requests screen placeholder'));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Admin Page'),
        centerTitle: true,
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          _buildUsersScreen(),
          _buildTurfScreen(),
          _buildRequestsScreen(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Users',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.sports_soccer),
            label: 'Turfs',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.pending),
            label: 'Requests',
          ),
        ],
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
    );
  }
}
