// FILE: lib/models/appointment_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class AppointmentModel {
  final String? id;
  final String patientId;
  final String doctorId;
  final String doctorName;
  final String patientName;
  final DateTime appointmentDate;
  final String status; // 'pending', 'confirmed', 'cancelled'
  final String? notes;

  AppointmentModel({
    this.id,
    required this.patientId,
    required this.doctorId,
    required this.doctorName,
    required this.patientName,
    required this.appointmentDate,
    this.status = 'pending',
    this.notes,
  });

  Map<String, dynamic> toMap() {
    return {
      'patientId': patientId,
      'doctorId': doctorId,
      'doctorName': doctorName,
      'patientName': patientName,
      'appointmentDate': appointmentDate,
      'status': status,
      'notes': notes,
    };
  }

  factory AppointmentModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AppointmentModel(
      id: doc.id,
      patientId: data['patientId'] ?? '',
      doctorId: data['doctorId'] ?? '',
      doctorName: data['doctorName'] ?? '',
      patientName: data['patientName'] ?? '',
      appointmentDate: (data['appointmentDate'] as Timestamp).toDate(),
      status: data['status'] ?? 'pending',
      notes: data['notes'],
    );
  }
}