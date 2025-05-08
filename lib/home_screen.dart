import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'admin_screen.dart';
import 'judge_screen.dart';
import 'scoreboard_screen.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}
 
class _HomeScreenState extends State<HomeScreen> {
  String userRole = 'watcher';
  String approved = "true";
  bool loading = true;
 
  @override
  void initState() {
    super.initState();
    fetchUserRole();
    refreshAuthToken();
  }
 
  void fetchUserRole() async {
    try {
      User? currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        setState(() => loading = false);
        return;
      }
      String uid = currentUser.uid;
      DocumentSnapshot doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
      if (doc.exists) {
        Map<String, dynamic>? data = doc.data() as Map<String, dynamic>?;
        setState(() {
          userRole = (data?['role'] ?? 'watcher').toString().toLowerCase();
          approved = data?['approved']?.toString().toLowerCase() ?? "true";
          loading = false;
        });
      } else {
        setState(() => loading = false);
      }
    } catch (e) {
      print("Error fetching user role: $e");
      setState(() => loading = false);
    }
  }
 
  void refreshAuthToken() async {
    try {
      await FirebaseAuth.instance.currentUser?.getIdToken(true);
      print("Auth token refreshed successfully.");
    } catch (e) {
      print("Error refreshing auth token: $e");
      if (e.toString().contains("expired")) {
        FirebaseAuth.instance.signOut();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Session expired. Please log in again.")),
        );
      }
    }
  }
 
  @override
  Widget build(BuildContext context) {
    if (loading)
      return Scaffold(body: Center(child: CircularProgressIndicator()));
    if (approved != "true") {
      Future.microtask(() {
        FirebaseAuth.instance.signOut();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Your account is awaiting admin approval.")),
        );
      });
      return Scaffold(
        body: Center(child: Text("Your account is awaiting approval.\nPlease log in later.", textAlign: TextAlign.center)),
      );
    }
 
    return Scaffold(
      appBar: AppBar(
        title: Text("Home (${userRole.toUpperCase()})"),
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: () => FirebaseAuth.instance.signOut(),
          )
        ],
      ),
      body: Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Card(
            elevation: 4,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (userRole == 'admin') ...[
                    ElevatedButton.icon(
                      icon: Icon(Icons.admin_panel_settings),
                      label: Text("Admin Dashboard"),
                      onPressed: () {
                        Navigator.push(context, MaterialPageRoute(builder: (context) => AdminScreen()));
                      },
                    ),
                    SizedBox(height: 20),
                    ElevatedButton.icon(
                      icon: Icon(Icons.leaderboard),
                      label: Text("Scoreboard"),
                      onPressed: () {
                        Navigator.push(context, MaterialPageRoute(builder: (context) => ScoreboardScreen()));
                      },
                    ),
                  ] else if (userRole == 'judge') ...[
                    ElevatedButton.icon(
                      icon: Icon(Icons.assignment_turned_in),
                      label: Text("Judge Page"),
                      onPressed: () {
                        Navigator.push(context, MaterialPageRoute(builder: (context) => JudgeScreen()));
                      },
                    ),
                    SizedBox(height: 20),
                    ElevatedButton.icon(
                      icon: Icon(Icons.leaderboard),
                      label: Text("Scoreboard"),
                      onPressed: () {
                        Navigator.push(context, MaterialPageRoute(builder: (context) => ScoreboardScreen()));
                      },
                    ),
                  ] else ...[
                    ElevatedButton.icon(
                      icon: Icon(Icons.leaderboard),
                      label: Text("Scoreboard"),
                      onPressed: () {
                        Navigator.push(context, MaterialPageRoute(builder: (context) => ScoreboardScreen()));
                      },
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
