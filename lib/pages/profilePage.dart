import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../widgets/bottomNavBar.dart';
import '../pages/loginPage.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';

class ProfilePage extends StatefulWidget {
  final User? user;

  ProfilePage({this.user});

  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  User? currentUser;
  File? _selectedImage;

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? pickedImage = await picker.pickImage(source: ImageSource.gallery);

    if (pickedImage != null) {
      setState(() {
        _selectedImage = File(pickedImage.path);
      });

      // You can add Firebase Storage upload logic here if needed
    }
  }

  // Text controllers for editable fields
  TextEditingController nameController = TextEditingController();
  TextEditingController phoneController = TextEditingController();
  TextEditingController nricController = TextEditingController();
  TextEditingController addressController = TextEditingController();
  TextEditingController cityController = TextEditingController();
  TextEditingController postcodeController = TextEditingController();

  @override
  void initState() {
    super.initState();
    currentUser = widget.user ?? FirebaseAuth.instance.currentUser;

    // Pre-fill the controllers with current values
    nameController.text = currentUser?.displayName ?? '';
    phoneController.text = currentUser?.phoneNumber ?? '';
    nricController.text = '';
    addressController.text = '';
    cityController.text = '';
    postcodeController.text = '';
  }

  Future<void> clearAuthCache() async {
    await FirebaseAuth.instance.signOut();
    GoogleSignIn googleSignIn = GoogleSignIn();
    if (await googleSignIn.isSignedIn()) {
      await googleSignIn.disconnect();
    }
    await googleSignIn.signOut();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          SizedBox(height: 50),
          Center(
            child: Column(
              children: [
                // Profile Picture
                GestureDetector(
                  onTap: () {
                    if (currentUser != null) {
                      _pickImage(); // Allow changing photo only if logged in
                    }
                  },
                  child: CircleAvatar(
                    radius: 50,
                    backgroundImage: _selectedImage != null
                        ? FileImage(_selectedImage!) // Use selected image
                        : (currentUser?.photoURL != null
                        ? NetworkImage(currentUser!.photoURL!) // Use current user's photo
                        : AssetImage('assets/profileNotLogin.png')) as ImageProvider, // Default for non-logged-in users
                  ),
                ),
                SizedBox(height: 20),
                // Name Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      currentUser?.displayName ?? "Set your name",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.yellow,
                      ),
                    ),
                    SizedBox(width: 10),
                    Image.asset(
                      'assets/pencil.png',
                      height: 20,
                      width: 20,
                    ),
                  ],
                ),
                SizedBox(height: 30),
                Container(
                  margin: EdgeInsets.symmetric(horizontal: 20),
                  decoration: BoxDecoration(
                    color: Color(0xFF404040),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    children: [
                      ListTile(
                        leading: Image.asset(
                          'assets/profileicon1.png',
                          height: 24,
                          width: 24,
                        ),
                        title: GestureDetector(
                          onTap: () {
                            _pickImage(); // Call image picker
                          },
                          child: Text(
                            'Change profile photo',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ),
                      // Username (Non-Editable)
                      buildNonEditableRow('assets/profileicon2.png', currentUser?.displayName ?? 'Set username'),
                      // Editable Rows
                      buildEditableRow('assets/profileicon3.png', 'Mobile Number', phoneController),
                      buildEditableRow('assets/profileicon4.png', 'NRIC', nricController),
                      buildEditableRow('assets/profileicon5.png', 'Home Address', addressController),
                      buildEditableRow('assets/profileicon6.png', 'City', cityController),
                      buildEditableRow('assets/profileicon7.png', 'Postcode', postcodeController),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Spacer(),
          Padding(
            padding: const EdgeInsets.only(bottom: 20.0),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: currentUser != null ? Colors.red : Color(0xFFFFCF40),
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: EdgeInsets.symmetric(horizontal: 80, vertical: 12),
              ),
              onPressed: () async {
                await clearAuthCache();
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => LoginPage()),
                );
              },
              child: Text(
                currentUser != null ? "Logout" : "Login",
                style: TextStyle(fontSize: 16),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavBar(
        selectedIndex: 4,
        onItemTapped: (int index) {
          if (index != 4) {
            Navigator.pushNamed(context, '/home');
          }
        },
      ),
    );
  }

  Widget buildNonEditableRow(String iconPath, String text) {
    return ListTile(
      leading: Image.asset(
        iconPath,
        height: 24,
        width: 24,
      ),
      title: Text(
        text,
        style: TextStyle(
          color: Colors.white,
        ),
      ),
    );
  }

  Widget buildEditableRow(String iconPath, String label, TextEditingController controller) {
    return ListTile(
      leading: Image.asset(
        iconPath,
        height: 24,
        width: 24,
      ),
      title: TextField(
        controller: controller,
        style: TextStyle(color: Colors.white),
        decoration: InputDecoration(
          border: InputBorder.none,
          hintText: label,
          hintStyle: TextStyle(color: Colors.grey),
        ),
      ),
    );
  }
}
