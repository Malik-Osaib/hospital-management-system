// FILE: lib/services/database_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hospital_management_system/models/appointment_model.dart';
import 'package:hospital_management_system/models/doctor_model.dart';

class DatabaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // --- Doctor CRUD ---
  Future<void> addDoctor(DoctorModel doctor) async {
    await _firestore.collection('doctors').add(doctor.toMap());
  }

  Stream<List<DoctorModel>> getDoctors() {
    return _firestore.collection('doctors').snapshots().map((snapshot) =>
        snapshot.docs.map((doc) => DoctorModel.fromFirestore(doc)).toList());
  }

  Future<void> updateDoctor(String docId, DoctorModel doctor) async {
    await _firestore.collection('doctors').doc(docId).update(doctor.toMap());
  }

  Future<void> deleteDoctor(String docId) async {
    await _firestore.collection('doctors').doc(docId).delete();
  }

  // --- Appointment CRUD ---
  Future<void> bookAppointment(AppointmentModel appointment) async {
    await _firestore.collection('appointments').add(appointment.toMap());
  }

  Stream<List<AppointmentModel>> getAppointmentsForPatient(String patientId) {
    return _firestore
        .collection('appointments')
        .where('patientId', isEqualTo: patientId)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => AppointmentModel.fromFirestore(doc))
            .toList());
  }

  Stream<List<AppointmentModel>> getAppointmentsForDoctor(String doctorId) {
    return _firestore
        .collection('appointments')
        .where('doctorId', isEqualTo: doctorId)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => AppointmentModel.fromFirestore(doc))
            .toList());
  }

  Future<void> updateAppointmentStatus(String docId, String status) async {
    await _firestore.collection('appointments').doc(docId).update({'status': status});
  }

  // --- Admin: User Management ---
  Stream<List<Map<String, dynamic>>> getAllUsers() {
    return _firestore.collection('users').snapshots().map((snapshot) =>
        snapshot.docs.map((doc) => doc.data() as Map<String, dynamic>).toList());
  }
}