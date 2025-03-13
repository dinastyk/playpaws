// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:flutter/widgets.dart';

// class FirestoreService {
//   final FirebaseFirestore _db = FirebaseFirestore.instance;

//   /// Add a pet to Firestore
//   Future<void> addPet(String ownerId, Map<String, dynamic> petData) async {
//     try {
//       await _db.collection('users').doc(ownerId).collection('pets').add(petData);
//      debugPrint("Firestore data added!");
//     } catch (e) {
//       debugPrint("❌ Error adding pet: $e");
//     }
//   }

//   /// Get pets for a specific user
//   Stream<List<Map<String, dynamic>>> getPets(String ownerId) {
//     return _db.collection('users').doc(ownerId).collection('pets').snapshots().map(
//           (snapshot) => snapshot.docs.map((doc) => doc.data()).toList(),
//         );
//   }
// }
