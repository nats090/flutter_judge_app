import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ScoreboardScreen extends StatelessWidget {
  final FirebaseFirestore db = FirebaseFirestore.instance;

  Future<void> resetScores() async {
    WriteBatch batch = db.batch();

    QuerySnapshot scoreboardSnapshot = await db.collection('scoreboard').get();
    for (var contestantDoc in scoreboardSnapshot.docs) {
      batch.update(contestantDoc.reference, {
        'total_score': 0,
        'judges_count': 0,
        'judges': []
      });
    }

    await batch.commit();
    print("All scores reset successfully!");
  }

  Stream<QuerySnapshot> getScoreboard() {
    return db.collection('scoreboard')
        .orderBy('total_score', descending: true)
        .snapshots();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black, // Dark background
      appBar: AppBar(title: Text('Scoreboard', style: TextStyle(color: Colors.white)), backgroundColor: Colors.orange),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: getScoreboard(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return Center(child: CircularProgressIndicator(color: Colors.orange));
                }

                var scores = snapshot.data!.docs;

                return ListView.builder(
                  itemCount: scores.length,
                  itemBuilder: (context, index) {
                    var data = scores[index].data() as Map<String, dynamic>;
                    return Card(
                      color: Colors.orange, // Orange card for visual appeal
                      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      elevation: 4,
                      child: ListTile(
                        title: Text("Contestant: ${scores[index].id}", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                        subtitle: Text("Score: ${data['total_score']} (Judged by ${data['judges_count']} judges)\nJudges: ${data['judges'].join(', ')}", style: TextStyle(color: Colors.white)),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: ElevatedButton(
              onPressed: () async {
                await resetScores();
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("All scores reset successfully!", style: TextStyle(color: Colors.white))));
              },
              child: Text('Reset Scores', style: TextStyle(fontSize: 18, color: Colors.white)),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15)),
            ),
          ),
          SizedBox(height: 20),
        ],
      ),
    );
  }
}
