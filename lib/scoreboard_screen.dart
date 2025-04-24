import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'vote_detail_screen.dart';

class ScoreboardScreen extends StatefulWidget {
  @override
  _ScoreboardScreenState createState() => _ScoreboardScreenState();
}

class _ScoreboardScreenState extends State<ScoreboardScreen> {
  String? selectedEvent;
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Event Scoreboard")),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Event Dropdown.
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('events').snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Text("No events available", style: TextStyle(color: Colors.red));
                }
                return DropdownButtonFormField<String>(
                  decoration: InputDecoration(labelText: 'Select Event'),
                  value: selectedEvent,
                  items: snapshot.data!.docs.map((doc) {
                    String eventName = "Unknown Event";
                    var data = doc.data();
                    if (data is Map<String, dynamic> && data.containsKey('name')) {
                      eventName = data['name'].toString();
                    }
                    return DropdownMenuItem<String>(
                      value: doc.id,
                      child: Text(eventName),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      selectedEvent = value;
                    });
                  },
                );
              },
            ),
            SizedBox(height: 20),
            
            // Scoreboard List.
            Expanded(
              child: selectedEvent == null
                  ? Center(child: Text("Please select an event"))
                  : StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('events')
                          .doc(selectedEvent)
                          .collection('scoreboard')
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                          return Center(
                              child: Text("No scoreboard data available", style: TextStyle(color: Colors.red)));
                        }
                        return ListView(
                          children: snapshot.data!.docs.map((contestantDoc) {
                            String contestant = contestantDoc.id;
                            // Get votes for each contestant.
                            return FutureBuilder<QuerySnapshot>(
                              future: contestantDoc.reference.collection('votes').get(),
                              builder: (context, voteSnapshot) {
                                if (!voteSnapshot.hasData) {
                                  return ListTile(
                                      title: Text(contestant),
                                      subtitle: Text("Loading votes..."));
                                }
                                var votesDocs = voteSnapshot.data!.docs;
                                if (votesDocs.isEmpty) {
                                  return ListTile(
                                      title: Text(contestant),
                                      subtitle: Text("No votes submitted yet"));
                                }
                                double totalSum = 0;
                                for (var voteDoc in votesDocs) {
                                  var voteData = voteDoc.data() as Map<String, dynamic>;
                                  double voteTotal = (voteData['total'] is num)
                                      ? (voteData['total'] as num).toDouble()
                                      : 0.0;
                                  totalSum += voteTotal;
                                }
                                double averageScore = totalSum / votesDocs.length;
                                return ListTile(
                                  title: Text("$contestant | Total Score: ${averageScore.toStringAsFixed(1)}"),
                                  subtitle: Text("Judges: ${votesDocs.length}"),
                                  onTap: () {
                                    Navigator.push(context,
                                        MaterialPageRoute(builder: (context) => VoteDetailScreen(
                                          eventId: selectedEvent!,
                                          contestant: contestant,
                                        )));
                                  },
                                );
                              },
                            );
                          }).toList(),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}