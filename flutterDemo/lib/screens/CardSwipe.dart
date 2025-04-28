import 'package:flutter/material.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';


Future<DocumentReference?> getDogID() async {
  final FirebaseFirestore database = FirebaseFirestore.instance;
  final userData = database.collection("users");
  final User? user = FirebaseAuth.instance.currentUser;

  if (user == null) return null;

  QuerySnapshot userSnapshot =
      await userData.where("uid", isEqualTo: user.uid).get();

  if (userSnapshot.docs.isNotEmpty) {
    var doc = userSnapshot.docs.first;
    var data = doc.data() as Map<String, dynamic>;
    return data.containsKey("dog") ? data["dog"] as DocumentReference : null;
  }

  return null;
}
  

Future<String> getBreed(DocumentReference docRef) async {
  try {
    DocumentSnapshot docSnapshot = await docRef.get();
    if (docSnapshot.exists) {
      return docSnapshot.get('breed');
    }
  } catch (e) {
    print('Error fetching document: $e');
  }
  return "";
}

Future<List<QueryDocumentSnapshot>> sortDogs(
    Future<List<QueryDocumentSnapshot>> filteredDogsFuture,
    DocumentReference dogRef) async {
  final FirebaseFirestore db = FirebaseFirestore.instance;

  final currentBreed = await getBreed(dogRef);
  if (currentBreed == "") {
    return filteredDogsFuture;
  }

  final scoresDoc =
      await db.collection("dog_breeds").doc(currentBreed).get();
  Map<String, dynamic> scoresMap = scoresDoc.get("compatibility_scores");

  final filteredDogs = await filteredDogsFuture;

  final pairs = filteredDogs.map((dog) {
    final otherBreed = dog.get('breed');
    final score = (scoresMap[otherBreed] ?? 0).toDouble();
    return MapEntry(dog, score);
  }).toList();

  pairs.sort((a, b) => b.value.compareTo(a.value));

  return pairs.map((e) => e.key).toList();
}

Future<List<QueryDocumentSnapshot>> getDogs() async {
  final FirebaseFirestore db = FirebaseFirestore.instance;
  final dogData = db.collection("dogs");
  final matchData = db.collection("matches");
  DocumentReference? dogRef = await getDogID();
  if (dogRef == null) {
    return []; // return empty list if user has no dog
  }

  Set<DocumentReference> interactedDogs = {};

  // get matches where currentDog is dog1 // means dog1 either already swiped right or left on dog
  QuerySnapshot matchSnapshot1 = await matchData
      .where("dog1", isEqualTo: dogRef)
      .get();

  for (var doc in matchSnapshot1.docs) {
    DocumentReference matchedDogRef = doc["dog2"] as DocumentReference;
    interactedDogs.add(matchedDogRef); // exlcude all dogs dog1 swiped on
  }

  // get matches where current dog is dog2 and status is accepted/ means current dog is already matched to that dog
  QuerySnapshot matchSnapshot2 = await matchData
      .where("dog2", isEqualTo: dogRef)
      .where("status", isEqualTo: "Accepted") 
      .get();

  for (var doc in matchSnapshot2.docs) {
    DocumentReference matchedDogRef = doc["dog1"] as DocumentReference;
    interactedDogs.add(matchedDogRef); // add accepted matches to interacted with dogs set
  }

  //get all dogs in firestore and remove interacted with dogs plus dog itself
  QuerySnapshot dogSnapshot = await dogData.limit(50).get();
  List<QueryDocumentSnapshot> filteredDogs = [];

  for (var dogDoc in dogSnapshot.docs) {
    if (!interactedDogs.contains(dogDoc.reference) && dogDoc.reference != dogRef) {
      filteredDogs.add(dogDoc);
    }
  }

return sortDogs(Future.value(filteredDogs), dogRef); // pass to sortDogs function to sort based on dog breed compatibility
}
class CardSwipe extends StatefulWidget {
  final List<QueryDocumentSnapshot> dogs;

  const CardSwipe({Key? key, required this.dogs}) : super(key: key);

  @override
  _CardSwipeState createState() => _CardSwipeState();
}
 class _CardSwipeState extends State<CardSwipe> with TickerProviderStateMixin {
  final CardSwiperController _swiperController = CardSwiperController();
  int _currentIndex = 0;  // track current index of the card being shown

  void onSwipeAction(int previousIndex, CardSwiperDirection direction) async {
    if (previousIndex < 0 || previousIndex >= widget.dogs.length) return;

    // debug: print details of the dog being swiped
    QueryDocumentSnapshot dogDoc = widget.dogs[previousIndex];
    var dogData = dogDoc.data() as Map<String, dynamic>;
    print('Swiping on dog: ${dogData['name']}');
    print('Breed: ${dogData['breed']}');
    print('Liked: ${direction == CardSwiperDirection.right}');
    
    // perform the action (match or reject)
    bool isLiked = direction == CardSwiperDirection.right;
    if (isLiked) {
      await matchDog(dogDoc);
    } else {
      await rejectDog(dogDoc);
    }

    // adjust the current index to next card in list // had problem when i was removing based on index was removing next index so changed it to this
    setState(() {
      if (_currentIndex < widget.dogs.length - 1) {
        _currentIndex++;
      }
    });

    // debug- log the current index after swipe
    print('New current index after swipe: $_currentIndex');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("PlayPaws Match")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: widget.dogs.isEmpty
            ? Center(child: CircularProgressIndicator())
            : CardSwiper(
                controller: _swiperController,
                cardsCount: widget.dogs.length,
                onSwipe: (previousIndex, currentIndex, direction) {
                  if (previousIndex != null) {
                    // debug: log swipe action
                    print('Swiped card at index: $previousIndex, direction: $direction');
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      onSwipeAction(previousIndex, direction);
                    });
                  }
                  return true;
                },
                cardBuilder: (context, index, _, __) {
                  // check if the current index is still within the list
                  return index >= _currentIndex
                      ? DogCard(dogDoc: widget.dogs[index])
                      : Container(); // hide cards that are not in view
                },
                numberOfCardsDisplayed: 2, // fewer cards to prevent overflow in UI
                backCardOffset: Offset(0, 10), // adjust for card positioning
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
      child: Container(
        height: double.infinity, // Card takes max height it can
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.network(
                  dogData["dogPictureURL"] ?? //either gets dog url from db or random one i found
                      "https://www.ohio.edu/sites/default/files/styles/max_650x650/public/2025-03/Image.jpeg?itok=hc0EF56Z",
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              dogData["name"] ?? "No name",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Text(
              dogData["breed"] ?? "Unknown breed",
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}

Future<void> matchDog(QueryDocumentSnapshot dogDoc) async {

  final FirebaseFirestore db = FirebaseFirestore.instance;
  final matchData = db.collection('matches');
  DocumentReference dogRef = dogDoc.reference;
    DocumentReference? currentDogRef = await getDogID();
  if (currentDogRef == null) {
    return; // return empty list if user has no dog
  }
  // DocumentReference currentDogRef = db.collection('dogs').doc(dog_id);
  print('Matched:${dogRef}, ${currentDogRef}'); //debug print dog and current dog
  QuerySnapshot matchSnapshot = await matchData //get match data where dog 2 is current dog and pending
      .where("dog1", isEqualTo: dogRef)
      .where("dog2", isEqualTo: currentDogRef)
      .where("status", isEqualTo: "Pending")
      .get();

  if (matchSnapshot.docs.isEmpty) 
  { //if is empty, this didnt't exist create new match doc with dog1 is current dog, dog2 is matched dog
    await matchData.add({
      "createdOn": FieldValue.serverTimestamp(),
      "dog1": currentDogRef,
      "dog2": dogRef,
      "status": "Pending",
    });
  } 
  else 
  {
    for (var doc in matchSnapshot.docs) 
    {
      await matchData.doc(doc.id).update({"status": "Accepted"});  //if does exist change pending to accepted

      var dog1Snapshot = await currentDogRef.get();
      var dog2Snapshot = await dogRef.get();
      String user1 = dog1Snapshot.get('owner');
      String user2 = dog2Snapshot.get('owner');
      List<String> ids = [user1, user2];
      ids.sort();
      String chatID = ids.join("-");
      DocumentReference chatDoc = FirebaseFirestore.instance.collection('chats').doc(chatID);
      DocumentSnapshot chatSnapshot = await chatDoc.get();

      if (!chatSnapshot.exists) 
      {
        await chatDoc.set({
        "users": ids,
        "dog1": currentDogRef,
        "dog2": dogRef,
        "createdOn": FieldValue.serverTimestamp(),
        });
      }

       final userData = FirebaseFirestore.instance.collection("users");
       await userData.doc(user1).update({"matchedUsers": FieldValue.arrayUnion([user2])});
       await userData.doc(user2).update({"matchedUsers": FieldValue.arrayUnion([user1])});
    }
  }
}


Future<void> rejectDog(QueryDocumentSnapshot dogDoc) async {
  final FirebaseFirestore db = FirebaseFirestore.instance;
  final matchData = db.collection('matches');
  DocumentReference dogRef = dogDoc.reference;
  // DocumentReference currentDogRef = db.collection('dogs').doc(dog_id);
      DocumentReference? currentDogRef = await getDogID();
  if (currentDogRef == null) {
    return; // return empty list if user has no dog
  }
  print('Rejected:${dogRef}, ${currentDogRef}'); //create match doc with dog1 is current dog, dog2 is rejected dog, status is rejected
  await matchData.add({
    "createdOn": FieldValue.serverTimestamp(),
    "dog1": currentDogRef,
    "dog2": dogRef,
    "status": "Rejected",
  });
}