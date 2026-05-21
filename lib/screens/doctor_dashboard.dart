// FILE: lib/screens/doctor_dashboard.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:hospital_management_system/models/medical_record_model.dart';
import 'package:hospital_management_system/screens/chat_list_screen.dart';
import 'package:hospital_management_system/screens/profile_screen.dart';
import 'package:hospital_management_system/services/database_service.dart';
import 'package:hospital_management_system/services/medical_record_service.dart';
import 'package:hospital_management_system/models/appointment_model.dart';

class DoctorDashboard extends StatefulWidget {
  const DoctorDashboard({super.key});

  @override
  State<DoctorDashboard> createState() => _DoctorDashboardState();
}

class _DoctorDashboardState extends State<DoctorDashboard> {
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
        title: const Text('Doctor Dashboard'),
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
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Dashboard'),
          BottomNavigationBarItem(icon: Icon(Icons.calendar_month), label: 'My Schedule'),
          BottomNavigationBarItem(icon: Icon(Icons.chat), label: 'Chat'),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.blue,
        onTap: _onItemTapped,
      ),
    );
  }

  Widget _buildBody() {
    if (_selectedIndex == 0) {
      return PendingAppointmentsTab(userId: user!.uid);
    } else if (_selectedIndex == 1) {
      return DoctorScheduleTab(userId: user!.uid, recordService: _recordService);
    } else {
      return const ChatListScreen();
    }
  }
}

// ------------------ PENDING TAB ------------------
class PendingAppointmentsTab extends StatelessWidget {
  final String userId;
  const PendingAppointmentsTab({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    final DatabaseService _dbService = DatabaseService();
    return StreamBuilder<List<AppointmentModel>>(
      stream: _dbService.getAppointmentsForDoctor(userId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('No pending appointments.'));
        }
        final now = DateTime.now();
        final pending = snapshot.data!
            .where((appt) => appt.status == 'pending' && appt.appointmentDate.isAfter(now))
            .toList();
        if (pending.isEmpty) {
          return const Center(child: Text('No pending appointments.'));
        }
        return ListView.builder(
          padding: const EdgeInsets.all(8.0),
          itemCount: pending.length,
          itemBuilder: (context, index) {
            final appt = pending[index];
            return Card(
              margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Patient: ${appt.patientName}',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    Text('Date: ${DateFormat('yyyy-MM-dd').format(appt.appointmentDate)}'),
                    Text('Time: ${DateFormat('hh:mm a').format(appt.appointmentDate)}'),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton.icon(
                          onPressed: () => _updateStatus(context, appt.id!, 'confirmed'),
                          icon: const Icon(Icons.check_circle, color: Colors.green),
                          label: const Text('Accept'),
                        ),
                        const SizedBox(width: 16),
                        TextButton.icon(
                          onPressed: () => _updateStatus(context, appt.id!, 'cancelled'),
                          icon: const Icon(Icons.cancel, color: Colors.red),
                          label: const Text('Reject'),
                        ),
                      ],
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

  Future<void> _updateStatus(BuildContext context, String appointmentId, String status) async {
    final dbService = DatabaseService();
    await dbService.updateAppointmentStatus(appointmentId, status);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Appointment $status')),
      );
    }
  }
}

// ------------------ SCHEDULE TAB ------------------
class DoctorScheduleTab extends StatelessWidget {
  final String userId;
  final MedicalRecordService recordService;
  const DoctorScheduleTab({super.key, required this.userId, required this.recordService});

  @override
  Widget build(BuildContext context) {
    final DatabaseService _dbService = DatabaseService();
    return StreamBuilder<List<AppointmentModel>>(
      stream: _dbService.getAppointmentsForDoctor(userId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('No appointments scheduled.'));
        }
        final appointments = snapshot.data!
          ..sort((a, b) => b.appointmentDate.compareTo(a.appointmentDate));
        return ListView.builder(
          padding: const EdgeInsets.all(8.0),
          itemCount: appointments.length,
          itemBuilder: (context, index) {
            final appt = appointments[index];
            final bool isConfirmed = appt.status == 'confirmed';
            return Card(
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(appt.patientName,
                            style: const TextStyle(fontWeight: FontWeight.bold)),
                        Chip(
                          label: Text(appt.status),
                          backgroundColor: appt.status == 'confirmed'
                              ? Colors.green
                              : appt.status == 'cancelled'
                                  ? Colors.red
                                  : Colors.orange,
                        ),
                      ],
                    ),
                    Text(DateFormat('yyyy-MM-dd – hh:mm a').format(appt.appointmentDate)),
                    if (isConfirmed) ...[
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton.icon(
                            onPressed: () => _showViewHistory(context, appt.patientId, recordService),
                            icon: const Icon(Icons.history, size: 18),
                            label: const Text('View History'),
                          ),
                          const SizedBox(width: 8),
                          TextButton.icon(
                            onPressed: () => _showAddPrescriptionDialog(
                              context,
                              patientId: appt.patientId,
                              patientName: appt.patientName,
                              doctorId: userId,
                              doctorName: appt.doctorName,
                              appointmentId: appt.id,
                              recordService: recordService,
                            ),
                            icon: const Icon(Icons.post_add, size: 18),
                            label: const Text('Add Prescription'),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showViewHistory(BuildContext context, String patientId, MedicalRecordService recordService) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Patient Medical History'),
        content: SizedBox(
          width: double.maxFinite,
          child: StreamBuilder<List<MedicalRecordModel>>(
            stream: recordService.getRecordsForPatient(patientId),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Text('Error: ${snapshot.error}',
                    style: const TextStyle(color: Colors.red));
              }
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const Text('No previous records.');
              }
              final records = snapshot.data!;
              return ListView.builder(
                shrinkWrap: true,
                itemCount: records.length,
                itemBuilder: (context, index) {
                  final rec = records[index];
                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Dr. ${rec.doctorName}',
                              style: const TextStyle(fontWeight: FontWeight.bold)),
                          Text(DateFormat('yyyy-MM-dd').format(rec.date)),
                          const SizedBox(height: 4),
                          Text('Diagnosis: ${rec.diagnosis}'),
                          Text('Treatment: ${rec.treatment}'),
                          if (rec.prescription.isNotEmpty)
                            Text('Prescription: ${rec.prescription}'),
                          if (rec.notes.isNotEmpty)
                            Text('Notes: ${rec.notes}'),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showAddPrescriptionDialog(BuildContext context,
      {required String patientId,
      required String patientName,
      required String doctorId,
      required String doctorName,
      required String? appointmentId,
      required MedicalRecordService recordService}) {
    final diagnosisController = TextEditingController();
    final treatmentController = TextEditingController();
    final prescriptionController = TextEditingController();   // NEW
    final notesController = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Add Prescription'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: diagnosisController,
                decoration: const InputDecoration(
                    labelText: 'Diagnosis', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: treatmentController,
                decoration: const InputDecoration(
                    labelText: 'Treatment', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: prescriptionController,
                decoration: const InputDecoration(
                    labelText: 'Prescription (Medicines/Dosage)',
                    border: OutlineInputBorder()),
                maxLines: 2,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: notesController,
                decoration: const InputDecoration(
                    labelText: 'Notes (optional)',
                    border: OutlineInputBorder()),
                maxLines: 2,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              if (diagnosisController.text.trim().isEmpty ||
                  treatmentController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Diagnosis and Treatment required')),
                );
                return;
              }
              final record = MedicalRecordModel(
                patientId: patientId,
                patientName: patientName,
                doctorId: doctorId,
                doctorName: doctorName,
                appointmentId: appointmentId,
                date: DateTime.now(),
                diagnosis: diagnosisController.text.trim(),
                treatment: treatmentController.text.trim(),
                prescription: prescriptionController.text.trim(),   // new field
                notes: notesController.text.trim(),
              );
              await recordService.addRecord(record);
              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Prescription added')),
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