import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math';

class TestDataService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final Random _random = Random();

  // Helper function to generate random names
  String generateRandomName() {
    List<String> names = ['Luna', 'Max', 'Bella', 'Charlie', 'Lucy', 'Rocky', 'Milo', 'Daisy', 'Cooper', 'Buddy'];
    return names[_random.nextInt(names.length)];
  }

  // Create 30 Users
  Future<void> createUsers() async {
    for (int i = 1; i <= 30; i++) {
      String userID = 'userID$i';
      String userName = generateRandomName();
      String userEmail = 'user$userID@example.com';
      
      await _db.collection('users').doc(userID).set({
        'name': userName,
        'email': userEmail,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
  }

  // Create 30 Dogs for the Users
  Future<void> createDogs() async {
    for (int i = 1; i <= 30; i++) {
      String dogID = 'dog$i';
      String name = generateRandomName();
      String breed = ['Pomeranian', 'Golden Retriever', 'Bulldog', 'Beagle', 'Poodle', 'Labrador', 'Chihuahua', 'Yorkie', 'Shih Tzu', 'Dachshund'][_random.nextInt(10)];
      String size = ['Small', 'Medium', 'Large'][_random.nextInt(3)];
      String temperament = ['Happy', 'Friendly', 'Energetic', 'Calm', 'Playful'][_random.nextInt(5)];
      String ownerID = 'userID${_random.nextInt(30) + 1}'; // Randomly assigning owners
      
      // Random geo location
      GeoPoint location = GeoPoint(43.0 + _random.nextDouble(), 74.0 + _random.nextDouble());
      
      // Add dog to Firestore
      await _db.collection('dogs').doc(dogID).set({
        'name': name,
        'breed': breed,
        'size': size,
        'personality': [temperament],
        'ownerID': ownerID,
        'availableForPlaydates': true,
        'location': location,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'age': _random.nextInt(12), // Age between 0 and 11 years
        'energyLevel': ['Low', 'Medium', 'High'][_random.nextInt(3)],
        'medicalConditions': 'None',
        'weight': _random.nextDouble() * 10 + 5, // Weight between 5 and 15 kg
      });
    }
  }

 // Create Playdates
Future<void> createPlaydates() async {
  for (int i = 1; i <= 30; i++) {
    String playdateID = 'playdate$i';
    String dogID1 = 'dog${_random.nextInt(30) + 1}';
    String dogID2 = 'dog${_random.nextInt(30) + 1}';

    // Ensuring that dog1 and dog2 are not the same
    while (dogID1 == dogID2) {
      dogID2 = 'dog${_random.nextInt(30) + 1}';
    }

    // Scheduling the playdate
    DateTime scheduledDate = DateTime.now().add(Duration(days: _random.nextInt(30) + 1)); // Playdate scheduled in the next 30 days
    
    await _db.collection('playdates').doc(playdateID).set({
      'dog1ID': dogID1,
      'dog2ID': dogID2,
      'scheduledDate': Timestamp.fromDate(scheduledDate),  // Scheduled date
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}


  // Create Matches (Similar to Playdates but with confirmed interactions)
  Future<void> createMatches() async {
    for (int i = 1; i <= 30; i++) {
      String matchID = 'match$i';
      String dogID1 = 'dog${_random.nextInt(30) + 1}';
      String dogID2 = 'dog${_random.nextInt(30) + 1}';

      // Ensuring that dog1 and dog2 are not the same
      while (dogID1 == dogID2) {
        dogID2 = 'dog${_random.nextInt(30) + 1}';
      }

      await _db.collection('matches').doc(matchID).set({
        'dog1ID': dogID1,
        'dog2ID': dogID2,
        'matchDate': Timestamp.fromDate(DateTime.now().add(Duration(days: _random.nextInt(30)))),
        'status': 'Matched', // Status of the match
      });
    }
  }

  // Call all the methods to create users, dogs, playdates, and matches
  Future<void> generateTestData() async {
    await createUsers();
    await createDogs();
    await createPlaydates();
    await createMatches();
  }
}
