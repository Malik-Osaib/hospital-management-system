// FILE: lib/screens/appointment_booking_screen.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:hospital_management_system/models/appointment_model.dart';
import 'package:hospital_management_system/models/doctor_model.dart';
import 'package:hospital_management_system/services/appointment_validator.dart';
import 'package:hospital_management_system/services/database_service.dart';
import 'package:intl/intl.dart';

class AppointmentBookingScreen extends StatefulWidget {
  final DoctorModel doctor;
  const AppointmentBookingScreen({super.key, required this.doctor});

  @override
  State<AppointmentBookingScreen> createState() =>
      _AppointmentBookingScreenState();
}

class _AppointmentBookingScreenState extends State<AppointmentBookingScreen> {
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  final DatabaseService _dbService = DatabaseService();
  final User? user = FirebaseAuth.instance.currentUser;
  final AppointmentValidator _validator = AppointmentValidator();
  bool _isLoading = false;

  Future<void> _bookAppointment() async {
    if (_selectedDate == null || _selectedTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select both date and time.')),
      );
      return;
    }

    final appointmentDateTime = DateTime(
      _selectedDate!.year,
      _selectedDate!.month,
      _selectedDate!.day,
      _selectedTime!.hour,
      _selectedTime!.minute,
    );

    if (appointmentDateTime.isBefore(DateTime.now())) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cannot book appointments in the past.')),
      );
      return;
    }

    setState(() => _isLoading = true);

    final error =
        await _validator.validateAvailability(widget.doctor, appointmentDateTime);
    if (error != null) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(error)));
      }
      return;
    }

    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user!.uid)
        .get();
    final patientName = userDoc.data()?['fullName'] ?? 'Patient';

    final appointment = AppointmentModel(
      patientId: user!.uid,
      doctorId: widget.doctor.id!,
      doctorName: widget.doctor.name,
      patientName: patientName,
      appointmentDate: appointmentDateTime,
    );

    try {
      await _dbService.bookAppointment(appointment);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Appointment booked successfully!')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error booking: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _getDaysString(List<int> days) {
    const map = {
      1: 'Mon', 2: 'Tue', 3: 'Wed', 4: 'Thu',
      5: 'Fri', 6: 'Sat', 7: 'Sun'
    };
    return days.map((d) => map[d]).join(', ');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Book with Dr. ${widget.doctor.name}')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.doctor.name,
                        style: const TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold)),
                    Text(widget.doctor.specialty),
                    Text(widget.doctor.hospital,
                        style: TextStyle(color: Colors.grey[600])),
                    Text('Experience: ${widget.doctor.experience} years'),
                    Text(
                        'Hours: ${widget.doctor.startTime} - ${widget.doctor.endTime}'),
                    Text('Days: ${_getDaysString(widget.doctor.workingDays)}'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            ListTile(
              title: Text(
                _selectedDate == null
                    ? 'Select Date'
                    : 'Date: ${DateFormat('yyyy-MM-dd').format(_selectedDate!)}',
                style: TextStyle(
                    color: _selectedDate == null ? Colors.grey : Colors.black),
              ),
              trailing: const Icon(Icons.calendar_today),
              onTap: () async {
                final DateTime? picked = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now().add(const Duration(days: 1)),
                  firstDate: DateTime.now(),
                  lastDate: DateTime(2101),
                );
                if (picked != null) setState(() => _selectedDate = picked);
              },
            ),
            ListTile(
              title: Text(
                _selectedTime == null
                    ? 'Select Time'
                    : 'Time: ${_selectedTime!.format(context)}',
                style: TextStyle(
                    color: _selectedTime == null ? Colors.grey : Colors.black),
              ),
              trailing: const Icon(Icons.access_time),
              onTap: () async {
                final TimeOfDay? picked = await showTimePicker(
                  context: context,
                  initialTime: TimeOfDay.now(),
                );
                if (picked != null) setState(() => _selectedTime = picked);
              },
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: _isLoading ? null : _bookAppointment,
              style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16)),
              child: _isLoading
                  ? const CircularProgressIndicator()
                  : const Text('Confirm Booking'),
            ),
          ],
        ),
      ),
    );
  }
}