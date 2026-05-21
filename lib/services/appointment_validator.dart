// FILE: lib/services/appointment_validator.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:hospital_management_system/models/doctor_model.dart';

class AppointmentValidator {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Check if the selected time is within doctor's working hours and day
  Future<String?> validateAvailability(
    DoctorModel doctor,
    DateTime appointmentDateTime,
  ) async {
    // Check working day
    final weekday = appointmentDateTime.weekday; // 1=Monday, 7=Sunday
    if (!doctor.workingDays.contains(weekday)) {
      return 'Doctor is not available on this day.';
    }

    // Check working hours
    final timeOfDay = TimeOfDay(
      hour: appointmentDateTime.hour,
      minute: appointmentDateTime.minute,
    );
    
    final startParts = doctor.startTime.split(':');
    final endParts = doctor.endTime.split(':');
    
    final start = TimeOfDay(
      hour: int.parse(startParts[0]),
      minute: int.parse(startParts[1]),
    );
    final end = TimeOfDay(
      hour: int.parse(endParts[0]),
      minute: int.parse(endParts[1]),
    );

    if (_isBefore(timeOfDay, start) || _isAfter(timeOfDay, end)) {
      return 'Doctor is only available from ${doctor.startTime} to ${doctor.endTime}.';
    }

    // Check for overlapping appointments (within 30 min before or after)
    try {
      final conflict = await _hasConflict(doctor.id!, appointmentDateTime);
      if (conflict) {
        return 'This time slot conflicts with an existing appointment. Please choose another time.';
      }
    } on FirebaseException catch (e) {
      if (e.code == 'failed-precondition') {
        // Missing index – provide instructions
        return 'Setup required: Please create the Firestore index by clicking the link in the console.';
      }
      return 'Error checking availability: ${e.message}';
    }

    return null; // All good
  }

  bool _isBefore(TimeOfDay a, TimeOfDay b) {
    if (a.hour < b.hour) return true;
    if (a.hour == b.hour && a.minute < b.minute) return true;
    return false;
  }

  bool _isAfter(TimeOfDay a, TimeOfDay b) {
    if (a.hour > b.hour) return true;
    if (a.hour == b.hour && a.minute > b.minute) return true;
    return false;
  }

  Future<bool> _hasConflict(String doctorId, DateTime dateTime) async {
    final startWindow = dateTime.subtract(const Duration(minutes: 30));
    final endWindow = dateTime.add(const Duration(minutes: 30));

    final query = await _firestore
        .collection('appointments')
        .where('doctorId', isEqualTo: doctorId)
        .where('appointmentDate', isGreaterThanOrEqualTo: startWindow)
        .where('appointmentDate', isLessThanOrEqualTo: endWindow)
        .get();

    return query.docs.isNotEmpty;
  }
}