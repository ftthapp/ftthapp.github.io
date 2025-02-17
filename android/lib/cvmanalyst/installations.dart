import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class InstallationsPage extends StatefulWidget {
  const InstallationsPage({Key? key}) : super(key: key);

  @override
  State<InstallationsPage> createState() => _InstallationsPageState();
}

class _InstallationsPageState extends State<InstallationsPage> {
  Future<void> assignEngineerToTicket(String clientId, String engineerId) async {
    try {
      final engineerSnapshot = await FirebaseFirestore.instance
          .collection('engineer')
          .doc(engineerId)
          .get();
      final ticketSnapshot = await FirebaseFirestore.instance
          .collection('clients')
          .doc(clientId)
          .get();

      if (engineerSnapshot.exists && ticketSnapshot.exists) {
        final engineerData = engineerSnapshot.data();
        final ticketData = ticketSnapshot.data();

        await FirebaseFirestore.instance
            .collection('clients')
            .doc(clientId)
            .update({
          'assignedEngineer': {
            'id': engineerId,
            'name': engineerData?['name'],
            'email': engineerData?['email'],
          },
          'installation': 'Assigned',
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Engineer assigned successfully'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Error assigning engineer'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Widget _buildTicketsTab(String status, List<DocumentSnapshot> engineers) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('clients')
          .where('installation', isEqualTo: status)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Text(
              status == 'Incomplete' ? 'No Assigned Installations' : 'No Unassigned Installations',
              style: const TextStyle(color: Colors.grey, fontSize: 16),
            ),
          );
        }

        final tickets = snapshot.data!.docs;
        return ListView.builder(
          padding: const EdgeInsets.all(8.0),
          itemCount: tickets.length,
          itemBuilder: (context, index) {
            return _buildTicketItem(tickets[index], engineers);
          },
        );
      },
    );
  }

  Widget _buildTicketItem(DocumentSnapshot ticket, List<DocumentSnapshot> engineers) {
    final data = ticket.data() as Map<String, dynamic>;

    String engineerName = "Not Assigned";
    String engineerEmail = "No Email";

    if (data.containsKey('assignedEngineer')) {
      final assignedEngineer = data['assignedEngineer'];

      if (assignedEngineer != null) {
        engineerName = assignedEngineer['name'] ?? "Not Assigned";
        engineerEmail = assignedEngineer['email'] ?? "No Email";
      }
    }

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Client Name: ${data['name'] ?? 'Unknown User'}',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            Text('Client Location: ${data['address'] ?? 'Unknown'}',
                style: const TextStyle(fontSize: 14, color: Colors.grey)),

            Text('Status: ${data['installation'] ?? 'Unknown'}',
                style: const TextStyle(fontSize: 14)),
            const SizedBox(height: 8),
            Text('Engineer: $engineerName',
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
            Text('Email: $engineerEmail',
                style: const TextStyle(fontSize: 14, color: Colors.grey)),
            Text('Comment: ${data['closeNote'] ?? 'Unknown'}',
                style: const TextStyle(fontSize: 14)),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () {
                  _showEngineerSelectionDialog(ticket.id, engineers);
                },
                icon: const Icon(Icons.assignment_ind, color: Colors.green),
                label: const Text('Assign Engineer'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showEngineerSelectionDialog(String ticketId, List<DocumentSnapshot> engineers) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          title: const Text('Assign Engineer'),
          content: SizedBox(
            height: 300,
            width: double.maxFinite,
            child: ListView.separated(
              separatorBuilder: (context, index) => const Divider(),
              itemCount: engineers.length,
              itemBuilder: (context, index) {
                final engineerData = engineers[index].data() as Map<String, dynamic>;
                return ListTile(
                  title: Text(engineerData['name'] ?? 'Unknown'),
                  subtitle: Text(engineerData['email'] ?? 'No Email'),
                  trailing: const Icon(Icons.arrow_forward, color: Colors.green),
                  onTap: () {
                    assignEngineerToTicket(ticketId, engineers[index].id);
                    Navigator.of(context).pop();
                  },
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Installations'),
        backgroundColor: Colors.green,
        elevation: 4,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('engineer').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No Engineers Found'));
          }

          final engineers = snapshot.data!.docs;

          return DefaultTabController(
            length: 2,
            child: Column(
              children: [
                const TabBar(
                  labelColor: Colors.green,
                  unselectedLabelColor: Colors.grey,
                  indicatorWeight: 4,
                  indicatorColor: Colors.green,
                  tabs: [
                    Tab(text: 'Unassigned Installations'),
                    Tab(text: 'Assigned Installations'),
                  ],
                ),
                Expanded(
                  child: TabBarView(
                    children: [
                      _buildTicketsTab('Incomplete', engineers),
                      _buildTicketsTab('Assigned', engineers),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
