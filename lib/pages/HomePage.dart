import 'package:flutter/material.dart';
import '../widgets/HomeAppBar.dart';
import '../widgets/AsnafDashboard.dart';
import '../widgets/AdminDashboard.dart';
import '../widgets/StaffDashboard.dart';
import '../widgets/UserPoints.dart';
import 'package:projects/widgets/bottomNavBar.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;
  String? userRole;

  @override
  void initState() {
    super.initState();
    _getUserRole();
  }

  Future<void> _getUserRole() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (doc.exists) {
        setState(() {
          userRole = doc.data()?['role'] ?? 'asnaf';
        });
      }
    }
  }

  // Handle tab selection
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  Widget _getDashboard() {
    switch (userRole) {
      case 'admin':
        return AdminDashboard();
      case 'staff':
        return StaffDashboard();
      case 'asnaf':
      default:
        return AsnafDashboard();
    }
  }

  Widget _buildUpcomingActivities() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 15, vertical: 20),
      padding: EdgeInsets.symmetric(horizontal: 15),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          stops: [0.16, 0.38, 0.58, 0.88],
          colors: [
            Color(0xFFF9F295),
            Color(0xFFE0AA3E),
            Color(0xFFF9F295),
            Color(0xFFB88A44),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title: Upcoming Activities
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Text(
              "Upcoming Activities",
              style: TextStyle(
                fontSize: 25,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
          ),

          // Fetch Events from Firestore and display horizontally
          Container(
            height: 250, // Increased height of the box for more space
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection("event").snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(child: Text("No Upcoming Activities", style: TextStyle(color: Colors.black)));
                }

                return ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    var event = snapshot.data!.docs[index];
                    return Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // Event Banner Image
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              event["bannerUrl"] ?? '', // Fetch banner image URL
                              height: 120,
                              width: 120,
                              fit: BoxFit.cover,
                            ),
                          ),
                          SizedBox(height: 8),

                          // Event Name (Centered)
                          Center(
                            child: Text(
                              event["eventName"] ?? "Unknown",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: Colors.black,
                              ),
                              textAlign: TextAlign.center, // Center align the event name
                            ),
                          ),
                          SizedBox(height: 8),

                          // Event Points
                          Text(
                            "Get ${event["points"] ?? "0"} points",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: Colors.black,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  @override
  @override
  Widget build(BuildContext context) {
    final _widgetOptions = <Widget>[
      ListView(
        children: [
          Container(
            padding: EdgeInsets.only(top: 15),
            child: Column(
              children: [
                Container(
                  margin: EdgeInsets.symmetric(horizontal: 15, vertical: 20),
                  padding: EdgeInsets.symmetric(horizontal: 15),
                  height: 50,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Container(
                          height: 50,
                          child: TextFormField(
                            decoration: InputDecoration(
                              border: InputBorder.none,
                              hintText: userRole == 'admin'
                                  ? "Admin here..."
                                  : userRole == 'staff'
                                  ? "Staff here..."
                                  : "Asnaf here...",
                            ),
                          ),
                        ),
                      ),
                      ShaderMask(
                        shaderCallback: (Rect bounds) {
                          return LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            stops: [0.16, 0.38, 0.58, 0.88],
                            colors: [
                              Color(0xFFF9F295),
                              Color(0xFFE0AA3E),
                              Color(0xFFF9F295),
                              Color(0xFFB88A44),
                            ],
                          ).createShader(bounds);
                        },
                        child: Icon(
                          Icons.search_rounded,
                          size: 35,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                userRole == null
                    ? CircularProgressIndicator()
                    : _getDashboard(),
                UserPoints(),
                // ✅ Add the Upcoming Activities section below UserPoints
                _buildUpcomingActivities(),
              ],
            ),
          ),
        ],
      ),
      Center(child: Text('Search Page')),
      Center(child: Text('Shopping Page')),
      Center(child: Text('Inbox Page')),
      Center(child: Text('Profile Page')),
    ];

    return Scaffold(
      body: _widgetOptions.elementAt(_selectedIndex),
      bottomNavigationBar: BottomNavBar(
        selectedIndex: _selectedIndex,
        onItemTapped: _onItemTapped,
      ),
    );
  }

}
