import 'package:flutter/material.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

final dog_id = "dogId1";

Future<List<QueryDocumentSnapshot>> getDogs() async {
  final FirebaseFirestore db = FirebaseFirestore.instance;
  final dogData = db.collection("dogs");
  final matchData = db.collection("matches");
  DocumentReference dogRef = db.collection("dogs").doc(dog_id);

  Set<DocumentReference> interactedDogs = {};

  // Step 1: Get matches where current dog is `dog1` (already swiped)
  QuerySnapshot matchSnapshot1 = await matchData
      .where("dog1", isEqualTo: dogRef)
      .get();

  for (var doc in matchSnapshot1.docs) {
    DocumentReference matchedDogRef = doc["dog2"] as DocumentReference;
    interactedDogs.add(matchedDogRef); // Exclude all dogs dog1 swiped on
  }

  // Step 2: Get matches where current dog is `dog2` AND status = "Accepted"
  QuerySnapshot matchSnapshot2 = await matchData
      .where("dog2", isEqualTo: dogRef)
      .where("status", isEqualTo: "Accepted") // Only remove accepted matches
      .get();

  for (var doc in matchSnapshot2.docs) {
    DocumentReference matchedDogRef = doc["dog1"] as DocumentReference;
    interactedDogs.add(matchedDogRef); // Remove accepted matches
  }

  // Step 3: Get all dogs and remove interacted ones
  QuerySnapshot dogSnapshot = await dogData.get();
  List<QueryDocumentSnapshot> filteredDogs = [];

  for (var dogDoc in dogSnapshot.docs) {
    if (!interactedDogs.contains(dogDoc.reference) && dogDoc.reference != dogRef) {
      filteredDogs.add(dogDoc);
    }
  }

  return filteredDogs;
}

class CardSwipe extends StatefulWidget {
  @override
  _CardSwipeState createState() => _CardSwipeState();
}

class _CardSwipeState extends State<CardSwipe> with TickerProviderStateMixin {
  List<QueryDocumentSnapshot> dogs = [];
  final CardSwiperController _swiperController = CardSwiperController();

  @override
  void initState() {
    super.initState();
    fetchDogs(); // Fetch initial dogs list
  }

  Future<void> fetchDogs() async {
    List<QueryDocumentSnapshot> fetchedDogs = await getDogs();
    setState(() {
      dogs = fetchedDogs;
    });
  }

  // Handle swipe action: like or reject dog
  void onSwipeAction(int index, CardSwiperDirection direction) async {
    if (index >= dogs.length) return;

    QueryDocumentSnapshot dogDoc = dogs[index];
    bool isLiked = direction == CardSwiperDirection.right; // Like if swiped right

    if (isLiked) {
      await matchDog(dogDoc); // Match the dog if liked
    } else {
      await rejectDog(dogDoc); // Reject the dog if disliked
    }

    setState(() {
      dogs.removeAt(index); // Remove the swiped dog
    });

    // Fetch more dogs if the list is empty
    if (dogs.isEmpty) {
      fetchDogs();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("PlayPaws Match")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: dogs.isEmpty
            ? Center(child: CircularProgressIndicator()) // Show loading indicator if no dogs
            : CardSwiper(
              controller: _swiperController,
              cardsCount: dogs.length,
              onSwipe: (previousIndex, currentIndex, direction) {
                if (currentIndex != null) {
                  onSwipeAction(currentIndex, direction); 
                  }
                  return true;
                  },
                onUndo: (previousIndex, currentIndex, direction) {
                  debugPrint('Card $currentIndex was undone from ${direction.name}');
                  return true;
                },
                cardBuilder: (context, index, _, __) {
                  return DogCard(dogDoc: dogs[index]);
                },
                numberOfCardsDisplayed: 3, // Display 3 cards at a time
                backCardOffset: Offset(40, 40),
                padding: EdgeInsets.all(24.0),
              ),
      ),
    );
  }
}


class DogCard extends StatelessWidget {
  final QueryDocumentSnapshot dogDoc;
  const DogCard({Key? key, required this.dogDoc}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    var dogData = dogDoc.data() as Map<String, dynamic>;

    return Card(
      elevation: 5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Image.network(
              dogData["dogPictureURL"] ??
                  "https://www.ohio.edu/sites/default/files/styles/max_650x650/public/2025-03/Image.jpeg?itok=hc0EF56Z",
              width: 300,
              height: 300,
              fit: BoxFit.cover,
            ),
          ),
          SizedBox(height: 12),
          Text(
            dogData["name"] ?? "No name",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 6),
          Text(
            dogData["breed"] ?? "Unknown breed",
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}

Future<void> matchDog(QueryDocumentSnapshot dogDoc) async {
  final FirebaseFirestore db = FirebaseFirestore.instance;
  final matchData = db.collection('matches');
  DocumentReference dogRef = dogDoc.reference;
  DocumentReference currentDogRef = db.collection('dogs').doc(dog_id);
  /*
  QuerySnapshot matchSnapshot = await matchData
      .where("dog1", isEqualTo: dogRef)
      .where("dog2", isEqualTo: currentDogRef)
      .where("status", isEqualTo: "Pending")
      .get();

  if (matchSnapshot.docs.isEmpty) {
    await matchData.add({
      "createdOn": FieldValue.serverTimestamp(),
      "dog1": dogRef,
      "dog2": currentDogRef,
      "status": "Pending",
    });
  } else {
    for (var doc in matchSnapshot.docs) {
      await matchData.doc(doc.id).update({"status": "Accepted"});
    }
  }
  */

  print('Matched: $dogRef, $currentDogRef');
}

Future<void> rejectDog(QueryDocumentSnapshot dogDoc) async {
  final FirebaseFirestore db = FirebaseFirestore.instance;
  final matchData = db.collection('matches');
  DocumentReference dogRef = dogDoc.reference;
  DocumentReference currentDogRef = db.collection('dogs').doc(dog_id);

/*
  await matchData.add({
    "createdOn": FieldValue.serverTimestamp(),
    "dog1": currentDogRef,
    "dog2": dogRef,
    "status": "Rejected",
  });
  */
  print('Rejected: $dogRef, $currentDogRef');
}
