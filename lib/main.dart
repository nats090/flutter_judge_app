import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'judge_screen.dart' as judge;
import 'scoreboard_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Judge App',
      theme: ThemeData(
        brightness: Brightness.dark, // Set dark mode
        primaryColor: Colors.orange, // Set primary color
        colorScheme: ColorScheme.dark(
          primary: Colors.orange, // Main accent color
          secondary: Colors.white, // Text contrast
          background: Colors.black, // Dark theme background
        ),
      ),
      home: HomePage(),
    );
  }
}

class HomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black, // Dark theme background
      appBar: AppBar(
        title: Text('Judge App', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.orange, // Header in orange
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton.icon(
              icon: Icon(Icons.assignment_turned_in, color: Colors.white),
              label: Text('Judge', style: TextStyle(fontSize: 18, color: Colors.white)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
              ),
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => judge.JudgeScreen()));
              },
            ),
            SizedBox(height: 20),
            ElevatedButton.icon(
              icon: Icon(Icons.leaderboard, color: Colors.white),
              label: Text('Scoreboard', style: TextStyle(fontSize: 18, color: Colors.white)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
              ),
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => ScoreboardScreen()));
              },
            ),
          ],
        ),
      ),
    );
  }
}
