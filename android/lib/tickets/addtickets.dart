import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';


class AddTickets extends StatefulWidget {
  const AddTickets({Key? key}) : super(key: key);

  @override
  State<AddTickets> createState() => _AddTicketsState();
}

class _AddTicketsState extends State<AddTickets> {
  bool _isLoading = false;

  final TextEditingController _clientNumberController = TextEditingController();
  final TextEditingController _clientLocationController = TextEditingController();
  final TextEditingController _ticketNumberController = TextEditingController();
  final TextEditingController _dateIssueRaisedController = TextEditingController();
  final TextEditingController _remarksController = TextEditingController();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void dispose() {
    _clientNumberController.dispose();
    _ticketNumberController.dispose();
    _clientLocationController.dispose();
    _dateIssueRaisedController.dispose();
    _remarksController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: _buildAppBar(),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(25.0),
            child: Column(
              children: [
                if (_isLoading)
                  const Center(child: CircularProgressIndicator()),

                const SizedBox(height: 30),

                _buildTextField(
                  controller: _ticketNumberController,
                  label: 'Ticket Number',
                ),
                const SizedBox(height: 25),

                _buildTextField(
                  controller: _clientNumberController,
                  label: 'Client Number',
                ),
                const SizedBox(height: 25),

                _buildTextField(
                  controller: _clientLocationController,
                  label: 'Client Location',
                ),
                const SizedBox(height: 25),

                _buildTextField(
                  controller: _dateIssueRaisedController,
                  label: 'Date Issue Raised',
                  onTap: () async {
                    DateTime? selectedDate = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now(),
                      firstDate: DateTime(2000),
                      lastDate: DateTime(2100),
                    );
                    if (selectedDate != null) {
                      _dateIssueRaisedController.text =
                          DateFormat('dd MMM yyyy').format(selectedDate);
                    }
                  },
                  readOnly: true,
                ),
                const SizedBox(height: 25),

                _buildTextField(
                  controller: _remarksController,
                  label: 'Remarks',
                  maxLines: 3,
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

  Widget _buildAppBar() {
    return AnimatedTextKit(
      animatedTexts: [
        TyperAnimatedText(
          'Add Tickets',
          textStyle: GoogleFonts.bebasNeue(fontSize: 28, color: Colors.black),
        ),
      ],
      repeatForever: true,
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    int maxLines = 1,
    bool readOnly = false,
    VoidCallback? onTap,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      readOnly: readOnly,
      onTap: onTap,
      decoration: InputDecoration(
        labelText: label,
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
      onTap: _addTicket,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.lightBlue,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Center(
          child: Text(
            'Add Ticket',
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

  Future<void> _addTicket() async {
    if (_clientLocationController.text.isEmpty ||
        _clientNumberController.text.isEmpty ||
        _ticketNumberController.text.isEmpty ||
        _dateIssueRaisedController.text.isEmpty ||
        _remarksController.text.isEmpty) {
      _showErrorDialog("All fields are required.");
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Generate a unique document ID
      DocumentReference docRef = _firestore.collection('tickets').doc();
      String docId = docRef.id;

      // Add ticket to Firestore
      await docRef.set({
        'id': docId,
        'status': 'Unassigned',
        'clientNumber': _clientNumberController.text,
        'ticketNumber': _ticketNumberController.text,
        'clientLocation': _clientLocationController.text,
        'dateIssueRaised': _dateIssueRaisedController.text,
        'remarks': _remarksController.text,
        'timestamp': FieldValue.serverTimestamp(),
      });

      // Add ticket to MySQL via PHP API
      final url = Uri.parse('http://localhost/projects/ftth/addticket.php'); // Update with your PHP API URL
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'id': docId,
          'status': 'Unassigned',
          'clientNumber': _clientNumberController.text,
          'ticketNumber': _ticketNumberController.text,
          'clientLocation': _clientLocationController.text,
          'dateIssueRaised': _dateIssueRaisedController.text,
          'remarks': _remarksController.text,
        }),
      );

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        if (result['success'] == true) {
          _showSuccessDialog("Ticket added successfully!");
        } else {
          _showErrorDialog("Failed to add ticket to MySQL: ${result['message']}");
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

  void _showSuccessDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Success"),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Error"),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }
}
