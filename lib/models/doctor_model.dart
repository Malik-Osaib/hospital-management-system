// FILE: lib/models/doctor_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class DoctorModel {
  final String? id;
  final String name;
  final String specialty;
  final double rating;
  final int experience;
  final String? imageUrl;
  final String hospital;

  // Working hours
  final String startTime;
  final String endTime;
  final List<int> workingDays;

  DoctorModel({
    this.id,
    required this.name,
    required this.specialty,
    required this.rating,
    required this.experience,
    this.imageUrl,
    this.hospital = "General Hospital",      // default
    this.startTime = "09:00",
    this.endTime = "17:00",
    this.workingDays = const [1, 2, 3, 4, 5],
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'specialty': specialty,
      'rating': rating,
      'experience': experience,
      'imageUrl': imageUrl,
      'hospital': hospital,
      'startTime': startTime,
      'endTime': endTime,
      'workingDays': workingDays,
    };
  }

  factory DoctorModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return DoctorModel(
      id: doc.id,
      name: data['name'] ?? '',
      specialty: data['specialty'] ?? '',
      rating: (data['rating'] ?? 0.0).toDouble(),
      experience: data['experience'] ?? 0,
      imageUrl: data['imageUrl'],
      hospital: data['hospital'] ?? "General Hospital",
      startTime: data['startTime'] ?? "09:00",
      endTime: data['endTime'] ?? "17:00",
      workingDays: List<int>.from(data['workingDays'] ?? [1, 2, 3, 4, 5]),
    );
  }
}