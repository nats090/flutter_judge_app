import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class VoteDetailScreen extends StatelessWidget {
  final String eventId;
  final String contestant;

  const VoteDetailScreen({required this.eventId, required this.contestant});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Votes for $contestant")),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('events')
            .doc(eventId)
            .collection('scoreboard')
            .doc(contestant)
            .collection('votes')
            .orderBy('timestamp', descending: false)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Center(child: CircularProgressIndicator());
          }
          if (snapshot.data!.docs.isEmpty) {
            return Center(child: Text("No votes found"));
          }
          return ListView(
            children: snapshot.data!.docs.map((voteDoc) {
              var voteData = voteDoc.data() as Map<String, dynamic>;
              String judgeName = voteData['judge'] ?? "Unknown Judge";
              Map<String, dynamic> criteriaVotes = voteData['criteria_scores'] != null
                  ? Map<String, dynamic>.from(voteData['criteria_scores'])
                  : {};
              double total = (voteData['total'] is num)
                  ? (voteData['total'] as num).toDouble()
                  : 0.0;
              return Card(
                margin: EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
                child: Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Judge: $judgeName", style: TextStyle(fontWeight: FontWeight.bold)),
                      ...criteriaVotes.entries.map((entry) {
                        return Text("${entry.key}: ${entry.value}");
                      }).toList(),
                      SizedBox(height: 4),
                      Text("Total: $total", style: TextStyle(fontStyle: FontStyle.italic)),
                    ],
                  ),
                ),
              );
            }).toList(),
          );
        },
      ),
    );
  }
}
