import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class JudgeScreen extends StatefulWidget {
  @override
  _JudgeScreenState createState() => _JudgeScreenState();
}

class _JudgeScreenState extends State<JudgeScreen> {
  final TextEditingController contestantController = TextEditingController();
  final TextEditingController scoreController = TextEditingController();
  final TextEditingController judgeNameController = TextEditingController();
  final String judgeId = "judge_1";

  Future<void> addScore() async {
    String contestantId = contestantController.text.trim();
    String judgeName = judgeNameController.text.trim();
    int score = int.tryParse(scoreController.text.trim()) ?? 0;

    if (contestantId.isEmpty || judgeName.isEmpty || score < 0 || score > 100) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Invalid input", style: TextStyle(color: Colors.white))));
      return;
    }

    final db = FirebaseFirestore.instance;

    await db.collection('judges').doc(judgeId).collection('scores').add({
      'contestant_id': contestantId,
      'judge_name': judgeName,
      'score': score,
      'timestamp': FieldValue.serverTimestamp(),
    });

    final contestantRef = db.collection('scoreboard').doc(contestantId);
    final docSnap = await contestantRef.get();

    if (docSnap.exists) {
      await contestantRef.update({
        'total_score': FieldValue.increment(score),
        'judges_count': FieldValue.increment(1),
        'judges': FieldValue.arrayUnion([judgeName])
      });
    } else {
      await contestantRef.set({
        'total_score': score,
        'judges_count': 1,
        'judges': [judgeName]
      });
    }

    contestantController.clear();
    scoreController.clear();
    judgeNameController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(title: Text('Judge Scoring', style: TextStyle(color: Colors.white)), backgroundColor: Colors.orange),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: judgeNameController,
              decoration: InputDecoration(labelText: 'Judge Name', labelStyle: TextStyle(color: Colors.white)),
              style: TextStyle(color: Colors.white),
            ),
            TextField(
              controller: contestantController,
              decoration: InputDecoration(labelText: 'Contestant ID', labelStyle: TextStyle(color: Colors.white)),
              style: TextStyle(color: Colors.white),
            ),
            TextField(
              controller: scoreController,
              decoration: InputDecoration(labelText: 'Score (0-100)', labelStyle: TextStyle(color: Colors.white)),
              keyboardType: TextInputType.number,
              style: TextStyle(color: Colors.white),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: addScore,
              child: Text('Submit Score', style: TextStyle(color: Colors.white)),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            ),
          ],
        ),
      ),
    );
  }
}
