import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';

import 'addtickets.dart';

class TicketsTab extends StatefulWidget {
  const TicketsTab({Key? key}) : super(key: key);

  @override
  State<TicketsTab> createState() => _TicketsTabState();
}

class _TicketsTabState extends State<TicketsTab> {
  final TextEditingController _searchController = TextEditingController();
  String _searchText = "";
  bool _isGridView = true;

  void _filterMembers(String query, List<DocumentSnapshot> members) {
    setState(() {
      _searchText = query.toLowerCase();
    });
  }

  Widget _buildGridView(List<DocumentSnapshot> filteredMembers) {
    return LayoutBuilder(
      builder: (context, constraints) {
        int crossAxisCount = (constraints.maxWidth > 600) ? 5 : 2;
        double aspectRatio = (constraints.maxWidth > 600) ? 2 / 2.5 : 2 / 2;

        return GridView.builder(
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            childAspectRatio: aspectRatio,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
          ),
          padding: const EdgeInsets.all(8),
          itemCount: filteredMembers.length,
          itemBuilder: (context, index) => _buildItem(filteredMembers[index]),
        );
      },
    );
  }

  Widget _buildListView(List<DocumentSnapshot> filteredMembers) {
    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: filteredMembers.length,
      itemBuilder: (context, index) => _buildItem(filteredMembers[index]),
    );
  }

  Widget _buildItem(DocumentSnapshot member) {
    final memberId = member.id;

    return InkWell(
      onLongPress: () {
        _showDeleteDialog(memberId);
      },
      onTap: () {
        // Add navigation to details page or desired functionality
      },
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 8.0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20.0),
          border: Border.all(color: Colors.red.shade100),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(15.0),
              color: Colors.white.withOpacity(0.85),
            ),
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [

                Row(
                  children: [
                    const Icon(Icons.pin_drop_sharp, size: 18, color: Colors.black),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        member['clientLocation'],
                        style: GoogleFonts.bebasNeue(
                          color: Colors.lightBlue,
                          fontSize: 18,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.phone, size: 18, color: Colors.black),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        member['clientNumber'],
                        style: GoogleFonts.bebasNeue(
                          color: Colors.lightBlue,
                          fontSize: 18,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.date_range, size: 18, color: Colors.black),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        member['dateIssueRaised'],
                        style: GoogleFonts.bebasNeue(
                          color: Colors.lightBlue,
                          fontSize: 18,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.description, size: 18, color: Colors.black),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        member['remarks'],
                        style: GoogleFonts.bebasNeue(
                          color: Colors.lightBlue,
                          fontSize: 18,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showDeleteDialog(String memberId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Tickets?'),
          content: const Text('Are you sure you want to delete this Tickets?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                _deleteMember(memberId);
                Navigator.pop(context);
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteMember(String memberId) async {
    try {
      await FirebaseFirestore.instance.collection('tickets').doc(memberId).delete();
    } catch (e) {
      print('Error deleting member: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.lightBlue,
        title: TextField(
          controller: _searchController,
          decoration: const InputDecoration(
            hintText: "Type Tickets name",
            hintStyle: TextStyle(color: Colors.white),
            border: InputBorder.none,
          ),
          onChanged: (value) => setState(() {
            _searchText = value.toLowerCase();
          }),
        ),
        actions: [
          IconButton(
            icon: Icon(_isGridView ? Icons.view_list : Icons.grid_view),
            onPressed: () {
              setState(() {
                _isGridView = !_isGridView;
              });
            },
          ),
          TextButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => AddTickets()),
              );
            },
            style: TextButton.styleFrom(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            child: const Text(
              'Add Tickets',
              style: TextStyle(color: Colors.lightBlue),
            ),
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('tickets').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No Tickets found'));
          }

          final members = snapshot.data!.docs;
          final filteredMembers = members.where((member) {
            final name = (member['clientNumber'] as String).toLowerCase();
            final email = (member['clientLocation'] as String).toLowerCase();
            return name.contains(_searchText) || email.contains(_searchText);
          }).toList();

          return _isGridView
              ? _buildGridView(filteredMembers)
              : _buildListView(filteredMembers);
        },
      ),
    );
  }
}
