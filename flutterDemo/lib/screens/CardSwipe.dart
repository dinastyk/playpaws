import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';
final dog_id = "dogId1";
Future<List<QueryDocumentSnapshot>> getDogs() async {
  final FirebaseFirestore db = FirebaseFirestore.instance;
  
  final dogData = db.collection("dogs");
  final matchData = db.collection("matches");

  // Step 1: Get the list of matches for the current dog (dog1)
  QuerySnapshot matchSnapshot = await matchData
      .where("dog1", isEqualTo: dog_id)
      .get(); 

  Set<String> matchedDogIDs = {};
  for (var doc in matchSnapshot.docs) {
    String matchedDogId = doc["dog2"];
    matchedDogIDs.add(matchedDogId);
  }
  QuerySnapshot matchedSnapshot = await matchData
      .where("dog2", isEqualTo: dog_id)
      .where("status", isEqualTo: "matched")
      .get(); 
  for (var doc in matchedSnapshot.docs) {
    String matchedDogId = doc["dog1"];
    matchedDogIDs.add(matchedDogId);
  }
  // Step 2: Query dogs collection and filter out matched dogs
  QuerySnapshot dogSnapshot = await dogData.get();

  List<QueryDocumentSnapshot> filteredDogs = [];
  for (var dogDoc in dogSnapshot.docs) {
    String dogID = dogDoc.id;
    if (!matchedDogIDs.contains(dogID) && dogID != dog_id) {
      filteredDogs.add(dogDoc);
    }
  }

  return filteredDogs;
}

class Example extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<List<QueryDocumentSnapshot>>(
        future: getDogs(), // Call getDogs() here
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text('No dogs to display.'));
          }

          List<Container> cards = snapshot.data!.map((dogDoc) {
            return Container(
              padding: EdgeInsets.all(8), 
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.network(
                    dogDoc["dogPictureURL"],
                    width: 100,
                    height: 100,
                    fit: BoxFit.cover,
                  ),
                  SizedBox(height: 8),
                  Text(
                    dogDoc["name"],
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 4),
                  Text(
                    dogDoc["breed"],
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                ],
              ),
              color: Colors.blue[50],
              margin: EdgeInsets.symmetric(vertical: 8),
            );
          }).toList();

          return Flexible(
            child: CardSwiper(
              cardsCount: cards.length,
              cardBuilder: (context, index, percentThresholdX, percentThresholdY) {
                return GestureDetector(
                  onPanUpdate: (details) {
                    if (details.localPosition.dx > percentThresholdX) {
                      // Swiping right
                      print("Swiped Right");
                      matchDog(snapshot.data![index]);
                    } else if (details.localPosition.dx < -percentThresholdX) {
                      // Swiping left
                      print("Swiped Left");
                      rejectDog(snapshot.data![index]);
                    }
                  },
                  onTap: () {
                    print("Tapped on card");
                  },
                  child: cards[index],
                );
              },
            ),
          );
        },
      ),
    );
  }
}

Future<void> matchDog(QueryDocumentSnapshot dogDoc) async {
  final FirebaseFirestore db = FirebaseFirestore.instance;
  final matchData = db.collection('matches');

  // Query for matches where the matched dog is dog1 and dog 2 is current_dog and status is "pending"
  QuerySnapshot matchSnapshot = await matchData
      .where("dog1", isEqualTo: dogDoc.id)
      .where("dog2", isEqualTo: dog_id)
      .where("status", isEqualTo: "pending")
      .get();
  if (matchSnapshot.docs.isEmpty) {
    print("No pending matches found for this dog. Creating a new match.");

    // Create a new match document if no pending matches exist
    await matchData.add({
      "dog1": "dogId1", // Replace with the actual dog ID for dog1
      "dog2": dogDoc.id, // The dogId of the current dog
      "status": "pending", // The initial status of the match
      // Add any other fields you need, like timestamps, user IDs, etc.
      "createdAt": FieldValue.serverTimestamp(),
    });}
else{
  // If there are any matches, update the status to "matched"
  for (var doc in matchSnapshot.docs) {
    String matchId = doc.id;
    await matchData.doc(matchId).update({
      "status": "matched",
    });
  }
}
}

Future<void> rejectDog(QueryDocumentSnapshot dogDoc) async {
    final FirebaseFirestore db = FirebaseFirestore.instance;
    final matchData = db.collection('matches');
      await matchData.add({
      "dog1": "dogId1", // Replace with the actual dog ID for dog1
      "dog2": dogDoc.id, // The dogId of the current dog
      "status": "pending", // The initial status of the match
      // Add any other fields you need, like timestamps, user IDs, etc.
      "createdAt": FieldValue.serverTimestamp(),
    });
}


/*
import 'package:flutter/material.dart';
import "dog_cards.dart";
class CardSwipe extends StatefulWidget {
  @override
  _CardSwipeState createState() => _CardSwipeState();
}

class _CardSwipeState extends State<CardSwipe> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Container(
          height: 300,
          width: 200,
          child: Stack(
            children: [
              //card stack
              DogCard(color: Colors.deepPurple),
              DogCard(color: Colors.green),
              DogCard(color: Colors.blue),
            ]
          )
        )
      )
    );
  }
}
*/