// FILE: lib/models/medical_record_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class MedicalRecordModel {
  final String? id;
  final String patientId;
  final String patientName;
  final String doctorId;
  final String doctorName;
  final String? appointmentId;
  final DateTime date;
  final String diagnosis;
  final String treatment;
  final String prescription;   // NEW field
  final String notes;

  MedicalRecordModel({
    this.id,
    required this.patientId,
    required this.patientName,
    required this.doctorId,
    required this.doctorName,
    this.appointmentId,
    required this.date,
    required this.diagnosis,
    required this.treatment,
    this.prescription = '',    // default empty
    required this.notes,
  });

  Map<String, dynamic> toMap() {
    return {
      'patientId': patientId,
      'patientName': patientName,
      'doctorId': doctorId,
      'doctorName': doctorName,
      'appointmentId': appointmentId,
      'date': date,
      'diagnosis': diagnosis,
      'treatment': treatment,
      'prescription': prescription,   // include it
      'notes': notes,
    };
  }

  factory MedicalRecordModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return MedicalRecordModel(
      id: doc.id,
      patientId: data['patientId'] ?? '',
      patientName: data['patientName'] ?? '',
      doctorId: data['doctorId'] ?? '',
      doctorName: data['doctorName'] ?? '',
      appointmentId: data['appointmentId'],
      date: (data['date'] as Timestamp).toDate(),
      diagnosis: data['diagnosis'] ?? '',
      treatment: data['treatment'] ?? '',
      prescription: data['prescription'] ?? '',   // read it
      notes: data['notes'] ?? '',
    );
  }
}