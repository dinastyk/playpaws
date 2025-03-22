import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:faker/faker.dart';
import 'dart:math';

class TestDataService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final faker = Faker();

  // Create users method
  Future<void> createUsers() async {
    Random random = Random();

    for (int i = 1; i <= 100; i++) {
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

    for (int i = 1; i <= 100; i++) {
      String dogID = 'dogID$i';
      String dogName = faker.animal.name();
      List<String> dogPersonality = [faker.randomGenerator.boolean() ? "Energetic" : "Friendly"];
      String dogBreed = faker.randomGenerator.element(['Pomeranian', 'Bulldog', 'Golden Retriever']);
     
      // Create dog document
      await _db.collection('dogs').doc(dogID).set({
        'name': dogName,
        'personality': dogPersonality,
        'age': faker.randomGenerator.integer(10, min: 1),
        'availableForPlaydates': faker.randomGenerator.boolean(),
        'breed': dogBreed,
        'energyLevel': faker.randomGenerator.element(['High', 'Medium', 'Low']),
        'location': GeoPoint(
          faker.randomGenerator.integer(180) - 90.0, // Latitude between -90 and 90
          faker.randomGenerator.integer(360) - 180.0, // Longitude between -180 and 180
        ),
        'medicalConditions': faker.randomGenerator.boolean() ? "None" : "Allergic",
        'ownerId': _db.collection('users').doc('userID$i'),
        'size': faker.randomGenerator.element(['small', 'medium', 'large']),
        'weight': faker.randomGenerator.decimal(),
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

      DateTime playdateDate = DateTime.now().add(Duration(days: random.nextInt(100)));

      // Create playdate document
      await _db.collection('playpaws').doc('playdates').collection('playdates').doc(playdateID).set({
        'date': playdateDate,
        'location': playdateLocation,
      });
    }
  }

  // Create matches method
  Future<void> createMatches() async {
    Random random = Random();

    for (int i = 1; i <= 100; i++) {
      String matchID = 'matchID$i';
    
      // Randomly select two dogs
      String dog1ID = 'dogID${random.nextInt(100) + 1}';
      String dog2ID = 'dogID${random.nextInt(100) + 1}';
    
      // Create match document
      await _db.collection('playpaws').doc('playdate_matches').collection('matches').doc(matchID).set({
        'createdOn': FieldValue.serverTimestamp(),
        'dog1': dog1ID,
        'dog2': dog2ID,
        'playdateID': _db.collection('playpaws').doc('playdates').collection('playdates').doc('playdateID${random.nextInt(10) + 1}'),  // Link to a playdate
        'status': ['Matched'],
        'user1': 'userID${random.nextInt(100) + 1}',  // Random user for dog1
        'user2': 'userID${random.nextInt(100) + 1}',  // Random user for dog2
      });
    }
  }

  // Create messages method
  Future<void> createMessages() async {
    Random random = Random();

    for (int i = 1; i <= 100; i++) {
      String messageID = 'messageID$i';
    
      // Randomly select a chat
      String chatID = 'chatID${random.nextInt(100) + 1}';
    
      // Randomly choose a sender and message content
      String senderID = 'userID${random.nextInt(100) + 1}';
      String messageContent = faker.lorem.sentence();
    
      // Create message document
      await _db.collection('playpaws').doc('chats').collection('chats').doc(chatID).collection('messages').doc(messageID).set({
        'content': messageContent,
        'senderId': senderID,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
  }
}
