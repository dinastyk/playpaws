import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'messages_page.dart';

Future<String?> getUserName(String receiverID) async {
  final FirebaseFirestore database = FirebaseFirestore.instance;
  final userData = database.collection("users");

  QuerySnapshot userSnapshot =
      await userData.where("uid", isEqualTo: receiverID).get();

  if (userSnapshot.docs.isNotEmpty) {
    var doc = userSnapshot.docs.first;
    var data = doc.data() as Map<String, dynamic>;
    return data["name"];
  }

  return null;
}

class ChatsPage extends StatelessWidget {
  const ChatsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('Please log in to view chats')),
      );
    }

    final userRef = FirebaseFirestore.instance.doc("users/${user.uid}");

    return Scaffold(
      appBar: AppBar(title: const Text("Your Chats")),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection("chats")
            .where("participants", arrayContains: userRef)
            .orderBy("createdAt", descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("No Chats Yet"));
          }

          final chats = snapshot.data!.docs;

          return ListView.builder(
            itemCount: chats.length,
            itemBuilder: (context, index) {
              final chat = chats[index];
              final participants =
                  List<DocumentReference>.from(chat['participants']);
              final otherParticipants =
                  participants.where((ref) => ref.id != user.uid).toList();

              if (otherParticipants.isEmpty) {
                return const SizedBox.shrink();
              }

              final otherUserRef = otherParticipants.first;
              final receiverId = otherUserRef.id;

              return FutureBuilder<String?>(
                future: getUserName(receiverId),
                builder: (context, nameSnapshot) {
                  final displayName = nameSnapshot.data ?? receiverId;

                  return Column(
                    children: [
                      ListTile(
                        leading: const CircleAvatar(
                          child: Icon(Icons.person),
                        ),
                        title: Text("Chat with $displayName"),
                        subtitle: Text(chat['lastMessage'] ?? 'Tap to chat'),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  MessagesPage(receiverID: receiverId),
                            ),
                          );
                        },
                      ),
                      const Divider(height: 1),
                    ],
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}

              //final chatID = chat.id;
/*
              return ListTile
              (
                title: Text("Chat with: $otherUserID"),
                subtitle: Text("Tap to chat"),
                onTap: ()
                {
                  Navigator.push
                  (
                    context, MaterialPageRoute(builder: (_) => MessagesPage(receiverID: otherUserID),),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
*/
