import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class EngineerInstallationPage extends StatefulWidget {
  const EngineerInstallationPage({Key? key}) : super(key: key);

  @override
  State<EngineerInstallationPage> createState() =>
      _EngineerInstallationPageState();
}

class _EngineerInstallationPageState
    extends State<EngineerInstallationPage> {
  final User? currentUser = FirebaseAuth.instance.currentUser;

  @override
  Widget build(BuildContext context) {
    if (currentUser == null) {
      return const Center(
        child: Text('No user logged in.'),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Assigned Installations'),
        backgroundColor: Colors.pinkAccent,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('clients')
            .where('assignedEngineer.email', isEqualTo: currentUser!.email)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text('No tickets assigned to you.'),
            );
          }

          final tickets = snapshot.data!.docs;

          return ListView.builder(
            itemCount: tickets.length,
            itemBuilder: (context, index) {
              return _buildTicketItem(tickets[index]);
            },
          );
        },
      ),
    );
  }

  Widget _buildTicketItem(DocumentSnapshot ticket) {
    final data = ticket.data() as Map<String, dynamic>;

    return Card(
      elevation: 5,
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: ListTile(
        title: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Client Name: ${data['name'] ?? 'Unknown User'}'),
            Text('Client Location: ${data['address'] ?? 'Unknown'}'),
            Text('Client Number: ${data['phoneNumber'] ?? 'Unknown'}'),


          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Status: ${data['installation'] ?? 'Unspecified'}'),
          ],
        ),
        trailing: ElevatedButton(
          onPressed: () => _showCloseTicketDialog(ticket),
          child: const Text('Mark Complete'),
        ),
      ),
    );
  }

  void _showCloseTicketDialog(DocumentSnapshot ticket) {
    final TextEditingController closeNoteController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Closure Note'),
          content: TextField(
            controller: closeNoteController,
            decoration: const InputDecoration(
              labelText: 'Closure Note',
              hintText: 'Enter details about the work done',
            ),
            maxLines: 3,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final closeNote = closeNoteController.text.trim();

                if (closeNote.isNotEmpty) {
                  // Update the ticket in Firestore
                  await FirebaseFirestore.instance
                      .collection('clients')
                      .doc(ticket.id)
                      .update({
                    'status': 'Completed',
                    'closeNote': closeNote,
                    'completedAt': FieldValue.serverTimestamp(),
                  });

                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Ticket marked as completed!'),
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please enter a closure note.'),
                    ),
                  );
                }
              },
              child: const Text('Submit'),
            ),
          ],
        );
      },
    );
  }
}
