// FILE: lib/screens/wrapper.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hospital_management_system/screens/admin_dashboard.dart';
import 'package:hospital_management_system/screens/doctor_dashboard.dart';
import 'package:hospital_management_system/screens/patient_dashboard.dart';
import 'package:hospital_management_system/screens/auth_screen.dart';
import 'package:hospital_management_system/services/auth_service.dart';

class Wrapper extends StatelessWidget {
  const Wrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    return StreamBuilder<User?>(
      stream: authService.user.map((userModel) => FirebaseAuth.instance.currentUser),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        } else if (snapshot.hasData) {
          // User is logged in, determine role and show correct dashboard
          return FutureBuilder<String?>(
            future: authService.getUserRole(snapshot.data!.uid),
            builder: (context, roleSnapshot) {
              if (roleSnapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                );
              }
              final role = roleSnapshot.data;
              if (role == 'patient') {
                return const PatientDashboard();
              } else if (role == 'doctor') {
                return const DoctorDashboard();
              } else if (role == 'admin') {
                return const AdminDashboard();
              } else {
                return const AuthScreen(); // Fallback if role is invalid
              }
            },
          );
        } else {
          // User is not logged in
          return const AuthScreen();
        }
      },
    );
  }
}