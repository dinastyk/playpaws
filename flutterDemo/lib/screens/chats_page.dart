import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'messages_page.dart'; 

class ChatsPage extends StatelessWidget
{
  const ChatsPage ({super.key});
  @override
  Widget build(BuildContext content)
  {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null)
    {
      return const Scaffold
      (
        body: Center(child: Text('Please log in to view chats')),
      );
    }
    return Scaffold
    (
      appBar: AppBar(title: const Text("Your Chats")),
      body: StreamBuilder<QuerySnapshot>
      (
        stream: FirebaseFirestore.instance
        .collection("chats")
        .where("users", arrayContains: user.uid)
        .orderBy("createdOn", descending: true)
        .snapshots(),
        builder: (context, snapshot)
        {
          if (snapshot.hasError)
          {
            return const Center(child: Text("Error Loading Chats"));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty)
          {
            return const Center(child: Text("No Chats Yet"));
          }
          final chats = snapshot.data!.docs;
        
          return ListView.builder
          (
            itemCount: chats.length,
            itemBuilder: (context, index)
            {
              final chat = chats[index];
              final users = List<String>.from(chat['users']);
              final otherUserID = users.firstWhere((uid) => uid != user.uid);
              final chatID = chat.id;

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