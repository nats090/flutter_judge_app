import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'vote_detail_screen.dart';

class ScoreboardScreen extends StatefulWidget {
  @override
  _ScoreboardScreenState createState() => _ScoreboardScreenState();
}

class _ScoreboardScreenState extends State<ScoreboardScreen> {
  String? selectedEvent;
  String? userRole; // "admin", "judge", or "watcher"

  @override
  void initState() {
    super.initState();
    // Fetch the current user's role when this screen loads.
    getUserRole().then((role) {
      setState(() {
        userRole = role;
      });
    });
  }

  /// Fetches the current user's role from Firestore.
  Future<String> getUserRole() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) return "";
    DocumentSnapshot userDoc =
        await FirebaseFirestore.instance.collection("users").doc(user.uid).get();
    if (userDoc.exists) {
      Map<String, dynamic> data = userDoc.data() as Map<String, dynamic>;
      return data["role"]?.toString().toLowerCase() ?? "";
    }
    return "";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Event Scoreboard")),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Scoreboard Info Tutorial (existing ExpansionTile)
            ExpansionTile(
              title: Text("Scoreboard Info",
                  style: TextStyle(
                      fontWeight: FontWeight.bold, color: Colors.deepOrange)),
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    "• Select an event from the dropdown to view its scoreboard.\n"
                    "• The average score per contestant is calculated from the total votes.\n"
                    "• Tap on a contestant to view detailed vote breakdowns.\n"
                    "• Use the refresh button on the vote details screen for the latest updates.\n"
                    "Admin users can delete an event by tapping the trash icon.",
                    style: TextStyle(fontSize: 14),
                  ),
                ),
              ],
            ),
            SizedBox(height: 20),
            // Event Dropdown with Delete Button if admin
            FutureBuilder<QuerySnapshot>(
              future:
                  FirebaseFirestore.instance.collection('events').get(),
              builder: (context, snapshot) {
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Text("No events available",
                      style: TextStyle(color: Colors.red));
                }
                return Row(
                  children: [
                    // Expanded dropdown
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        decoration:
                            InputDecoration(labelText: 'Select Event'),
                        value: selectedEvent,
                        items: snapshot.data!.docs.map((doc) {
                          String eventName = "Unknown Event";
                          var data = doc.data();
                          if (data is Map<String, dynamic> &&
                              data.containsKey('name')) {
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
                      ),
                    ),
                    SizedBox(width: 8),
                    // Show the delete button only if userRole is admin and an event is selected.
                    if (userRole == "admin" && selectedEvent != null)
                      IconButton(
                        icon: Icon(Icons.delete, color: Colors.red),
                        tooltip: "Delete Event",
                        onPressed: () async {
                          bool? confirmed = await showDialog<bool>(
                            context: context,
                            builder: (BuildContext context) {
                              return AlertDialog(
                                title: Text("Delete Event"),
                                content: Text(
                                    "Are you sure you want to delete this event? This action cannot be undone."),
                                actions: [
                                  TextButton(
                                    child: Text("Cancel"),
                                    onPressed: () =>
                                        Navigator.of(context).pop(false),
                                  ),
                                  ElevatedButton(
                                    child: Text("Delete"),
                                    onPressed: () =>
                                        Navigator.of(context).pop(true),
                                  ),
                                ],
                              );
                            },
                          );
                          if (confirmed == true) {
                            await FirebaseFirestore.instance
                                .collection('events')
                                .doc(selectedEvent)
                                .delete();
                            setState(() {
                              selectedEvent = null;
                            });
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text("Event deleted")),
                            );
                          }
                        },
                      ),
                  ],
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
                              child: Text("No scoreboard data available",
                                  style: TextStyle(color: Colors.red)));
                        }
                        return ListView(
                          children:
                              snapshot.data!.docs.map((contestantDoc) {
                            String contestant = contestantDoc.id;
                            return FutureBuilder<QuerySnapshot>(
                              future: contestantDoc.reference
                                  .collection('votes')
                                  .get(),
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
                                      subtitle:
                                          Text("No votes submitted yet"));
                                }
                                double totalSum = 0;
                                for (var voteDoc in votesDocs) {
                                  var voteData =
                                      voteDoc.data() as Map<String, dynamic>;
                                  double voteTotal =
                                      (voteData['total'] is num)
                                          ? (voteData['total'] as num)
                                              .toDouble()
                                          : 0.0;
                                  totalSum += voteTotal;
                                }
                                double averageScore =
                                    totalSum / votesDocs.length;
                                return ListTile(
                                  title: Text(
                                      "$contestant | Total Score: ${averageScore.toStringAsFixed(1)}"),
                                  subtitle: Text("Judges: ${votesDocs.length}"),
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            VoteDetailScreen(
                                          eventId: selectedEvent!,
                                        ),
                                      ),
                                    );
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
