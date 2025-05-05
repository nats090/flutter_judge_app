import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminScreen extends StatefulWidget {
  @override
  _AdminScreenState createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  final TextEditingController eventController = TextEditingController();

  // Use a dynamic list for criteria items.
  // Each criteria item is a map with two controllers: one for "name" and one for "weight".
  List<Map<String, TextEditingController>> criteriaItems = [];

  @override
  void initState() {
    super.initState();
    // Start with one criteria row by default.
    addCriterion();
  }

  void addCriterion() {
    criteriaItems.add({
      'name': TextEditingController(),
      'weight': TextEditingController(),
    });
    setState(() {});
  }

  void removeCriterion(int index) {
    criteriaItems[index]['name']!.dispose();
    criteriaItems[index]['weight']!.dispose();
    criteriaItems.removeAt(index);
    setState(() {});
  }

  Future<void> createEvent() async {
    String eventName = eventController.text.trim();
    List<Map<String, dynamic>> criteriaList = [];

    if (eventName.isNotEmpty) {
      // Build criteria list from the dynamic rows.
      for (var item in criteriaItems) {
        String critName = item['name']!.text.trim();
        String weightStr = item['weight']!.text.trim();
        if (critName.isNotEmpty && weightStr.isNotEmpty) {
          double weight = double.tryParse(weightStr) ?? 0;
          criteriaList.add({"name": critName, "weight": weight});
        }
      }

      if (criteriaList.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text("Please enter at least one valid criterion.")));
        return;
      }

      await FirebaseFirestore.instance.collection('events').add({
        'name': eventName,
        'created_at': FieldValue.serverTimestamp(),
        'criteria': criteriaList, // Store list of criteria (each with name & weight)
      });

      eventController.clear();
      for (var item in criteriaItems) {
        item['name']!.clear();
        item['weight']!.clear();
      }
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Event created successfully")));
    }
  }

  @override
  void dispose() {
    eventController.dispose();
    for (var item in criteriaItems) {
      item['name']!.dispose();
      item['weight']!.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
          title: Text('Admin: Create Event'),
          backgroundColor: Colors.orange),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView( // make scrollable
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: eventController,
                decoration: InputDecoration(
                  labelText: 'Event Name',
                  labelStyle: TextStyle(color: Colors.white),
                ),
                style: TextStyle(color: Colors.white),
              ),
              SizedBox(height: 20),
              Text(
                "Criteria and Weight (%)",
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 10),
              // Create dynamic list of criteria rows.
              ListView.builder(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                itemCount: criteriaItems.length,
                itemBuilder: (context, index) {
                  return Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: TextField(
                          controller: criteriaItems[index]['name'],
                          decoration: InputDecoration(
                            labelText: 'Criterion ${index + 1}',
                            labelStyle: TextStyle(color: Colors.white),
                          ),
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                      SizedBox(width: 10),
                      Expanded(
                        flex: 2,
                        child: TextField(
                          controller: criteriaItems[index]['weight'],
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: 'Weight (%)',
                            labelStyle: TextStyle(color: Colors.white),
                          ),
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.remove_circle, color: Colors.red),
                        onPressed: () {
                          removeCriterion(index);
                        },
                      ),
                    ],
                  );
                },
              ),
              SizedBox(height: 10),
              ElevatedButton(
                onPressed: addCriterion,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                child:
                    Text('Add Criterion', style: TextStyle(color: Colors.white)),
              ),
              SizedBox(height: 20),
              Center(
                child: ElevatedButton(
                  onPressed: createEvent,
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                  child: Text('Create Event',
                      style: TextStyle(color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
