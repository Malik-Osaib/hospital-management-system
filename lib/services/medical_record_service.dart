// FILE: lib/services/medical_record_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hospital_management_system/models/medical_record_model.dart';

class MedicalRecordService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> addRecord(MedicalRecordModel record) async {
    await _firestore.collection('medical_records').add(record.toMap());
  }

  Stream<List<MedicalRecordModel>> getRecordsForPatient(String patientId) {
    return _firestore
        .collection('medical_records')
        .where('patientId', isEqualTo: patientId)
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => MedicalRecordModel.fromFirestore(doc)).toList());
  }
}