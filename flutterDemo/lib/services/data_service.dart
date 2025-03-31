import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:faker/faker.dart';
import 'dart:math';

class TestDataService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final Faker faker = Faker();
  final Random random = Random();

  // Generate a list of dog personalities
  List<String> getDogPersonalities() {
    return ['Energetic', 'Friendly', 'Calm', 'Playful'];
  }

  // Create a single dog entry
  Future<void> createDog(String dogId) async {
    List<String> dogPersonalities = getDogPersonalities();
    double dogWeight = random.nextDouble() * (50 - 5) + 5; // Dog weight between 5-50 lb
    int dogAge = random.nextInt(15) + 1; // Dog age between 1-15 years
    String dogPictureUrl = 'https://picsum.photos/200/200?random=${random.nextInt(1000)}'; // Random dog pic URL
    
    await _db.collection('dogs').doc(dogId).set({
      'name': faker.animal.name(),
      'breed': faker.lorem.word(),
      'weight': dogWeight,
      'age': dogAge,
      'energyLevel': faker.randomGenerator.element(['Low', 'Medium', 'High']),
      'personality': dogPersonalities, // Dog's personality traits
      'dogPictureURL': dogPictureUrl,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // Create a single user entry with a reference to a dog
  Future<void> createUser(String userId, String dogId) async {
    String userPictureUrl = 'https://picsum.photos/200/200?random=${random.nextInt(1000)}'; // Random user pic URL
    List<String> dogPersonalities = getDogPersonalities();
    
    // Select 2 random personalities for the user preferences
    List<String> selectedPersonalities = [
      faker.randomGenerator.element(dogPersonalities),
      faker.randomGenerator.element(dogPersonalities)
    ];

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
        'energyLevel': faker.randomGenerator.element(['Low', 'Medium', 'High']),
        'preferredPersonalities': selectedPersonalities, // Preferred personalities (array of 2 random traits)
      },
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // Generate 50 users and their corresponding dogs
  Future<void> createMultipleUsersAndDogs() async {
    // Create 50 users and 50 dogs
    for (int i = 0; i < 50; i++) {
      String dogId = 'dogId${i + 1}';
      await createDog(dogId);  // Create a dog and add it to Firestore
      
      String userId = 'userId${i + 1}';
      await createUser(userId, dogId);  // Create a user and add it to Firestore with a corresponding dog
    }
  }
  // Create playdates for random users and dogs
  Future<void> createPlaydate(List<String> userIds, List<String> dogIds) async {
    String playdateId = 'playdateId${random.nextInt(1000)}';
    List<String> selectedUsers = [userIds[random.nextInt(userIds.length)], userIds[random.nextInt(userIds.length)]];
    List<String> selectedDogs = [dogIds[random.nextInt(dogIds.length)], dogIds[random.nextInt(dogIds.length)]];
    
    await _db.collection('playdates').doc(playdateId).set({
      'confirmedDogOwners': selectedUsers.map((id) => _db.doc('/users/$id')).toList(),
      'dogIDs': selectedDogs.map((id) => _db.doc('/dogs/$id')).toList(), // Using references to dogs here
      'location': GeoPoint(
        random.nextDouble() * 180 - 90,  // Latitude
        random.nextDouble() * 360 - 180 // Longitude
      ),
      'date': Timestamp.now(),
      'status': faker.randomGenerator.element(['Pending', 'Confirmed', 'Completed']),
    });
  }

  // Generate a match between two dogs
  Future<void> createMatch(List<String> dogIds) async {
    String matchId = 'matchId${random.nextInt(1000)}';
    String dog1 = dogIds[random.nextInt(dogIds.length)];
    String dog2 = dogIds[random.nextInt(dogIds.length)];
    
    await _db.collection('matches').doc(matchId).set({
      'dog1': _db.doc('/dogs/$dog1'),
      'dog2': _db.doc('/dogs/$dog2'),
      'createdOn': FieldValue.serverTimestamp(),
      'status': faker.randomGenerator.element(['Pending', 'Accepted', 'Declined']),
    });
  }

  // Create fake data for users, dogs, playdates, etc.
  Future<void> createFakeData() async {
    List<String> dogIds = [];
    List<String> userIds = [];
    
    // Create dogs and users
    for (int i = 1; i <= 50; i++) {
      String dogId = 'dogId$i';
      await createDog(dogId);
      dogIds.add(dogId);

      String userId = 'userId$i';
      await createUser(userId, dogId);
      userIds.add(userId);
    }

    // Create playdates
    for (int i = 1; i <= 20; i++) {
      await createPlaydate(userIds, dogIds);
    }

    // Create matches
    for (int i = 1; i <= 30; i++) {
      await createMatch(dogIds);
    }
  }

 // Create a chat with random messages between users
  Future<void> createChat(List<String> userIds) async {
    String chatId = 'chatId${random.nextInt(1000)}';

    // Select two random users for the chat
    String user1 = userIds[random.nextInt(userIds.length)];
    String user2 = userIds[random.nextInt(userIds.length)];

    // Create the chat document
    await _db.collection('chats').doc(chatId).set({
      'user1': _db.doc('/users/$user1'),
      'user2': _db.doc('/users/$user2'),
      'createdAt': FieldValue.serverTimestamp(),
    });

    // Create 5 messages for the chat
    for (int i = 0; i < 5; i++) {
      String messageId = 'messageId${random.nextInt(1000)}';
      String sender = random.nextBool() ? user1 : user2; // Randomly choose sender

      await _db.collection('chats').doc(chatId).collection('messages').doc(messageId).set({
        'sender': _db.doc('/users/$sender'),
        'message': faker.lorem.sentence(),
        'sentAt': Timestamp.now(),
        'status': 'Sent',
      });
    }
  }

  // Create a list of test data with users and chats
  Future<void> createTestData(List<String> userIds) async {
    // Create chats and populate with messages
    for (int i = 0; i < 3; i++) {
      await createChat(userIds);
    }
  }
}