import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:faker/faker.dart';
import 'dart:math';

class TestDataService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final faker = Faker();

  // Generate fake user data and upload to Firestore
  Future<void> createFakeUsers() async {
    Random random = Random();

    for (int i = 1; i <= 100; i++) {
      String userID = 'userID$i';
      String userName = faker.person.name();
      String userEmail = 'user$userID@example.com';
      String userPhone = faker.phoneNumber.us();
      String profilePicUrl = 'https://picsum.photos/200/200?random=$i'; // Random profile pic URL

      // Create user document in Firestore
      await _db.collection('users').doc(userID).set({
        'name': userName,
        'email': userEmail,
        'phone': userPhone,
        'profilePictureURL': profilePicUrl,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }
  }

  // Generate fake dog data and upload to Firestore
  Future<void> createFakeDogs() async {
    Random random = Random();

    for (int i = 1; i <= 100; i++) {
      String dogID = 'dogID$i';
      String dogName = faker.animal.name();
      List<String> dogPersonality = [faker.randomGenerator.boolean() ? "Energetic" : "Friendly"];
      String dogBreed = faker.randomGenerator.element(['Pomeranian', 'Bulldog', 'Golden Retriever']);
      String dogPictureUrl = 'https://picsum.photos/200/200?random=$i'; // Random dog pic URL

      // Create dog document in Firestore
      await _db.collection('dogs').doc(dogID).set({
        'name': dogName,
        'breed': dogBreed,
        'personality': dogPersonality,
        'dogPictureURL': dogPictureUrl,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }
  }

  // Create fake playdates and upload to Firestore
  Future<void> createFakePlaydates() async {
    Random random = Random();

    for (int i = 1; i <= 100; i++) {
      String playdateID = 'playdateID$i';
      GeoPoint playdateLocation = GeoPoint(
        faker.randomGenerator.integer(180) - 90.0, // Latitude between -90 and 90
        faker.randomGenerator.integer(360) - 180.0, // Longitude between -180 and 180
      );

      DateTime playdateDate = DateTime.now().add(Duration(days: random.nextInt(100)));

      // Create playdate document in Firestore
      await _db.collection('playdates').doc(playdateID).set({
        'date': playdateDate,
        'location': playdateLocation,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }
  }

  // Create fake matches and upload to Firestore
  Future<void> createFakeMatches() async {
    Random random = Random();

    for (int i = 1; i <= 100; i++) {
      String matchID = 'matchID$i';
      String dog1ID = 'dogID${random.nextInt(100) + 1}';
      String dog2ID = 'dogID${random.nextInt(100) + 1}';
      String user1ID = 'userID${random.nextInt(100) + 1}';
      String user2ID = 'userID${random.nextInt(100) + 1}';
      
      // Create match document in Firestore
      await _db.collection('matches').doc(matchID).set({
        'dog1': dog1ID,
        'dog2': dog2ID,
        'user1': user1ID,
        'user2': user2ID,
        'status': 'matched',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }
  }

  // Create fake chat data and upload to Firestore
  Future<void> createFakeChats() async {
    Random random = Random();

    for (int i = 1; i <= 100; i++) {
      String chatID = 'chatID$i';
      String user1ID = 'userID${random.nextInt(100) + 1}';
      String user2ID = 'userID${random.nextInt(100) + 1}';
      
      // Create chat document in Firestore
      await _db.collection('chats').doc(chatID).set({
        'user1': user1ID,
        'user2': user2ID,
        'lastMessageTimestamp': FieldValue.serverTimestamp(),
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Add some fake messages to the chat
      for (int j = 1; j <= 10; j++) {
        String messageID = 'messageID${random.nextInt(1000) + 1}';
        String messageSender = random.nextBool() ? user1ID : user2ID;
        String messageContent = faker.lorem.sentence();

        await _db.collection('chats').doc(chatID).collection('messages').doc(messageID).set({
          'senderId': messageSender,
          'content': messageContent,
          'timestamp': FieldValue.serverTimestamp(),
        });
      }
    }
  }

  // Call all methods to create fake data
  Future<void> generateTestData() async {
    await createFakeUsers();
    await createFakeDogs();
    await createFakePlaydates();
    await createFakeMatches();
    await createFakeChats();
    print('Test data created successfully!');
  }
}
