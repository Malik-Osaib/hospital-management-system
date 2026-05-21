// FILE: lib/screens/patient_dashboard.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:hospital_management_system/models/medical_record_model.dart';
import 'package:hospital_management_system/screens/appointment_booking_screen.dart';
import 'package:hospital_management_system/screens/chat_list_screen.dart';
import 'package:hospital_management_system/screens/profile_screen.dart';
import 'package:hospital_management_system/services/database_service.dart';
import 'package:hospital_management_system/services/medical_record_service.dart';
import 'package:hospital_management_system/models/doctor_model.dart';
import 'package:hospital_management_system/models/appointment_model.dart';

class PatientDashboard extends StatefulWidget {
  const PatientDashboard({super.key});

  @override
  State<PatientDashboard> createState() => _PatientDashboardState();
}

class _PatientDashboardState extends State<PatientDashboard> {
  int _selectedIndex = 0;
  final DatabaseService _dbService = DatabaseService();
  final MedicalRecordService _recordService = MedicalRecordService();
  final User? user = FirebaseAuth.instance.currentUser;

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Patient Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const ProfileScreen())),
          ),
        ],
      ),
      body: _buildBody(),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.calendar_today), label: 'Appointments'),
          BottomNavigationBarItem(icon: Icon(Icons.medical_services), label: 'Records'),
          BottomNavigationBarItem(icon: Icon(Icons.chat), label: 'Chat'),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.blue,
        onTap: _onItemTapped,
      ),
    );
  }

  Widget _buildBody() {
    switch (_selectedIndex) {
      case 0:
        return const PatientHomeTab();
      case 1:
        return const AppointmentListTab();
      case 2:
        return PatientRecordsTab(recordService: _recordService, userId: user!.uid);
      case 3:
        return const ChatListScreen();
      default:
        return const PatientHomeTab();
    }
  }
}

class PatientHomeTab extends StatelessWidget {
  const PatientHomeTab({super.key});

  @override
  Widget build(BuildContext context) {
    final DatabaseService _dbService = DatabaseService();
    return StreamBuilder<List<DoctorModel>>(
      stream: _dbService.getDoctors(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('No doctors available.'));
        }
        final doctors = snapshot.data!;
        return ListView.builder(
          padding: const EdgeInsets.all(16.0),
          itemCount: doctors.length,
          itemBuilder: (context, index) {
            final doctor = doctors[index];
            return Card(
              child: ListTile(
                leading: const CircleAvatar(child: Icon(Icons.person)),
                title: Text(doctor.name),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(doctor.specialty),
                    Text(doctor.hospital, style: TextStyle(color: Colors.grey[600])),
                  ],
                ),
                trailing: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => AppointmentBookingScreen(doctor: doctor),
                      ),
                    );
                  },
                  child: const Text('Book Now'),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class AppointmentListTab extends StatelessWidget {
  const AppointmentListTab({super.key});

  @override
  Widget build(BuildContext context) {
    final DatabaseService _dbService = DatabaseService();
    final User? user = FirebaseAuth.instance.currentUser;
    return StreamBuilder<List<AppointmentModel>>(
      stream: _dbService.getAppointmentsForPatient(user!.uid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('No appointments yet.'));
        }
        final appointments = snapshot.data!;
        return ListView.builder(
          itemCount: appointments.length,
          itemBuilder: (context, index) {
            final appt = appointments[index];
            return Card(
              margin: const EdgeInsets.all(8.0),
              child: ListTile(
                title: Text('Dr. ${appt.doctorName}'),
                subtitle: Text(
                    'Date: ${DateFormat('yyyy-MM-dd – kk:mm').format(appt.appointmentDate)}'),
                trailing: Chip(
                  label: Text(appt.status),
                  backgroundColor: appt.status == 'confirmed'
                      ? Colors.green
                      : appt.status == 'cancelled'
                          ? Colors.red
                          : Colors.orange,
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class PatientRecordsTab extends StatelessWidget {
  final MedicalRecordService recordService;
  final String userId;
  const PatientRecordsTab({super.key, required this.recordService, required this.userId});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<MedicalRecordModel>>(
      stream: recordService.getRecordsForPatient(userId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(
            child: Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.red)),
          );
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('No medical records yet.'));
        }
        final records = snapshot.data!;
        return ListView.builder(
          padding: const EdgeInsets.all(8.0),
          itemCount: records.length,
          itemBuilder: (context, index) {
            final record = records[index];
            return Card(
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Dr. ${record.doctorName}',
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    Text(DateFormat('yyyy-MM-dd – kk:mm').format(record.date)),
                    const Divider(),
                    Text('Diagnosis: ${record.diagnosis}'),
                    Text('Treatment: ${record.treatment}'),
                    if (record.prescription.isNotEmpty)
                      Text('Prescription: ${record.prescription}'),
                    if (record.notes.isNotEmpty)
                      Text('Notes: ${record.notes}'),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}