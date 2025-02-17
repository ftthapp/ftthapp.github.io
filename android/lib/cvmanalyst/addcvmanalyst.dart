import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:intl/intl.dart';

import '../../auth/glassbox.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:intl/intl.dart';

class AddCvmAnalyst extends StatefulWidget {
  const AddCvmAnalyst({Key? key}) : super(key: key);

  @override
  State<AddCvmAnalyst> createState() => _AddCvmAnalystState();
}

class _AddCvmAnalystState extends State<AddCvmAnalyst> {

  bool _isLoading = false;

  String _selectedParent = '';

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;



  Future<List<Map<String, dynamic>>> fetchParents() async {
    QuerySnapshot snapshot = await _firestore.collection('users').get();
    return snapshot.docs.map((doc) {
      return {
        'id': doc.id, // Fetching parent ID
        'name': '${doc['name']}',
        'email': '${doc['email']} ',
      };
    }).toList();
  }

  @override
  void dispose() {


    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: _buildAppBar(),
        actions: [],
      ),
      //  backgroundColor: Colors.transparent,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(25.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (_isLoading)
                  Center(
                    child: CircularProgressIndicator(),
                  ),

                SizedBox(height: 30),

                _buildDropdownn(
                  future: fetchParents(),
                  value: _selectedParent,
                  hint: 'Select CVM Analyst',
                  onChanged: (value) {
                    setState(() {
                      _selectedParent = value!;

                    });
                  },
                ),
                SizedBox(height: 25),


                _buildAddButton(),
                SizedBox(height: 25),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return Stack(
      children: <Widget>[
        //   AppBarr(),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const SizedBox(width: 5),
            Column(
              children: [
                GestureDetector(
                  onTap: () {},
                  child: AnimatedTextKit(
                    animatedTexts: [
                      TyperAnimatedText(
                        'Add Cvm Analyst',
                        textStyle: GoogleFonts.bebasNeue(fontSize: 28, color: Colors.black),
                      ),
                    ],
                    pause: const Duration(milliseconds: 3000),
                    stopPauseOnTap: true,
                    repeatForever: true,
                  ),
                ),
              ],
            ),
            const SizedBox(width: 5),
          ],
        ),
      ],
    );
  }



  Widget _buildAddButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 25.0),
      child: GestureDetector(
        onTap:  ()async {
          await _addPastor();
        },
        child: Container(
          padding: EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.orange,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Text(
              'Add Cvm Analyst',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _addPastor() async {
    if (_selectedParent == null) {
      _showErrorDialog("Please select a parent.");
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Retrieve the parent details using the selected ID
      DocumentSnapshot selectedParentDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(_selectedParent)
          .get();

      if (!selectedParentDoc.exists) {
        _showErrorDialog("Selected parent does not exist.");
        return;
      }

      String name = selectedParentDoc['name'] ?? 'Unknown Name';
      String email = selectedParentDoc['email'] ?? 'Unknown Email';

      // Generate a unique document ID for Firestore
      String documentId = FirebaseFirestore.instance.collection('cvmanalyst').doc().id;

      // Add CVM Analyst to Firestore
      await FirebaseFirestore.instance.collection('cvmanalyst').doc(documentId).set({
        'availability': true,
        'name': name,
        'email': email,
        'timestamp': FieldValue.serverTimestamp(),
        'id': documentId,
      });

      // Optionally Add CVM Analyst to MySQL via PHP API
      final url = Uri.parse('http://localhost/projects/ftth/addcvmanalyst.php'); // Update with your PHP API URL
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'id': documentId,
          'availability': true,
          'name': name,
          'email': email,
        }),
      );

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        if (result['success'] == true) {
          _showSuccessDialog("CVM Analyst added successfully!");
        } else {
          _showErrorDialog("Failed to add CVM Analyst to MySQL: ${result['message']}");
        }
      } else {
        _showErrorDialog("Error: Unable to connect to the server. Status code: ${response.statusCode}");
      }
    } catch (e) {
      // Handle any errors and display a dialog
      _showErrorDialog("Error occurred: ${e.toString()}");
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showSuccessDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Success"),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pop(context); // Close the current page
              },
              child: Text("OK"),
            ),
          ],
        );
      },
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Error"),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Close the dialog
              },
              child: Text("OK"),
            ),
          ],
        );
      },
    );
  }




  Widget _buildDropdownn({
    required Future<List<Map<String, dynamic>>> future,
    required String value,
    required String hint,
    required void Function(String?) onChanged,
  }) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(child: Text('No data available.'));
        } else {
          return LayoutBuilder(
            builder: (context, constraints) {
              return Container(
                width: constraints.maxWidth, // Adjusts the dropdown width to the parent width
                child: DropdownButtonFormField<String>(
                  isExpanded: true, // Ensure dropdown items expand to fit the screen width
                  value: value.isNotEmpty ? value : null,
                  items: snapshot.data!
                      .map((parentData) => DropdownMenuItem<String>(
                    value: parentData['id'], // Use the parentId as value
                    child: Row(
                      children: [
                        Text(
                          parentData['name'], // Display the parent's name
                          style: GoogleFonts.lato(fontSize: 16),
                          overflow: TextOverflow.ellipsis, // Ensures long text doesn't overflow
                        ),
                        Text(
                        '- ', // Display the parent's name
                          style: GoogleFonts.lato(fontSize: 16),
                          overflow: TextOverflow.ellipsis, // Ensures long text doesn't overflow
                        ),
                        Text(
                          parentData['email'], // Display the parent's name
                          style: GoogleFonts.lato(fontSize: 16),
                          overflow: TextOverflow.ellipsis, // Ensures long text doesn't overflow
                        ),
                      ],
                    ),
                  ))
                      .toList(),
                  hint: Text(hint, style: GoogleFonts.lato(fontSize: 16, color: Colors.grey[600])),
                  onChanged: onChanged,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.grey[200],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                  ),
                  dropdownColor: Colors.grey[200],
                ),
              );
            },
          );
        }
      },
    );
  }



}
