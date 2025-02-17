import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:mysql1/mysql1.dart';

class AddClients extends StatefulWidget {
  const AddClients({Key? key}) : super(key: key);

  @override
  State<AddClients> createState() => _AddClientsState();
}

class _AddClientsState extends State<AddClients> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _accountNumberController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _isLoading = false;


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Add Client',
          style: GoogleFonts.bebasNeue(fontSize: 28, color: Colors.black),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(25.0),
            child: Column(
              children: [
                if (_isLoading)
                  const Center(
                    child: CircularProgressIndicator(),
                  ),
                const SizedBox(height: 30),
                _buildTextField(
                  controller: _nameController,
                  label: 'Name',
                  hint: 'Enter client name',
                ),
                const SizedBox(height: 20),
                _buildTextField(
                  controller: _phoneController,
                  label: 'Phone Number',
                  hint: 'Enter phone number',
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 20),
                _buildTextField(
                  controller: _accountNumberController,
                  label: 'Account Number',
                  hint: 'Enter Account number',
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 20),
                _buildTextField(
                  controller: _addressController,
                  label: 'Address',
                  hint: 'Enter client address',
                ),
                const SizedBox(height: 25),
                _buildAddButton(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        filled: true,
        fillColor: Colors.grey[200],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.0),
        ),
      ),
    );
  }

  Widget _buildAddButton() {
    return GestureDetector(
      onTap: _addClient,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.purpleAccent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Center(
          child: Text(
            'Add Client',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
        ),
      ),
    );
  }


  Future<void> _oldaddClient() async {
    if (_nameController.text.isEmpty ||
        _phoneController.text.isEmpty ||
        _accountNumberController.text.isEmpty ||
        _addressController.text.isEmpty) {
      _showErrorDialog("All fields are required.");
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Generate a unique document ID for Firestore
      DocumentReference docRef = _firestore.collection('clients').doc();
      String docId = docRef.id;

      // Add client to Firestore
      await docRef.set({
        'id': docId,
        'name': _nameController.text.trim(),
        'phoneNumber': _phoneController.text.trim(),
        'accountNumber': _accountNumberController.text.trim(),
        'address': _addressController.text.trim(),
        'installation': 'Incomplete',
        'timestamp': FieldValue.serverTimestamp(),
      });

      // Add client to MySQL via PHP API
      final url = Uri.parse('http://localhost/projects/ftth/addclient.php'); // Update with your PHP API URL
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'id': docId,
          'name': _nameController.text.trim(),
          'phoneNumber': _phoneController.text.trim(),
          'accountNumber': _accountNumberController.text.trim(),
          'address': _addressController.text.trim(),
          'installation': 'Incomplete',
        }),
      );

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        if (result['success'] == true) {
          _showSuccessDialog("Client added successfully!");
        } else {
          _showErrorDialog("Failed to add client to MySQL: ${result['message']}");
        }
      } else {
        _showErrorDialog("Error: Unable to connect to the server. Status code: ${response.statusCode}");
      }
    } catch (e) {
      _showErrorDialog("Error: ${e.toString()}");
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }


  Future<void> _addClient() async {
    if (_nameController.text.isEmpty ||
        _phoneController.text.isEmpty ||
        _accountNumberController.text.isEmpty ||
        _addressController.text.isEmpty) {
      _showErrorDialog("All fields are required.");
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // MySQL connection settings
      final settings = ConnectionSettings(
        host: '127.0.0.1', // e.g., '127.0.0.1' or your server IP
        port: 3306,
        user: 'root',
        password: '',
        db: 'ftth',
      );

      // Establish a connection
      final conn = await MySqlConnection.connect(settings);

      // Insert the client into the MySQL database
      final result = await conn.query(
        'INSERT INTO clients (id, name, phoneNumber, accountNumber, address, installation) VALUES (?, ?, ?, ?, ?, ?)',
        [
          DateTime.now().millisecondsSinceEpoch.toString(), // Unique ID
          _nameController.text.trim(),
          _phoneController.text.trim(),
          _accountNumberController.text.trim(),
          _addressController.text.trim(),
          'Incomplete',
        ],
      );

      await conn.close();

      if (result.affectedRows == 1) {
        _showSuccessDialog("Client added successfully!");
      } else {
        _showErrorDialog("Failed to add client to MySQL.");
      }
    } catch (e) {
      _showErrorDialog("Error: ${e.toString()}");
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
          title: const Text('Success'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(message),
              const SizedBox(height: 10),

            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pop(context); // Close the current page
              },
              child: const Text('OK'),
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
          title: const Text('Error'),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }
}

