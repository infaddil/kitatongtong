import 'package:flutter/material.dart';
import 'package:projects/widgets/bottomNavBar.dart';

class ApplyAid extends StatefulWidget {
  @override
  _ApplyAidState createState() => _ApplyAidState();
}

class _ApplyAidState extends State<ApplyAid> {
  int currentStep = 1; // Tracks the current step (e.g., 1/5)
  final int totalSteps = 5; // Total number of steps
  int _selectedIndex = 0; // For BottomNavBar selected index

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    double progressValue = currentStep / totalSteps; // Calculate progress percentage

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(80.0),
        child: AppBar(
          automaticallyImplyLeading: false,
          backgroundColor: Color(0xFF303030), // Dark background for app bar
          flexibleSpace: Padding(
            padding: const EdgeInsets.only(top: 20.0, left: 16.0, right: 16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    GestureDetector(
                      onTap: () {
                        Navigator.pop(context);
                      },
                      child: Icon(
                        Icons.arrow_back,
                        color: Colors.white,
                      ),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: Stack(
                          children: [
                            Container(
                              height: 23,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            AnimatedContainer(
                              duration: Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                              width: MediaQuery.of(context).size.width * 0.74 * progressValue,
                              height: 23, // Same height as background
                              decoration: BoxDecoration(
                                color: Colors.green,
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Text(
                      "$currentStep/$totalSteps",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0), // Add horizontal padding to the entire form
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 20), // Padding between progress tracker and title
            Center(
              child: Column(
                children: [
                  Text(
                    currentStep == 1
                        ? "Share your personal details"
                        : "Check your eligibility",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFFDB515),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 8),
                  Text(
                    currentStep == 1
                        ? "Fill in your personal details to begin your application"
                        : "Answer a few simple questions to see if you meet our eligibility criteria",
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.yellow[200],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            SizedBox(height: 16),
            // Display form fields based on the current step
            Expanded(
              child: ListView(
                children: currentStep == 1
                    ? buildPersonalDetailsForm()
                    : buildEligibilityForm(),
              ),
            ),
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end, // Push the content upwards from the bottom
                children: [
                  Divider(
                    color: Colors.white,
                    thickness: 1,
                  ),
                  SizedBox(height: 2), // Space between divider and button
                  Padding(
                    padding: const EdgeInsets.only(bottom: 20.0), // Add space from the bottom
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFFFFCF40), // Button background color
                        foregroundColor: Colors.black, // Text color
                      ),
                      onPressed: () {
                        if (currentStep < totalSteps) {
                          setState(() {
                            currentStep++;
                          });
                        }
                      },
                      child: Text(currentStep == totalSteps ? "Submit" : "Next"),
                    ),
                  ),
                ],
              ),
            ),

          ],
        ),
      ),
      bottomNavigationBar: BottomNavBar(
        selectedIndex: _selectedIndex, // Pass the selected index
        onItemTapped: _onItemTapped, // Pass the tap handler
      ),
    );
  }

  List<Widget> buildPersonalDetailsForm() {
    return [
      buildTextField("NRIC"),
      SizedBox(height: 10),
      buildTextField("Full Name"),
      SizedBox(height: 10),
      buildTextField("Email"),
      SizedBox(height: 10),
      buildMobileNumberField(),
      SizedBox(height: 10),
      buildTextField("Address Line 1"),
      SizedBox(height: 10),
      buildTextField("Address Line 2"),
      SizedBox(height: 10),
      buildTextField("City"),
      SizedBox(height: 10),
      buildTextField("Postcode"),
    ];
  }

  List<Widget> buildEligibilityForm() {
    return [
      buildTextField("Residency Status"),
      SizedBox(height: 10),
      buildTextField("Employment Status"),
      SizedBox(height: 10),
      buildTextField("Monthly Income"),
      SizedBox(height: 10),
      buildLongTextField("Justification of Application"),
    ];
  }
  Widget buildLongTextField(String label) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        SizedBox(height: 8),
        Container(
          height: 120, // Make the container taller
          decoration: BoxDecoration(
            color: Color(0xFFFFCF40),
            borderRadius: BorderRadius.circular(10),
          ),
          child: TextField(
            maxLines: null, // Allows multi-line input
            expands: true,  // Makes the field expand to fill the container
            textAlignVertical: TextAlignVertical.top, // Align text to the top
            decoration: InputDecoration(
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
          ),
        ),
      ],
    );
  }

  Widget buildTextField(String label) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        SizedBox(height: 8),
        Container(
          height: 30,
          decoration: BoxDecoration(
            color: Color(0xFFFFCF40),
            borderRadius: BorderRadius.circular(10),
          ),
          child: TextField(
            decoration: InputDecoration(
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
          ),
        ),
      ],
    );
  }

  Widget buildMobileNumberField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Mobile Number",
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        SizedBox(height: 8),
        Container(
          height: 30,
          decoration: BoxDecoration(
            color: Color(0xFFFFCF40),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: Text(
                  "+60",
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ),
              VerticalDivider(color: Colors.black, thickness: 1),
              Expanded(
                child: TextField(
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}