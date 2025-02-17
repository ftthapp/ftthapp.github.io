import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:ftthapp/areateamlead/viewareateamlead.dart';
import 'package:ftthapp/auth/main.dart';
import 'package:ftthapp/client/viewclient.dart';
import 'package:ftthapp/engineer/viewengineer.dart';
import 'package:ftthapp/support/viewsupport.dart';
import 'package:ftthapp/tickets/viewtickets.dart';

import 'auth/login.dart';
import 'cvmanalyst/installations.dart';
import 'cvmanalyst/viewcvmanalyst.dart';
import 'engineer/assignedworkengineer.dart';
import 'engineer/assinedengineer.dart';
import 'engineer/engineerinstallation.dart';
// Grid section for displaying options
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
class HomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Welcome"),
        leading: Icon(Icons.menu),
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: () async {
              try {
                await FirebaseAuth.instance.signOut(); // Sign out the user
                Navigator.of(context).pushReplacement(MaterialPageRoute(
                  builder: (context) => MainPage(), // Navigate to login page
                ));
              } catch (e) {
                print("Error during logout: $e");
              }
            },
          ),
        ],
        elevation: 0,
        backgroundColor: Colors.purple[50],
      ),

      body: SingleChildScrollView(
        child: Column(
          children: [
            //   HeaderImage(),
            SizedBox(height: 20),
            GridSection(),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavBar(),
    );
  }
}

// Header image with the banner
class HeaderImage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(15.0),
        child: Image.network(
          'https://via.placeholder.com/400x150?text=Back+to+School',
          height: 150.0,
          width: double.infinity,
          fit: BoxFit.cover,
        ),
      ),
    );
  }
}



class GridSection extends StatefulWidget {
  @override
  _GridSectionState createState() => _GridSectionState();
}

class _GridSectionState extends State<GridSection> {
  List<GridItem> items = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchUserRole();
  }

  Future<void> fetchUserRole() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        // Handle unauthenticated state
        return;
      }

      final email = user.email;

      // Firestore collections for roles
      final adminRef = FirebaseFirestore.instance.collection('admin');
      final engineerRef = FirebaseFirestore.instance.collection('engineer');
      final areaTeamLeadRef = FirebaseFirestore.instance.collection('areateamlead');
      final cvmAnalystRef = FirebaseFirestore.instance.collection('cvmanalyst');
      final supportRef = FirebaseFirestore.instance.collection('support');
      final usersRef = FirebaseFirestore.instance.collection('users');

      // Check user's role by email
      if ((await adminRef.where('email', isEqualTo: email).get()).docs.isNotEmpty) {
        setState(() {
          items = [
            GridItem('Clients', Icons.people, Colors.purpleAccent, ClientsTab()),
            GridItem('CVM Analysts', Icons.analytics, Colors.orange, CvmAnalystTab()),
            GridItem('Engineers', Icons.engineering_sharp, Colors.redAccent, EngineerTab()),
            GridItem('Support', Icons.support_agent, Colors.cyan, SupportTab()),
            GridItem('Area Team Lead', Icons.leaderboard, Colors.green, AreaTeamLeadTab()),
            GridItem('Tickets', Icons.airplane_ticket, Colors.lightBlue, TicketsTab()),
            GridItem('Assign Engineers', Icons.engineering, Colors.pinkAccent, AssignEngineersPage()),
            GridItem('Engineer Tickets', Icons.engineering, Colors.pinkAccent, EngineerAssignedTicketsPage()),
            GridItem('Engineer Installation', Icons.engineering, Colors.pinkAccent, EngineerInstallationPage()),
            GridItem('Installations', Icons.engineering, Colors.green, InstallationsPage()),
          ];
        });
      } else if ((await engineerRef.where('email', isEqualTo: email).get()).docs.isNotEmpty) {
        setState(() {
          items = [
            GridItem('Engineer Tickets', Icons.engineering, Colors.pinkAccent, EngineerAssignedTicketsPage()),
            GridItem('Engineer Installation', Icons.engineering, Colors.pinkAccent, EngineerInstallationPage()),

          ];
        });
      } else if ((await areaTeamLeadRef.where('email', isEqualTo: email).get()).docs.isNotEmpty) {
        setState(() {
          items = [
            GridItem('Clients', Icons.people, Colors.purpleAccent, ClientsTab()),
          ];
        });
      } else if ((await cvmAnalystRef.where('email', isEqualTo: email).get()).docs.isNotEmpty) {
        setState(() {
          items = [
            GridItem('Assign Engineers', Icons.engineering, Colors.pinkAccent, AssignEngineersPage()),
            GridItem('Installations', Icons.engineering, Colors.green, InstallationsPage()),
            GridItem('Tickets', Icons.airplane_ticket, Colors.lightBlue, TicketsTab()),
          ];
        });
      } else if ((await usersRef.where('email', isEqualTo: email).get()).docs.isNotEmpty) {
        setState(() {
          items = [
            GridItem('Wait for Approval', Icons.engineering, Colors.pinkAccent, MainPage()),

          ];
        });
      } else if ((await supportRef.where('email', isEqualTo: email).get()).docs.isNotEmpty) {
        setState(() {
          items = [
            GridItem('Tickets', Icons.airplane_ticket, Colors.lightBlue, TicketsTab()),
          ];
        });
      }
    } catch (e) {
      print('Error fetching user role: $e');
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Center(child: CircularProgressIndicator());
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: GridView.builder(
        shrinkWrap: true,
        physics: NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 4, // Adjust number of columns here
          childAspectRatio: 1,
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
        ),
        itemCount: items.length,
        itemBuilder: (context, index) {
          return GridMenuItem(items[index]);
        },
      ),
    );
  }
}


class GridItem {
  final String title;
  final IconData icon;
  final Color color;
  final Widget destinationPage;

  GridItem(this.title, this.icon, this.color, this.destinationPage);
}

// Widget for each grid item
class GridMenuItem extends StatelessWidget {
  final GridItem item;

  GridMenuItem(this.item);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => item.destinationPage), // Use the destination page
        );
      },
      child: Column(
        children: [
          CircleAvatar(
            backgroundColor: item.color.withOpacity(0.2),
            child: Icon(item.icon, color: item.color),
          ),
          SizedBox(height: 8),
          Text(
            item.title,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12),
          ),
        ],
      ),
    );
  }
}

// Bottom navigation bar
class BottomNavBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      items: const <BottomNavigationBarItem>[
        BottomNavigationBarItem(
          icon: Icon(Icons.home),
          label: 'Home',
        ),

        BottomNavigationBarItem(
          icon: Icon(Icons.dashboard),
          label: 'Dashboard',
        ),
      ],
      currentIndex: 0, // Selected index can be managed with state
      selectedItemColor: Colors.purple,
      onTap: (index) {
        // Handle onTap
      },
    );
  }
}
