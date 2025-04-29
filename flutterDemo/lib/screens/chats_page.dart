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

    final userRef = FirebaseFirestore.instance.doc("users/${user.uid}");

    return Scaffold
    (
      appBar: AppBar(title: const Text("Your Chats")),
      body: StreamBuilder<QuerySnapshot>
      (
        stream: FirebaseFirestore.instance
        .collection("chats")
        .where("participants", arrayContains: userRef)
        .orderBy("createdAt", descending: true)
        .snapshots(),
        builder: (context, snapshot)
        {
          if (snapshot.hasError)
          {
            return Center(child: Text("Error: ${snapshot.error} "));
            //print("Error: ${snapshot.error}");
            //print("${snapshot.error}");
            
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
              final participants = List<DocumentReference>.from(chat['participants']);
              final otherParticipants = participants.where((ref) => ref.id != user.uid).toList();
              if (otherParticipants.isEmpty) 
              {
                return const SizedBox.shrink();
              }
              final otherUserRef = otherParticipants.first;
              
              return FutureBuilder
              (
                future: otherUserRef.get(),
                builder: (context, snapshot)
                {
                  //final displayName = snapshot.hasData ? (snapshot.data!.data() as Map<String, dynamic>)['username'] ?? otherUserRef.id : otherUserRef.id;

                  String displayName = otherUserRef.id;
                  if (snapshot.hasData && snapshot.data!.exists)
                  {
                    final data = snapshot.data!.data() as Map<String, dynamic>?;
                    if (data != null && data['username'] != null) 
                    {
                      displayName = data['username'];
                    }
                  }


                  return ListTile
                  (
                    title: Text("Chat with $displayName"),
                    subtitle: Text(chat['lastMessage'] ?? 'Tap to chat'),
                    onTap: ()
                    {
                      Navigator.push(context, 
                      MaterialPageRoute(builder: (_) => MessagesPage(receiverID: otherUserRef.id),),);
                    }
                  );
                }
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
