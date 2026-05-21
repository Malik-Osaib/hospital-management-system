// FILE: lib/screens/admin_dashboard.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:hospital_management_system/models/doctor_model.dart';
import 'package:hospital_management_system/screens/add_doctor_screen.dart';
import 'package:hospital_management_system/screens/profile_screen.dart';
import 'package:hospital_management_system/services/database_service.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  int _selectedIndex = 0;
  final DatabaseService _dbService = DatabaseService();

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ProfileScreen()),
              );
            },
          ),
        ],
      ),
      body: _selectedIndex == 0 ? const AdminHomeTab() : const AdminUsersTab(),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: Icon(Icons.people), label: 'Doctors'),
          BottomNavigationBarItem(
              icon: Icon(Icons.supervised_user_circle), label: 'Users'),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.blue,
        onTap: _onItemTapped,
      ),
    );
  }
}

// ---------------------------------------------------------------------
// DOCTORS TAB – View, add, and edit hospital
// ---------------------------------------------------------------------
class AdminHomeTab extends StatelessWidget {
  const AdminHomeTab({super.key});

  @override
  Widget build(BuildContext context) {
    final DatabaseService _dbService = DatabaseService();
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddDoctorScreen()),
          );
        },
        child: const Icon(Icons.add),
      ),
      body: StreamBuilder<List<DoctorModel>>(
        stream: _dbService.getDoctors(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No doctors found. Tap + to add.'));
          }
          final doctors = snapshot.data!;
          return ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: doctors.length,
            itemBuilder: (context, index) {
              final doctor = doctors[index];
              return Card(
                elevation: 2,
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.blue.shade100,
                    child:
                        Text(doctor.name.isNotEmpty ? doctor.name[0] : 'D'),
                  ),
                  title: Text(doctor.name,
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(doctor.specialty),
                      Text(doctor.hospital,
                          style: TextStyle(color: Colors.grey[600])),
                      Row(
                        children: [
                          const Icon(Icons.star, size: 16, color: Colors.amber),
                          Text(
                              ' ${doctor.rating}  •  ${doctor.experience} Years'),
                        ],
                      ),
                    ],
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.edit, color: Colors.blue),
                    onPressed: () =>
                        _showEditHospitalDialog(context, doctor),
                  ),
                  isThreeLine: true,
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _showEditHospitalDialog(BuildContext context, DoctorModel doctor) {
    final TextEditingController hospitalController =
        TextEditingController(text: doctor.hospital);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Change Hospital'),
        content: TextField(
          controller: hospitalController,
          decoration: const InputDecoration(
            labelText: 'Hospital Name',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              final newHospital = hospitalController.text.trim();
              if (newHospital.isEmpty) return;
              await FirebaseFirestore.instance
                  .collection('doctors')
                  .doc(doctor.id)
                  .update({'hospital': newHospital});
              if (context.mounted) {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Hospital updated')),
                );
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------
// USERS TAB – same as before (delete patients/doctors)
// ---------------------------------------------------------------------
class AdminUsersTab extends StatelessWidget {
  const AdminUsersTab({super.key});

  @override
  Widget build(BuildContext context) {
    final DatabaseService _dbService = DatabaseService();
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _dbService.getAllUsers(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('No users found.'));
        }
        final users = snapshot.data!;
        return ListView.builder(
          padding: const EdgeInsets.all(8.0),
          itemCount: users.length,
          itemBuilder: (context, index) {
            final user = users[index];
            final uid = user['uid'];
            final role = user['role'] ?? '';
            final name = user['fullName'] ?? 'No Name';
            final email = user['email'] ?? 'No Email';
            final canDelete = (role == 'patient' || role == 'doctor');

            return Card(
              child: ListTile(
                leading: CircleAvatar(
                  child: Text(name.isNotEmpty ? name[0].toUpperCase() : 'U'),
                ),
                title: Text(name),
                subtitle: Text(email),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Chip(
                      label: Text(role,
                          style: const TextStyle(color: Colors.white)),
                      backgroundColor: _getRoleColor(role),
                    ),
                    if (canDelete)
                      IconButton(
                        icon: const Icon(Icons.delete_outline,
                            color: Colors.red),
                        onPressed: () =>
                            _confirmDeleteUser(context, uid, name, role),
                      ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Color _getRoleColor(String? role) {
    switch (role) {
      case 'admin':
        return Colors.red;
      case 'doctor':
        return Colors.blue;
      case 'patient':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  Future<void> _confirmDeleteUser(
      BuildContext context, String? uid, String name, String role) async {
    if (uid == null) return;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete User'),
        content: Text('Are you sure you want to delete $name ($role)?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    try {
      final firestore = FirebaseFirestore.instance;
      if (role == 'doctor') {
        await firestore.collection('doctors').doc(uid).delete();
        final appts = await firestore
            .collection('appointments')
            .where('doctorId', isEqualTo: uid)
            .get();
        for (var doc in appts.docs) {
          await doc.reference.delete();
        }
      }
      if (role == 'patient') {
        final appts = await firestore
            .collection('appointments')
            .where('patientId', isEqualTo: uid)
            .get();
        for (var doc in appts.docs) {
          await doc.reference.delete();
        }
      }
      await firestore.collection('users').doc(uid).delete();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$name deleted.'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }
}