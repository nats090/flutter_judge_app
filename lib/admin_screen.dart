import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'user_list_screen.dart';

class AdminScreen extends StatefulWidget {
  @override
  _AdminScreenState createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  final TextEditingController eventController = TextEditingController();
  List<Map<String, TextEditingController>> criteriaItems = [];
 
  @override
  void initState() {
    super.initState();
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
      for (var item in criteriaItems) {
        String critName = item['name']!.text.trim();
        String weightStr = item['weight']!.text.trim();
        if (critName.isNotEmpty && weightStr.isNotEmpty) {
          double weight = double.tryParse(weightStr) ?? 0;
          criteriaList.add({"name": critName, "weight": weight});
        }
      }
 
      if (criteriaList.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Please enter at least one valid criterion.")),
        );
        return;
      }
 
      await FirebaseFirestore.instance.collection('events').add({
        'name': eventName,
        'created_at': FieldValue.serverTimestamp(),
        'criteria': criteriaList,
      });
 
      eventController.clear();
      for (var item in criteriaItems) {
        item['name']!.clear();
        item['weight']!.clear();
      }
 
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Event created successfully")),
      );
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
      appBar: AppBar(
        title: Text('Admin Dashboard'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(24),
        child: Card(
          elevation: 8,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Event Creation Section
                TextField(
                  controller: eventController,
                  decoration: InputDecoration(
                    labelText: 'Event Name',
                  ),
                ),
                SizedBox(height: 20),
                Text(
                  "Criteria and Weight (%)",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 10),
                ListView.builder(
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  itemCount: criteriaItems.length,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          Expanded(
                            flex: 3,
                            child: TextField(
                              controller: criteriaItems[index]['name'],
                              decoration: InputDecoration(
                                  labelText: 'Criterion ${index + 1}'),
                            ),
                          ),
                          SizedBox(width: 10),
                          Expanded(
                            flex: 2,
                            child: TextField(
                              controller: criteriaItems[index]['weight'],
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                  labelText: 'Weight (%)'),
                            ),
                          ),
                          IconButton(
                            icon: Icon(Icons.remove_circle, color: Colors.red),
                            onPressed: () {
                              removeCriterion(index);
                            },
                          ),
                        ],
                      ),
                    );
                  },
                ),
                SizedBox(height: 10),
                ElevatedButton(
                  onPressed: addCriterion,
                  child: Text('Add Criterion'),
                ),
                SizedBox(height: 20),
                Center(
                  child: ElevatedButton(
                    onPressed: createEvent,
                    child: Text('Create Event'),
                  ),
                ),
                SizedBox(height: 20),
                // Tutorial Sidebar for Event Creation
                ExpansionTile(
                  title: Text("Event Creation Tutorial",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.deepOrange,
                      )),
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(
                        "1. Enter the event name in the provided field.\n"
                        "2. Add one or more criteria along with their weights (in %).\n"
                        "3. Click on 'Add Criterion' to include more fields if needed.\n"
                        "4. Finally, hit 'Create Event' to save the event to the database.\n"
                        "Tip: Ensure the weights sum up meaningfully to represent judging criteria.",
                        style: TextStyle(fontSize: 14),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 20),
                Divider(),
                SizedBox(height: 10),
                Center(
                  child: ElevatedButton.icon(
                    icon: Icon(Icons.people),
                    label: Text("Manage Users"),
                    onPressed: () {
                      Navigator.push(context,
                          MaterialPageRoute(builder: (context) => UserListScreen()));
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
