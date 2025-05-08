import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class JudgeScreen extends StatefulWidget {
  @override
  _JudgeScreenState createState() => _JudgeScreenState();
}

class _JudgeScreenState extends State<JudgeScreen> {
  String? selectedEvent;
  String? selectedEventName;
  String? selectedContestant;
  TextEditingController judgeNameController = TextEditingController();
 
  List<Map<String, dynamic>> criteria = [];
  Map<String, double> criteriaScores = {};
  bool criteriaLoading = false;
 
  Future<void> fetchCriteria(String eventId) async {
    setState(() {
      criteriaLoading = true;
      criteria = [];
      selectedEventName = null;
    });
    try {
      DocumentSnapshot eventDoc = await FirebaseFirestore.instance
          .collection('events')
          .doc(eventId)
          .get();
 
      var criteriaData = eventDoc.get('criteria');
      List<Map<String, dynamic>> fetchedCriteria = [];
      if (criteriaData is List<dynamic>) {
        for (var item in criteriaData) {
          if (item is Map) {
            String critName = item["name"]?.toString() ?? "";
            double critWeight =
                double.tryParse(item["weight"]?.toString() ?? "0") ?? 0;
            if (critName.isNotEmpty) {
              fetchedCriteria.add({"name": critName, "weight": critWeight});
            }
          }
        }
      }
 
      String eventName = "Unknown Event";
      var eventData = eventDoc.data();
      if (eventData is Map<String, dynamic> && eventData.containsKey('name')) {
        eventName = eventData['name'].toString();
      }
 
      setState(() {
        criteria = fetchedCriteria;
        selectedEventName = eventName;
      });
    } catch (e) {
      print("Error fetching criteria: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error fetching criteria: $e")),
      );
    } finally {
      setState(() {
        criteriaLoading = false;
      });
    }
  }
 
  void submitVote() async {
    String judgeName = judgeNameController.text.trim();
    if (selectedEvent != null &&
        selectedContestant != null &&
        judgeName.isNotEmpty) {
      try {
        var scoreboardRef = FirebaseFirestore.instance
            .collection('events')
            .doc(selectedEvent)
            .collection('scoreboard')
            .doc(selectedContestant);
 
        QuerySnapshot existingVote = await scoreboardRef
            .collection('votes')
            .where('judge', isEqualTo: judgeName)
            .get();
        if (existingVote.docs.isNotEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("You have already submitted a score for $selectedContestant.")),
          );
          return;
        }
 
        await scoreboardRef.set({
          'contestant': selectedContestant,
        }, SetOptions(merge: true));
 
        double weightedTotal = 0.0;
        for (var crit in criteria) {
          String critName = crit["name"];
          double weight = crit["weight"];
          double score = criteriaScores[critName] ?? 0;
          weightedTotal += score * (weight / 100);
        }
 
        await scoreboardRef.collection('votes').add({
          'judge': judgeName,
          'criteria_scores': criteriaScores,
          'total': weightedTotal,
          'timestamp': FieldValue.serverTimestamp(),
        });
 
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Scores submitted by $judgeName!")),
        );
        judgeNameController.clear();
        setState(() {
          criteriaScores.clear();
        });
      } catch (e) {
        print("Error submitting vote: $e");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error submitting vote: $e")),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Please fill in all fields.")),
      );
    }
  }
 
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Judge Panel")),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(24),
        child: Column(
          children: [
            TextField(
              controller: judgeNameController,
              decoration: InputDecoration(
                labelText: "Enter your name",
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 20),
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
                    if (value != null) {
                      setState(() {
                        selectedEvent = value;
                        selectedContestant = null;
                        criteriaScores.clear();
                        criteria = [];
                        selectedEventName = null;
                      });
                      fetchCriteria(value);
                    }
                  },
                );
              },
            ),
            SizedBox(height: 20),
            if (selectedEvent != null)
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('events')
                    .doc(selectedEvent)
                    .collection('scoreboard')
                    .snapshots(),
                builder: (context, snapshot) {
                  final List<String> defaultContestants = ["CECE", "CBA", "CTELAN"];
                  List<String> firestoreContestants = [];
                  if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
                    firestoreContestants = snapshot.data!.docs
                        .map((doc) => doc.id.toString())
                        .toList();
                  }
                  List<String> mergedContestants = List.from(defaultContestants);
                  for (var c in firestoreContestants) {
                    if (!mergedContestants.contains(c)) {
                      mergedContestants.add(c);
                    }
                  }
                  mergedContestants.sort();
                  return DropdownButtonFormField<String>(
                    decoration: InputDecoration(labelText: 'Select Contestant'),
                    value: selectedContestant,
                    items: mergedContestants.map((contestant) {
                      return DropdownMenuItem<String>(
                        value: contestant,
                        child: Text(contestant),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        selectedContestant = value;
                      });
                    },
                  );
                },
              ),
            SizedBox(height: 20),
            criteriaLoading
                ? Text("Loading criteria...", style: TextStyle(color: Colors.blue))
                : criteria.isNotEmpty
                    ? Column(
                        children: criteria.map((criterion) {
                          String critName = criterion["name"];
                          double weight = criterion["weight"];
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "$critName - ${weight.toInt()}%",
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                              Slider(
                                value: criteriaScores[critName] ?? 0,
                                min: 0,
                                max: 10,
                                divisions: 10,
                                label: (criteriaScores[critName] ?? 0).toString(),
                                onChanged: (newScore) {
                                  setState(() {
                                    criteriaScores[critName] = newScore;
                                  });
                                },
                              ),
                              SizedBox(height: 10),
                            ],
                          );
                        }).toList(),
                      )
                    : Text("No criteria found", style: TextStyle(color: Colors.red)),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: submitVote,
              child: Text("Submit Scores"),
            ),
            SizedBox(height: 20),
            // Voting Tutorial
            ExpansionTile(
              title: Text("Voting Instructions", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.deepOrange)),
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    "1. Select an event from the dropdown.\n"
                    "2. Choose a contestant from the merged list.\n"
                    "3. Adjust the sliders for each criterion to score between 0-10.\n"
                    "4. Enter your name and hit 'Submit Scores'.\n"
                    "Note: You cannot submit more than one vote per contestant.",
                    style: TextStyle(fontSize: 14),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
