import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:faker/faker.dart';
import 'dart:math';

class TestDataService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final faker = Faker();

  // Create users method
  Future<void> createUsers() async {
    Random random = Random();

    for (int i = 1; i <= 30; i++) {
      String userID = 'userID$i';
      String userName = faker.person.name();
      String userEmail = 'user$userID@example.com';
      GeoPoint userLocation = GeoPoint(
  faker.randomGenerator.integer(180) - 90.0, // Latitude between -90 and 90
  faker.randomGenerator.integer(360) - 180.0, // Longitude between -180 and 180
);
      String userPhone = faker.phoneNumber.us();

      // Create user document
      await _db.collection('users').doc(userID).set({
        'email': userEmail,
        'location': userLocation,
        'name': userName,
        'phone': userPhone,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }
  }

  // Create dogs method
  Future<void> createDogs() async {
    Random random = Random();

    for (int i = 1; i <= 30; i++) {
      String dogID = 'dogID$i';
      String dogName = faker.animal.name();
      List<String> dogPersonality = [faker.randomGenerator.boolean() ? "Energetic" : "Friendly"];
      String dogBreed = faker.randomGenerator.element(['Pomeranian', 'Bulldog', 'Golden Retriever']);
      String dogSize = faker.randomGenerator.element(['small', 'medium', 'large']);
      double dogWeight = faker.randomGenerator.decimal();
      GeoPoint dogLocation = GeoPoint(
  faker.randomGenerator.integer(180) - 90.0, // Latitude between -90 and 90
  faker.randomGenerator.integer(360) - 180.0, // Longitude between -180 and 180
);
      String dogMedicalCondition = faker.randomGenerator.boolean() ? "None" : "Allergic";
      bool dogAvailableForPlaydates = faker.randomGenerator.boolean();

      // Create dog document
      await _db.collection('dogs').doc(dogID).set({
        'name': dogName,
        'personality': dogPersonality,
        'age': faker.randomGenerator.integer(10, min: 1),
        'availableForPlaydates': dogAvailableForPlaydates,
        'breed': dogBreed,
        'energyLevel': faker.randomGenerator.element(['High', 'Medium', 'Low']),
        'location': dogLocation,
        'medicalConditions': dogMedicalCondition,
        'ownerId': _db.collection('users').doc('userID$i'),
        'size': dogSize,
        'weight': dogWeight,
      });
    }
  }

  // Create playdates method
  Future<void> createPlaydates() async {
    Random random = Random();

    for (int i = 1; i <= 10; i++) {
      String playdateID = 'playdateID$i';
      GeoPoint playdateLocation = GeoPoint(
  faker.randomGenerator.integer(180) - 90.0, // Latitude between -90 and 90
  faker.randomGenerator.integer(360) - 180.0, // Longitude between -180 and 180
);

      DateTime playdateDate = DateTime.now().add(Duration(days: random.nextInt(30)));

      // Create playdate document
      await _db.collection('playpaws').doc('playdates').collection('playdates').doc(playdateID).set({
        'date': playdateDate,
        'location': playdateLocation,
        'dogIDs': [
          _db.collection('dogs').doc('dogID${random.nextInt(30) + 1}'),
          _db.collection('dogs').doc('dogID${random.nextInt(30) + 1}'),
        ],
        'confirmedDogOwners': [
          _db.collection('users').doc('userID${random.nextInt(30) + 1}'),
          _db.collection('users').doc('userID${random.nextInt(30) + 1}')
        ],
        'status': ['Pending'],
      });
    }
  }

  // Create matches method
  Future<void> createMatches() async {
    Random random = Random();

    for (int i = 1; i <= 10; i++) {
      String matchID = 'matchID$i';
      String dog1ID = 'dogID${random.nextInt(30) + 1}';
      String dog2ID = 'dogID${random.nextInt(30) + 1}';
      String playdateID = 'playdateID${random.nextInt(10) + 1}';

      // Create match document
      await _db.collection('playpaws').doc('playdate_matches').collection('matches').doc(matchID).set({
        'createdOn': FieldValue.serverTimestamp(),
        'dog1': dog1ID,
        'dog2': dog2ID,
        'playdateID': _db.collection('playpaws').doc('playdates').collection('playdates').doc(playdateID),
        'status': ['Matched'],
        'user1': _db.collection('users').doc('userID${random.nextInt(30) + 1}'),
        'user2': _db.collection('users').doc('userID${random.nextInt(30) + 1}'),
      });
    }
  }
}

