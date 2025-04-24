import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminScreen extends StatefulWidget {
  @override
  _AdminScreenState createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  final TextEditingController eventController = TextEditingController();
  List<TextEditingController> criteriaControllers = List.generate(5, (index) => TextEditingController());

  Future<void> createEvent() async {
    String eventName = eventController.text.trim();
    List<String> criteria = [];

    if (eventName.isNotEmpty) {
      for (int i = 0; i < 5; i++) {
        String criterion = criteriaControllers[i].text.trim();
        criteria.add(criterion.isNotEmpty ? criterion : "N/A"); // ✅ Auto-fill "N/A" for missing criteria
      }

      await FirebaseFirestore.instance.collection('events').add({
        'name': eventName,
        'created_at': FieldValue.serverTimestamp(),
        'criteria': criteria, // ✅ Store criteria in Firestore
      });

      eventController.clear();
      criteriaControllers.forEach((controller) => controller.clear()); // Reset all inputs
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(title: Text('Admin: Create Event'), backgroundColor: Colors.orange),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: eventController,
              decoration: InputDecoration(labelText: 'Event Name', labelStyle: TextStyle(color: Colors.white)),
              style: TextStyle(color: Colors.white),
            ),
            SizedBox(height: 20),

            // Input fields for criteria
            for (int i = 0; i < 5; i++)
              TextField(
                controller: criteriaControllers[i],
                decoration: InputDecoration(labelText: 'Criterion ${i + 1}', labelStyle: TextStyle(color: Colors.white)),
                style: TextStyle(color: Colors.white),
              ),
            SizedBox(height: 20),

            ElevatedButton(
              onPressed: createEvent,
              style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
              child: Text('Create Event', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}
