import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'admin_screen.dart';
import 'judge_screen.dart';
import 'scoreboard_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Judge App',
      theme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: Colors.orange,
        colorScheme: ColorScheme.dark(
          primary: Colors.orange,
          secondary: Colors.white,
          surface: Colors.black,
        ),
      ),
      home: HomePage(),
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text('Judge App', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.orange,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton.icon(
              icon: Icon(Icons.admin_panel_settings, color: Colors.white),
              label: Text('Admin', style: TextStyle(fontSize: 18, color: Colors.white)),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => AdminScreen()));
              },
            ),
            SizedBox(height: 20),
            ElevatedButton.icon(
              icon: Icon(Icons.assignment_turned_in, color: Colors.white),
              label: Text('Judge', style: TextStyle(fontSize: 18, color: Colors.white)),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => JudgeScreen()));
              },
            ),
            SizedBox(height: 20),
            ElevatedButton.icon(
              icon: Icon(Icons.leaderboard, color: Colors.white),
              label: Text('Scoreboard', style: TextStyle(fontSize: 18, color: Colors.white)),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
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
