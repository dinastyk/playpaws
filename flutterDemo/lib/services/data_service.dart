import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:faker/faker.dart';
import 'dart:math';

class TestDataService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final Faker faker = Faker();
  final Random random = Random();

  Future<void> createFakeData() async {
    List<String> dogIds = [];
    List<String> userIds = [];
    
    for (int i = 1; i <= 50; i++) {
      // Generate dog first
      String dogId = 'dogId$i';
      double dogWeight = random.nextDouble() * (50 - 5) + 5; // Dog weight between 5-50 kg
      int dogAge = random.nextInt(15) + 1; // Dog age between 1-15 years
      String dogPictureUrl = 'https://picsum.photos/200/200?random=${i + 50}'; // Random dog pic URL
      
      await _db.collection('dogs').doc(dogId).set({
        'name': faker.animal.name(),
        'breed': faker.lorem.word(),
        'weight': dogWeight,
        'age': dogAge,
        'energyLevel': faker.randomGenerator.element(['Low', 'Medium', 'High']),
        'dogPictureURL': dogPictureUrl,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      dogIds.add(dogId);
      
      // Generate user with reference to this dog
      String userId = 'userId$i';
      String userPictureUrl = 'https://picsum.photos/200/200?random=$i'; // Random user pic URL
      
      await _db.collection('users').doc(userId).set({
        'email': faker.internet.email(),
        'name': faker.person.name(),
        'location': GeoPoint(
          random.nextDouble() * 180 - 90,  // Latitude
          random.nextDouble() * 360 - 180 // Longitude
        ),
        'dog': _db.doc('/dogs/$dogId'),
        'profilePictureURL': userPictureUrl,
        'preferences': {
          'minWeight': random.nextDouble() * 20 + 5, // Min 5-25kg
          'maxWeight': random.nextDouble() * 30 + 20, // Max 20-50kg
          'minAge': random.nextInt(5) + 1, // Min 1-5 years
          'maxAge': random.nextInt(10) + 5, // Max 5-15 years
          'energyLevel': faker.randomGenerator.element(['Low', 'Medium', 'High'])
        },
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      userIds.add(userId);
    }

    // Generate playdates
    for (int i = 1; i <= 20; i++) {
      String playdateId = 'playdateId$i';
      List<String> selectedUsers = [userIds[random.nextInt(userIds.length)], userIds[random.nextInt(userIds.length)]];
      List<String> selectedDogs = [dogIds[random.nextInt(dogIds.length)], dogIds[random.nextInt(dogIds.length)]];
      
      await _db.collection('playpaws/playdates').doc(playdateId).set({
        'confirmedDogOwners': selectedUsers.map((id) => _db.doc('/users/$id')).toList(),
        'dogIDs': selectedDogs.map((id) => _db.doc('/dogs/$id')).toList(),
        'location': GeoPoint(
          random.nextDouble() * 180 - 90,  // Latitude
          random.nextDouble() * 360 - 180 // Longitude
        ),
        'date': Timestamp.now(),
        'status': faker.randomGenerator.element(['Pending', 'Confirmed', 'Completed']),
      });
    }

    // Generate matches
    for (int i = 1; i <= 30; i++) {
      String matchId = 'matchId$i';
      String dog1 = dogIds[random.nextInt(dogIds.length)];
      String dog2 = dogIds[random.nextInt(dogIds.length)];
      
      await _db.collection('playpaws/matches').doc(matchId).set({
        'dog1': _db.doc('/dogs/$dog1'),
        'dog2': _db.doc('/dogs/$dog2'),
        'createdOn': FieldValue.serverTimestamp(),
        'status': faker.randomGenerator.element(['Pending', 'Accepted', 'Declined']),
      });
    }

    // Generate messages
    for (int i = 1; i <= 50; i++) {
      String messageId = 'messageId$i';
      String sender = userIds[random.nextInt(userIds.length)];
      String receiver = userIds[random.nextInt(userIds.length)];
      
      await _db.collection('playpaws/messages').doc(messageId).set({
        'sender': _db.doc('/users/$sender'),
        'receiver': _db.doc('/users/$receiver'),
        'content': faker.lorem.sentence(),
        'timestamp': FieldValue.serverTimestamp(),
      });
    }
  }
}

  