// FILE: lib/screens/chat_list_screen.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hospital_management_system/screens/chat_screen.dart';
import 'package:hospital_management_system/services/auth_service.dart';
import 'package:hospital_management_system/services/chat_service.dart';

class ChatListScreen extends StatelessWidget {
  const ChatListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final User? currentUser = FirebaseAuth.instance.currentUser;
    final ChatService _chatService = ChatService();
    final AuthService _authService = Provider.of<AuthService>(context);

    return FutureBuilder<String?>(
      future: _authService.getUserRole(currentUser!.uid),  
      builder: (context, roleSnapshot) {
        if (roleSnapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final role = roleSnapshot.data;

        // Determine who to show in the list
        String targetRole = (role == 'patient') ? 'doctor' : 'patient';

        return StreamBuilder<List<Map<String, dynamic>>>(
          stream: _chatService.getUsersByRole(targetRole),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const Center(child: Text('No users available to chat.'));
            }

            final users = snapshot.data!;
            return ListView.builder(
              itemCount: users.length,
              itemBuilder: (context, index) {
                final user = users[index];
                return ListTile(
                  title: Text(user['fullName'] ?? 'No Name'),
                  subtitle: Text(user['role'] ?? 'No Role'),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ChatScreen(
                          receiverId: user['uid'],
                          receiverName: user['fullName'] ?? 'User',
                        ),
                      ),
                    );
                  },
                );
              },
            );
          },
        );
      },
    );
  }
}