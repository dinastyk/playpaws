import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

Future<void> sendEmbeddingRequest() async {
  final FirebaseFirestore database = FirebaseFirestore.instance;
  final userData = database.collection("users");
  final User? user = FirebaseAuth.instance.currentUser;
  // final uid = user?.uid;

  if (user == null) {
    print("No user logged in");
    return;
  }

  QuerySnapshot userSnapshot =
      await userData.where("uid", isEqualTo: user.uid).get();

  if (userSnapshot.docs.isNotEmpty) {
    var doc = userSnapshot.docs.first;
    var data = doc.data() as Map<String, dynamic>;
    final preferences = data['preferences'];
    final preferred_traits = preferences['preferredPersonalities'];

    if (preferred_traits != null && preferred_traits.isNotEmpty) {
      final sentence = (preferred_traits.toSet().join(" ")).trim();

      final response = await http.post(
        Uri.parse("https://ce9e-2601-84-8601-61c0-fcc4-ec5c-971c-e3ac.ngrok-free.app/generate-embedding"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "user_id": user.uid,
          "text": sentence,
          "type": "user",
        }),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        final embedding = responseData['embedding'];

        print("Embedding: $embedding");

        // final DocumentReference dogRef = data['dog'];
        DocumentReference userRef = doc.reference;

        try {
          await userRef.update({'userEmbedding': embedding});
          print("Updated dog document with userEmbedding");
        } catch (e) {
          print("Failed to update dog document: $e");
        }

      } else {
        print("Error from embedding API: ${response.statusCode}");
      }
    }
  }
}

Future<void> sendDogEmbeddingRequest() async {
  final FirebaseFirestore database = FirebaseFirestore.instance;
  final userData = database.collection("users");
  final User? user = FirebaseAuth.instance.currentUser;

  if (user == null) {
    print("No user logged in");
    return;
  }

  QuerySnapshot userSnapshot =
      await userData.where("uid", isEqualTo: user.uid).get();

  if (userSnapshot.docs.isNotEmpty) {
    var doc = userSnapshot.docs.first;
    var data = doc.data() as Map<String, dynamic>;
    final DocumentReference dogRef = data['dog'];

    try {
      // Fetch the dog document data
      DocumentSnapshot dogSnapshot = await dogRef.get();
      var dogData = dogSnapshot.data() as Map<String, dynamic>;
      final personality = dogData['personality'];

      if (personality != null && personality.isNotEmpty) {
        final sentence = (personality.toSet().join(" ")).trim();

        final response = await http.post(
          Uri.parse("https://ce9e-2601-84-8601-61c0-fcc4-ec5c-971c-e3ac.ngrok-free.app/generate-embedding"),
          headers: {"Content-Type": "application/json"},
          body: jsonEncode({
            "user_id": user.uid,
            "text": sentence,
            "type": "dog",
          }),
        );

        if (response.statusCode == 200) {
          final responseData = jsonDecode(response.body);
          final embedding = responseData['embedding'];

          print("Embedding: $embedding");

          try {
            await dogRef.update({'dogEmbedding': embedding});
            print("Updated dog document with dogEmbedding");
          } catch (e) {
            print("Failed to update dog document: $e");
          }

        } else {
          print("Error from dog embedding API: ${response.statusCode}");
        }
      }
    } catch (e) {
      print("Error fetching dog data: $e");
    }
  }
}



// final user = FirebaseAuth.instance.currentUser;
// final uid = user?.uid; // This is the UID you want to send!


// Future<String?> getText() async {
//   final FirebaseFirestore database = FirebaseFirestore.instance;
//   final userData = database.collection("users");
//   final user = FirebaseAuth.instance.currentUser;
//   final uid = user?.uid;

//   if (uid == null) {
//     print("No user logged in");
//     return "";
//   }

//   if (user == null) return "";

//   QuerySnapshot userSnapshot =
//       await userData.where("uid", isEqualTo: user.uid).get();

//   if (userSnapshot.docs.isNotEmpty) {
//     var doc = userSnapshot.docs.first;
//     var data = doc.data() as Map<String, dynamic>;
//     final preferences = data['preferences'];
//     final preferred_traits = preferences['preferred_traits'];

//     if (preferred_traits != null && preferred_traits.isNotEmpty) {
//       // Use a Set to remove duplicates and then join the traits into a sentence
//       final sentence = (preferred_traits.toSet().join(" ")).trim();
//       sendEmbeddingRequest(sentence);
//       return sentence;
      
//     }
//   }
//   return "";
// }

  
// Future<void> sendEmbeddingRequest(String text) async {
//   final user = FirebaseAuth.instance.currentUser;
//   final uid = user?.uid;

//   if (uid == null) {
//     print("No user logged in");
//     return;
//   }

//   final response = await http.post(
//     // Uri.parse("http://your-server-ip:8000/generate-embedding"),
//     Uri.parse("https://ce9e-2601-84-8601-61c0-fcc4-ec5c-971c-e3ac.ngrok-free.app/generate-embedding"),
//     headers: {"Content-Type": "application/json"},
//     body: jsonEncode({
//       "user_id": uid,
//       "text": text,
//       "type": "user", // or "dog"
//     }),
//   );

//   if (response.statusCode == 200) {
//     final data = jsonDecode(response.body);
//     print("Embedding: ${data['embedding']}");
//   } else {
//     print("Error: ${response.statusCode}");
//   }
// }
