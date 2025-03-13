import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options.dart';

// Function to generate 30 test users
Future<void> addTestUsers() async {
  // Initialize Firebase
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  
  FirebaseFirestore firestore = FirebaseFirestore.instance;

  for (int i = 1; i <= 30; i++) {
    String userId = "userId$i";

    await firestore.collection("users").doc(userId).set({
      "name": "User $i",
      "email": "user$i@example.com",
      "dogs": ["dogId$i", "dogId${i + 1}"], // Assign two test dogs
    });

    print("Added User $i");
  }
}

Future<void> main() async {
  await addTestUsers();
  print(" Successfully added 30 test users to Firestore!");
}
