import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import '../login/login_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  AdminDashboardScreenState createState() => AdminDashboardScreenState();
}

class AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Fetch user sign-up activity over time
  Future<List<ActivityData>> _fetchUserActivity() async {
    try {
      final querySnapshot = await _firestore.collection('users').get();
      final users = querySnapshot.docs;

      final Map<String, int> activity = {};
      for (var user in users) {
        final createdAt = (user['createdAt'] as Timestamp).toDate();
        final date = DateTime(createdAt.year, createdAt.month, createdAt.day);
        activity[date.toIso8601String()] =
            (activity[date.toIso8601String()] ?? 0) + 1;
      }

      return activity.entries
          .map((entry) => ActivityData(DateTime.parse(entry.key), entry.value))
          .toList();
    } catch (e) {
      throw Exception("Failed to fetch user activity: $e");
    }
  }

  // Delete a user and their notes with confirmation
  Future<void> _deleteUser(String userId, String username) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete User"),
        content: Text(
            "Are you sure you want to delete user $username and all their notes?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text("Delete", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        // Delete all notes associated with the user
        final notesQuery = await _firestore
            .collection('notes')
            .where('userId', isEqualTo: userId)
            .get();

        for (var note in notesQuery.docs) {
          await _firestore.collection('notes').doc(note.id).delete();
        }

        // Delete the user
        await _firestore.collection('users').doc(userId).delete();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  "User $username and all their notes deleted successfully.")),
        );
        setState(() {});
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to delete user $username: $e")),
        );
      }
    }
  }

  // Logout
  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('current_user');
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF9EB),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF7C242),
        centerTitle: true,
        elevation: 0,
        toolbarHeight: 80,
        title: const Text(
          "Admin Dashboard",
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // User Activity Over Time (Line Chart)
            Expanded(
              flex: 1,
              child: FutureBuilder<List<ActivityData>>(
                future: _fetchUserActivity(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return const Center(
                      child: Text("Failed to load user activity."),
                    );
                  }

                  final data = snapshot.data ?? [];

                  return SfCartesianChart(
                    title: ChartTitle(
                      text: "User Activity Over Time",
                      textStyle: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    primaryXAxis: DateTimeAxis(),
                    primaryYAxis: NumericAxis(),
                    series: <ChartSeries>[
                      LineSeries<ActivityData, DateTime>(
                        dataSource: data,
                        xValueMapper: (ActivityData data, _) => data.date,
                        yValueMapper: (ActivityData data, _) => data.count,
                        markerSettings: const MarkerSettings(isVisible: true),
                      )
                    ],
                  );
                },
              ),
            ),

            // User List Section
            Expanded(
              flex: 2,
              child: Column(
                children: [
                  const Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Text(
                      "List of Users",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: Color(0xFF3C3C3C),
                      ),
                    ),
                  ),
                  Expanded(
                    child: FutureBuilder<List<Map<String, dynamic>>>(
                      future: _fetchUsers(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator());
                        }
                        if (snapshot.hasError) {
                          return const Center(
                            child: Text("Failed to load users."),
                          );
                        }

                        final users = snapshot.data ?? [];
                        if (users.isEmpty) {
                          return const Center(
                            child: Text(
                              "No users available.",
                              style: TextStyle(fontSize: 18, color: Colors.grey),
                            ),
                          );
                        }

                        return ListView.builder(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          itemCount: users.length,
                          itemBuilder: (context, index) {
                            final user = users[index];
                            return Card(
                              margin: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 8),
                              elevation: 4,
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: const Color(0xFFF7C242),
                                  child: Text(
                                    user['username']?[0]?.toUpperCase() ?? "U",
                                    style: const TextStyle(color: Colors.black),
                                  ),
                                ),
                                title: Text(
                                  user['username'] ?? "Unknown",
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: Color(0xFF3C3C3C),
                                  ),
                                ),
                                subtitle: Text(
                                  user['email'] ?? "No Email",
                                  style:
                                      const TextStyle(color: Color(0xFFA0A0A0)),
                                ),
                                trailing: IconButton(
                                  icon: const Icon(Icons.delete, color: Colors.red),
                                  onPressed: () =>
                                      _deleteUser(user['id'], user['username']),
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: "logout",
        onPressed: _logout,
        backgroundColor: Colors.red,
        child: const Icon(Icons.logout, color: Colors.white),
      ),
    );
  }

  // Fetch user list
  Future<List<Map<String, dynamic>>> _fetchUsers() async {
    try {
      final currentUser = _auth.currentUser;
      final querySnapshot = await _firestore.collection('users').get();
      return querySnapshot.docs
          .where((doc) =>
              doc['email'] != currentUser?.email) // Exclude logged-in user
          .map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      throw Exception("Failed to fetch users: $e");
    }
  }
}

// Chart data model
class ActivityData {
  final DateTime date;
  final int count;

  ActivityData(this.date, this.count);
}
