import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';

import 'addsupport.dart';

class SupportTab extends StatefulWidget {
  const SupportTab({Key? key}) : super(key: key);

  @override
  State<SupportTab> createState() => _SupportTabState();
}

class _SupportTabState extends State<SupportTab> {
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
                    const Icon(Icons.book_outlined, size: 18, color: Colors.black),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        member['name'],
                        style: GoogleFonts.bebasNeue(
                          color: Colors.cyan,
                          fontSize: 18,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    const Icon(Icons.email, size: 18, color: Colors.black),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        member['email'],
                        style: GoogleFonts.bebasNeue(
                          color: Colors.cyan,
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
          title: const Text('Delete Support?'),
          content: const Text('Are you sure you want to delete this Support?'),
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
      await FirebaseFirestore.instance.collection('support').doc(memberId).delete();
    } catch (e) {
      print('Error deleting member: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.cyan,
        title: TextField(
          controller: _searchController,
          decoration: const InputDecoration(
            hintText: "Type Support name",
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
                MaterialPageRoute(builder: (context) => AddSupport()),
              );
            },
            style: TextButton.styleFrom(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            child: const Text(
              'Add Support',
              style: TextStyle(color: Colors.cyan),
            ),
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('support').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No Support found'));
          }

          final members = snapshot.data!.docs;
          final filteredMembers = members.where((member) {
            final name = (member['name'] as String).toLowerCase();
            final email = (member['email'] as String).toLowerCase();
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
