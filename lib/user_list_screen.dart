import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';

class UserListScreen extends StatelessWidget {
  const UserListScreen({Key? key}) : super(key: key);
 
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("User Management"),
        centerTitle: true,
      ),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: StreamBuilder<QuerySnapshot>(
          stream:
              FirebaseFirestore.instance.collection("users").snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Center(child: Text("Error: ${snapshot.error}"));
            }
            if (!snapshot.hasData) {
              return Center(child: CircularProgressIndicator());
            }
            final users = snapshot.data!.docs;
            if (users.isEmpty) {
              return Center(child: Text("No users found"));
            }
            return ListView.separated(
              itemCount: users.length,
              separatorBuilder: (context, index) =>
                  Divider(color: Colors.grey),
              itemBuilder: (context, index) {
                final userDoc = users[index];
                final userData = userDoc.data() as Map<String, dynamic>;
                final email = userData["email"] ?? "No Email";
                final role = userData["role"] ?? "N/A";
                final bool approved =
                    userData["approved"]?.toString().toLowerCase() ==
                        "true";
 
                return Card(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                  margin:
                      EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                  child: ListTile(
                    title: Text(email),
                    subtitle: Text("Role: $role | Approved: ${approved.toString()}"),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (role.toString().toLowerCase() == "admin" ||
                            role.toString().toLowerCase() == "judge")
                          IconButton(
                            icon: Icon(
                              approved
                                  ? Icons.check_box
                                  : Icons.check_box_outline_blank,
                              color: Colors.green,
                            ),
                            onPressed: () async {
                              bool? confirmed = await showDialog<bool>(
                                context: context,
                                builder: (BuildContext context) {
                                  return AlertDialog(
                                    title: Text(approved
                                        ? "Disapprove User?"
                                        : "Approve User?"),
                                    content: Text("Are you sure you want to " +
                                        (approved
                                            ? "disapprove"
                                            : "approve") +
                                        " this user?"),
                                    actions: [
                                      TextButton(
                                        child: Text("Cancel"),
                                        onPressed: () => Navigator.of(context).pop(false),
                                      ),
                                      ElevatedButton(
                                        child: Text("Confirm"),
                                        onPressed: () => Navigator.of(context).pop(true),
                                      ),
                                    ],
                                  );
                                },
                              );
                              if (confirmed == true) {
                                await FirebaseFirestore.instance
                                    .collection("users")
                                    .doc(userDoc.id)
                                    .update({
                                  "approved": approved ? "false" : "true"
                                });
                              }
                            },
                          ),
                        IconButton(
                          icon: Icon(Icons.delete, color: Colors.red),
                          onPressed: () async {
                            bool? deleteConfirmed = await showDialog<bool>(
                              context: context,
                              builder: (BuildContext context) {
                                return AlertDialog(
                                  title: Text("Delete Account"),
                                  content: Text("Are you sure you want to delete this account? This action cannot be undone."),
                                  actions: [
                                    TextButton(
                                      child: Text("Cancel"),
                                      onPressed: () => Navigator.of(context).pop(false),
                                    ),
                                    ElevatedButton(
                                      child: Text("Delete"),
                                      onPressed: () => Navigator.of(context).pop(true),
                                    ),
                                  ],
                                );
                              },
                            );
                            if (deleteConfirmed == true) {
                              try {
                                final callable = FirebaseFunctions.instance
                                    .httpsCallable("deleteUserAccount");
                                final result = await callable.call({"uid": userDoc.id});
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text(result.data["message"] ?? "User deleted")),
                                );
                              } catch (error) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text("Error deleting user: $error")),
                                );
                              }
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
