import 'package:flutter/material.dart';
import 'package:projects/widgets/bottomNavBar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class Rewards extends StatefulWidget {
  @override
  _RewardsState createState() => _RewardsState();
}

class _RewardsState extends State<Rewards> {
  bool isRewards = true;
  int _selectedIndex = 0;
  int userPoints = 0;
  int redeemablePoints = 0;
  int valuePoints = 0;
  String validityMessage = "Valid for 1 month";
  List<Map<String, dynamic>> eligibleVouchers = [];

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  @override
  void initState() {
    super.initState();
    fetchUserData(); // <-- This must be here
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  Future<void> fetchUserData() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    final userDoc = await _firestore.collection('users').doc(uid).get();
    final voucherDocs = await _firestore.collection('vouchers').get();
    Timestamp? redeemedAt;
    int daysLeft = 0;

    int points = userDoc.data()?['points'] ?? 0;

    // Filter vouchers of type "Points" and sort descending by 'points'
    final validVouchers = voucherDocs.docs
        .map((doc) => doc.data())
        .where((data) => (data['typeVoucher'] ?? '').toString().trim().toLowerCase() == 'points')
        .toList()
      ..sort((a, b) => b['points'].compareTo(a['points'])); // Sort descending
    final pointVouchers = voucherDocs.docs
        .map((doc) => doc.data())
        .where((data) =>
    (data['typeVoucher'] ?? '').toString().trim().toLowerCase() == 'points' &&
        (data['points'] ?? 0) <= points &&
        (data['bannerVoucher'] ?? '').toString().isNotEmpty)
        .toList();

    eligibleVouchers = pointVouchers
        .where((v) =>
    v['points'] != null &&
        v['valuePoints'] != null &&
        v['bannerVoucher'] != null)
        .toList();

    int bestMatchPoints = 0;
    int bestMatchValue = 0;

    for (var voucher in validVouchers) {
      if (voucher['points'] <= points) {
        bestMatchPoints = voucher['points'];
        bestMatchValue = voucher['valuePoints'];
        break; // Found best match, no need to continue
      }
    }
    if (userDoc.data()?['voucherReceived'] != null) {
      final received = userDoc.data()!['voucherReceived'];
      if (received is Map && received['redeemedAt'] != null) {
        final redeemedAt = received['redeemedAt'] as Timestamp?;
        if (redeemedAt != null) {
          final redeemedDate = redeemedAt.toDate();
          final now = DateTime.now();
          final difference = 30 - now.difference(redeemedDate).inDays;

          if (difference >= 0) {
            daysLeft = difference;
            validityMessage = "Valid for $daysLeft day${daysLeft == 1 ? '' : 's'}";
          } else {
            validityMessage = "Expired";
          }
        }
      }
    }

    setState(() {
      userPoints = points;
      redeemablePoints = bestMatchPoints;
      valuePoints = bestMatchValue;
      //eligiblePointVouchers = eligibleVouchers;
    });
  }

  Future<void> redeemPoints() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null || redeemablePoints == 0) return;

    final now = Timestamp.now();
    final userRef = _firestore.collection('users').doc(uid);
    final historyRef = _firestore.collection('redeemedPoints').doc();

    final userSnapshot = await userRef.get();
    final userData = userSnapshot.data();
    final name = userData?['name'] ?? '';
    final email = userData?['email'] ?? '';
    final currentPoints = userData?['points'] ?? 0;
    final currentTotalValue = userData?['totalValuePoints'] ?? 0;
    final currentVoucherHistory = userData?['voucherReceived'] ?? [];

    // Prevent negative balance
    if (redeemablePoints > currentPoints) return;

    await _firestore.runTransaction((transaction) async {
      transaction.update(userRef, {
        'points': currentPoints - redeemablePoints,
        'totalValuePoints': currentTotalValue + valuePoints,
        'voucherReceived': FieldValue.arrayUnion([
          {
            'redeemedAt': now,
            'valuePoints': valuePoints,
          }
        ])
      });

      transaction.set(historyRef, {
        'userId': uid,
        'name': name,
        'email': email,
        'pointsUsed': redeemablePoints,
        'valuePoints': valuePoints,
        'redeemedAt': now,
      });
    });

    fetchUserData(); // Refresh
  }
  Future<void> claimVoucher(int selectedPoints, int selectedValuePoints) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null || selectedPoints == 0) return;

    final now = Timestamp.now();
    final userRef = _firestore.collection('users').doc(uid);
    final historyRef = _firestore.collection('redeemedPoints').doc();

    final userSnapshot = await userRef.get();
    final userData = userSnapshot.data();
    final name = userData?['name'] ?? '';
    final email = userData?['email'] ?? '';
    final currentPoints = userData?['points'] ?? 0;
    final currentTotalValue = userData?['totalValuePoints'] ?? 0;

    if (selectedPoints > currentPoints) return;

    await _firestore.runTransaction((transaction) async {
      transaction.update(userRef, {
        'points': currentPoints - selectedPoints,
        'totalValuePoints': currentTotalValue + selectedValuePoints,
        'voucherReceived': FieldValue.arrayUnion([
          {
            'redeemedAt': now,
            'valuePoints': selectedValuePoints,
          }
        ])
      });

      transaction.set(historyRef, {
        'userId': uid,
        'name': name,
        'email': email,
        'pointsUsed': selectedPoints,
        'valuePoints': selectedValuePoints,
        'redeemedAt': now,
      });
    });

    fetchUserData();
  }
  Widget buildRewardsListSection() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Center(
        child: Text(
          "Rewards list goes here...",
          style: TextStyle(color: Colors.white),
        ),
      ),
    );
  }

  Widget buildRedeemSection() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Tongtong Points\n$userPoints Pts",
                style: TextStyle(
                  color: Color(0xFFFFCF40),
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.start,
              ),
              Image.asset(
                'assets/Smiley.png',
                width: 40,
                height: 40,
              ),
            ],
          ),
          SizedBox(height: 20),
          SizedBox(height: 20),
          Center(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  "Points to Redeem",
                  style: TextStyle(
                    color: Color(0xFFFDB515),
                    fontSize: 18,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  "$redeemablePoints",
                  style: TextStyle(
                    color: Color(0xFFFFCF40),
                    fontSize: 18,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  "Details",
                  style: TextStyle(
                    color: Color(0xFFFDB515),
                    fontSize: 18,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  "$valuePoints Cash Voucher\n$validityMessage",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
                SizedBox(height: 20),
                ElevatedButton(
                  onPressed: redeemPoints,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFFEFBF04),
                    padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                  child: Text(
                    "Redeem Points",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                SizedBox(height: 20),

// 🔶 Golden box section
                if (eligibleVouchers.isNotEmpty)
                  Container(
                    margin: EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                    padding: EdgeInsets.symmetric(horizontal: 15, vertical: 15),
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
                        Text(
                          "Available Vouchers",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                        SizedBox(height: 10),
                        SizedBox(
                          height: 260, // ← fixed overflow without breaking design
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: eligibleVouchers.length,
                            itemBuilder: (context, index) {
                              final voucher = eligibleVouchers[index];
                              final bannerUrl = voucher['bannerVoucher'];
                              final valuePoints = voucher['valuePoints'];
                              final pointsCost = voucher['points'];

                              return Container(
                                width: 200,
                                margin: EdgeInsets.only(right: 10),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(10),
                                      child: Image.network(
                                        bannerUrl,
                                        fit: BoxFit.cover,
                                        width: 200,
                                        height: 110,
                                      ),
                                    ),
                                    Container(
                                      width: 200,
                                      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.only(
                                          bottomLeft: Radius.circular(10),
                                          bottomRight: Radius.circular(10),
                                        ),
                                      ),
                                      child: Column(
                                        children: [
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text("Redeem with", style: TextStyle(color: Color(0xFFA67C00), fontWeight: FontWeight.bold, fontSize: 13)),
                                              Text("Rewards", style: TextStyle(color: Color(0xFFA67C00), fontWeight: FontWeight.bold, fontSize: 13)),
                                            ],
                                          ),
                                          SizedBox(height: 4),
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text("$pointsCost pts", style: TextStyle(color: Colors.black, fontWeight: FontWeight.w600, fontSize: 13)),
                                              Text("RM$valuePoints", style: TextStyle(color: Colors.black, fontWeight: FontWeight.w600, fontSize: 13)),
                                            ],
                                          ),
                                          SizedBox(height: 8),
                                          SizedBox(
                                            width: double.infinity,
                                            child: ElevatedButton(
                                              onPressed: () => claimVoucher(pointsCost, valuePoints),
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: Colors.black,
                                                padding: EdgeInsets.symmetric(vertical: 10),
                                                shape: RoundedRectangleBorder(
                                                  borderRadius: BorderRadius.circular(8),
                                                ),
                                              ),
                                              child: Text("Claim", style: TextStyle(fontSize: 14, color: Colors.white)),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        )

                      ],
                    ),
                  ),
              ],
            ),
          ),

        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF303030),
      body: SingleChildScrollView(
        physics: BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Tabs: Redeem Rewards / Rewards
            Padding(
              padding: const EdgeInsets.only(top: 70.0, left: 16, right: 16),
              child: Container(
                height: 50,
                decoration: BoxDecoration(
                  color: Color(0xFFFDB515),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => isRewards = true),
                        child: Container(
                          decoration: BoxDecoration(
                            color: isRewards ? Colors.white : Color(0xFFFDB515),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            "Redeem Rewards",
                            style: TextStyle(
                              color: isRewards ? Color(0xFFFDB515) : Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => isRewards = false),
                        child: Container(
                          decoration: BoxDecoration(
                            color: !isRewards ? Colors.white : Color(0xFFFDB515),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            "Rewards",
                            style: TextStyle(
                              color: !isRewards ? Color(0xFFFDB515) : Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            SizedBox(height: 30),

            // Show Redeem Section or Rewards Section
            isRewards
                ? buildRedeemSection()
                : buildRewardsListSection(),

            SizedBox(height: 80),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavBar(
        selectedIndex: _selectedIndex,
        onItemTapped: _onItemTapped,
      ),
    );
  }

}