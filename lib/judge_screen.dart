import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class JudgeScreen extends StatefulWidget {
  @override
  _JudgeScreenState createState() => _JudgeScreenState();
}

class _JudgeScreenState extends State<JudgeScreen> {
  String? selectedEvent;
  String? selectedEventName; // Holds the event name from Firestore.
  String? selectedContestant;
  TextEditingController judgeNameController = TextEditingController();
  Map<String, double> criteriaScores = {}; // Holds scores for each criterion.
  List<String> criteria = []; // Fetched criteria from Firestore.
  bool criteriaLoading = false;

  // Fetch the event's criteria and name
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
      List<String> fetchedCriteria = [];
      if (criteriaData is List<dynamic>) {
        fetchedCriteria =
            List<String>.from(criteriaData.map((e) => e.toString()));
      } else if (criteriaData is Map) {
        List<MapEntry<dynamic, dynamic>> entries =
            (criteriaData as Map).entries.toList();
        entries.sort((a, b) {
          int aKey = int.tryParse(a.key.toString()) ?? 999;
          int bKey = int.tryParse(b.key.toString()) ?? 999;
          return aKey.compareTo(bKey);
        });
        fetchedCriteria =
            entries.map((entry) => entry.value.toString()).toList();
      }
      
      String eventName = "Unknown Event";
      var eventData = eventDoc.data();
      if (eventData is Map<String, dynamic> &&
          eventData.containsKey('name')) {
        eventName = eventData['name'].toString();
      }
      
      setState(() {
        criteria = fetchedCriteria;
        selectedEventName = eventName;
      });
    } catch (e) {
      print("Error fetching criteria: $e");
    } finally {
      setState(() {
        criteriaLoading = false;
      });
    }
  }

  // Submit vote: ensures the scoreboard document exists,
  // then writes the vote document to the "votes" subcollection.
  void submitVote() async {
    String judgeName = judgeNameController.text.trim();
    if (selectedEvent != null &&
        selectedContestant != null &&
        judgeName.isNotEmpty) {
      // Reference to the contestant document in the scoreboard.
      var scoreboardRef = FirebaseFirestore.instance
          .collection('events')
          .doc(selectedEvent)
          .collection('scoreboard')
          .doc(selectedContestant);

      // Ensure the scoreboard document exists.
      await scoreboardRef.set({
        'contestant': selectedContestant,
      }, SetOptions(merge: true));

      // Calculate the total score.
      double totalScore =
          criteriaScores.values.fold(0, (sum, element) => sum + element);

      // Add a new vote document to the "votes" subcollection.
      await scoreboardRef.collection('votes').add({
        'judge': judgeName,
        'criteria_scores': criteriaScores,
        'total': totalScore,
        'timestamp': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Scores submitted by $judgeName!")));
      judgeNameController.clear();
      setState(() {
        criteriaScores.clear();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Judge Panel")),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Judge Name Input
            TextField(
              controller: judgeNameController,
              decoration: InputDecoration(labelText: "Enter your name"),
            ),
            SizedBox(height: 20),

            // Event Dropdown
            StreamBuilder<QuerySnapshot>(
              stream:
                  FirebaseFirestore.instance.collection('events').snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Text("No events available",
                      style: TextStyle(color: Colors.red));
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
                      value: doc.id, // using the document ID as the key
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

            // Contestant Dropdown: Merging default list with Firestore data.
            if (selectedEvent != null)
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('events')
                    .doc(selectedEvent)
                    .collection('scoreboard')
                    .snapshots(),
                builder: (context, snapshot) {
                  // Default contestants always to show.
                  final List<String> defaultContestants = ["CECE", "CBA", "CTELAN"];
                  // Get contestants from Firestore.
                  List<String> firestoreContestants = [];
                  if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
                    firestoreContestants = snapshot.data!.docs
                        .map((doc) => doc.id.toString())
                        .toList();
                  }
                  // Merge the two lists.
                  List<String> mergedContestants = List.from(defaultContestants);
                  for (var c in firestoreContestants) {
                    if (!mergedContestants.contains(c)) {
                      mergedContestants.add(c);
                    }
                  }
                  // (Optional: sort alphabetically)
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

            // Display Criteria with Sliders
            criteriaLoading
                ? Text("Loading criteria...", style: TextStyle(color: Colors.blue))
                : criteria.isNotEmpty
                    ? Column(
                        children: criteria.map((criterion) {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(criterion,
                                  style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold)),
                              Slider(
                                value: criteriaScores[criterion] ?? 0,
                                min: 0,
                                max: 10,
                                divisions: 10,
                                label:
                                    (criteriaScores[criterion] ?? 0).toString(),
                                onChanged: (newScore) {
                                  setState(() {
                                    criteriaScores[criterion] = newScore;
                                  });
                                },
                              ),
                              SizedBox(height: 10),
                            ],
                          );
                        }).toList(),
                      )
                    : Text("No criteria found",
                        style: TextStyle(color: Colors.red)),
            SizedBox(height: 20),

            // Submit Scores Button
            ElevatedButton(
              onPressed: submitVote,
              child: Text("Submit Scores"),
            ),
          ],
        ),
      ),
    );
  }
}