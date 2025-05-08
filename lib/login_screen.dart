import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}
 
class _LoginScreenState extends State<LoginScreen> {
  bool isLogin = true;
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  // Only used in sign up mode.
  String role = 'Watcher'; // Default role.
  final _formKey = GlobalKey<FormState>();
 
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Top App Title
            SizedBox(height: 60),
            Text(
              "Vote It",
              style: TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.bold,
                color: Colors.deepOrange,
              ),
            ),
            SizedBox(height: 20),
            // Centered Login/SignUp Card
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 8,
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          isLogin ? 'Login' : 'Sign Up',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.deepOrange,
                          ),
                        ),
                        SizedBox(height: 20),
                        TextFormField(
                          controller: emailController,
                          decoration: InputDecoration(
                            labelText: 'Email',
                            prefixIcon: Icon(Icons.email),
                          ),
                          validator: (val) =>
                              val == null || val.isEmpty ? 'Enter email' : null,
                        ),
                        SizedBox(height: 16),
                        TextFormField(
                          controller: passwordController,
                          decoration: InputDecoration(
                            labelText: 'Password',
                            prefixIcon: Icon(Icons.lock),
                          ),
                          obscureText: true,
                          validator: (val) =>
                              (val == null || val.length < 6)
                                  ? 'Minimum 6 characters'
                                  : null,
                        ),
                        SizedBox(height: 16),
                        if (!isLogin)
                          DropdownButtonFormField<String>(
                            value: role,
                            items: ['Admin', 'Judge', 'Watcher']
                                .map((role) => DropdownMenuItem(
                                      value: role,
                                      child: Text(role),
                                    ))
                                .toList(),
                            onChanged: (val) {
                              setState(() {
                                role = val!;
                              });
                            },
                            decoration: InputDecoration(labelText: 'Role'),
                          ),
                        SizedBox(height: 20),
                        ElevatedButton(
                          onPressed: handleAuth,
                          child: Text(isLogin ? 'Login' : 'Sign Up'),
                        ),
                        SizedBox(height: 10),
                        TextButton(
                          onPressed: () {
                            setState(() {
                              isLogin = !isLogin;
                            });
                          },
                          child: Text(isLogin
                              ? "Don't have an account? Sign Up"
                              : "Already have an account? Login"),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(height: 40),
            // Footer Section
            Container(
              color: Colors.grey[200],
              padding: EdgeInsets.symmetric(vertical: 16, horizontal: 24),
              child: Column(
                children: [
                  Text(
                    "Contact: 09451664763",
                    style: TextStyle(color: Colors.grey[800]),
                  ),
                  SizedBox(height: 4),
                  Text(
                    "Facebook: Neil J A Lebrillo",
                    style: TextStyle(color: Colors.grey[800]),
                  ),
                  SizedBox(height: 4),
                  Text(
                    "© 2025 Vote It. All Rights Reserved. Designed with Flutter.",
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                ],
              ),
            ),
            SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
 
  void handleAuth() async {
    if (_formKey.currentState!.validate()) {
      String email = emailController.text.trim();
      String password = passwordController.text.trim();
      try {
        if (isLogin) {
          await FirebaseAuth.instance.signInWithEmailAndPassword(email: email, password: password);
        } else {
          // Sign up.
          UserCredential userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(email: email, password: password);
          String uid = userCredential.user!.uid;
          print("User created with uid: $uid");
          await FirebaseFirestore.instance.collection('users').doc(uid).set({
            'email': email,
            'role': role.toLowerCase(),
            'approved': (role.toLowerCase() == 'admin' || role.toLowerCase() == 'judge') ? "false" : "true",
          });
          print("User document for uid $uid created in Firestore.");
        }
      } catch (e) {
        print("Error during authentication: $e");
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }
}
