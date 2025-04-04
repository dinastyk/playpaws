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

class Example extends StatefulWidget {
  @override
  _ExampleState createState() => _ExampleState();
}

class _ExampleState extends State<Example> with TickerProviderStateMixin {
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
  void onSwipe(int index, CardSwiperDirection direction) async {
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
                onSwipeDirectionChange: (previousDirection, currentDirection) {
                  int currentIndex = dogs.length - 1; // Get the index of the top card
                  onSwipe(currentIndex, currentDirection); // Call onSwipe with current index and direction
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
}

Future<void> rejectDog(QueryDocumentSnapshot dogDoc) async {
  final FirebaseFirestore db = FirebaseFirestore.instance;
  final matchData = db.collection('matches');
  DocumentReference dogRef = dogDoc.reference;
  DocumentReference currentDogRef = db.collection('dogs').doc(dog_id);

  await matchData.add({
    "createdOn": FieldValue.serverTimestamp(),
    "dog1": currentDogRef,
    "dog2": dogRef,
    "status": "Rejected",
  });
}


// Future<List<QueryDocumentSnapshot>> getDogs() async {
//   final FirebaseFirestore db = FirebaseFirestore.instance;
//   final dogData = db.collection("dogs");
//   final matchData = db.collection("matches");
//   DocumentReference dogRef = db.collection("dogs").doc(dog_id);

//   // Step 1: Get the list of matches for the current dog (dog1)
//   QuerySnapshot matchSnapshot = await matchData
//       .where("dog1", isEqualTo: dogRef)
//       .get();

//   Set<DocumentReference> matchedDogRefs = {};
//   for (var doc in matchSnapshot.docs) {
//     DocumentReference matchedDogRef = doc["dog2"] as DocumentReference;
//     matchedDogRefs.add(matchedDogRef);
//   }

//   QuerySnapshot matchedSnapshot = await matchData
//       .where("dog2", isEqualTo: dogRef)
//       .where("status", isEqualTo: "Accepted")
//       .get();

//   for (var doc in matchedSnapshot.docs) {
//     DocumentReference matchedDogRef = doc["dog1"] as DocumentReference;
//     matchedDogRefs.add(matchedDogRef);
//   }

//   // Step 2: Query dogs collection and filter out matched dogs
//   QuerySnapshot dogSnapshot = await dogData.get();

//   List<QueryDocumentSnapshot> filteredDogs = [];
//   for (var dogDoc in dogSnapshot.docs) {
//     if (!matchedDogRefs.contains(dogDoc.reference) && dogDoc.reference != dogRef) {
//       filteredDogs.add(dogDoc);
//     }
//   }

//   return filteredDogs;
// }

// class Example extends StatefulWidget {
//   @override
//   _ExampleState createState() => _ExampleState();
// }

// class _ExampleState extends State<Example> with TickerProviderStateMixin {
//   late List<QueryDocumentSnapshot> dogs;
//   int currentIndex = 0;
//   late TabController _tabController;

//   @override
//   void initState() {
//     super.initState();
//     _tabController = TabController(length: 2, vsync: this);

//     // Initial fetch of dogs
//     getDogs().then((fetchedDogs) {
//       setState(() {
//         dogs = fetchedDogs;
//       });
//     });

//     // Add listener to detect tab changes
//     _tabController.addListener(() {
//       if (_tabController.index == 0) {
//         reloadDogs();
//       }
//     });
//   }

//   Future<void> reloadDogs() async {
//     List<QueryDocumentSnapshot> freshDogs = await getDogs();
//     setState(() {
//       dogs = freshDogs;
//       currentIndex = 0; // Reset index to the first dog
//     });
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: Text("PlayPaws Match")),
//       body: dogs.isEmpty
//           ? Center(child: CircularProgressIndicator())
//           : Padding(
//               padding: const EdgeInsets.all(16.0),
//               child: Column(
//                 mainAxisAlignment: MainAxisAlignment.center,
//                 children: [
//                   if (currentIndex < dogs.length)
//                     DogCard(dogDoc: dogs[currentIndex])
//                   else
//                     Text("No more dogs to swipe!"),
//                   SizedBox(height: 20),
//                   Row(
//                     mainAxisAlignment: MainAxisAlignment.spaceAround,
//                     children: [
//                       ElevatedButton(
//                         onPressed: () {
//                           print("Disliked dog ${dogs[currentIndex]["name"]}");
//                           rejectDog(dogs[currentIndex]);
//                           setState(() {
//                             if (currentIndex < dogs.length - 1) {
//                               currentIndex++;
//                             }
//                           });
//                         },
//                         child: Text("Dislike"),
//                       ),
//                       ElevatedButton(
//                         onPressed: () {
//                           print("Liked dog ${dogs[currentIndex]["name"]}");
//                           matchDog(dogs[currentIndex]);
//                           setState(() {
//                             if (currentIndex < dogs.length - 1) {
//                               currentIndex++;
//                             }
//                           });
//                         },
//                         child: Text("Like"),
//                       ),
//                     ],
//                   ),
//                 ],
//               ),
//             ),
//     );
//   }
// }

// class DogCard extends StatelessWidget {
//   final QueryDocumentSnapshot dogDoc;
//   const DogCard({Key? key, required this.dogDoc}) : super(key: key);

//   @override
//   Widget build(BuildContext context) {
//     var dogData = dogDoc.data() as Map<String, dynamic>;

//     return Card(
//       elevation: 5,
//       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
//       child: Column(
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           ClipRRect(
//             borderRadius: BorderRadius.circular(16),
//             child: Image.network(
//               dogData["dogPictureURL"] ??
//                   "https://www.ohio.edu/sites/default/files/styles/max_650x650/public/2025-03/Image.jpeg?itok=hc0EF56Z",
//               width: 300,
//               height: 300,
//               fit: BoxFit.cover,
//             ),
//           ),
//           SizedBox(height: 12),
//           Text(
//             dogData["name"] ?? "No name",
//             style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
//           ),
//           SizedBox(height: 6),
//           Text(
//             dogData["breed"] ?? "Unknown breed",
//             style: TextStyle(fontSize: 16, color: Colors.grey),
//           ),
//         ],
//       ),
//     );
//   }
// }

// Future<void> matchDog(QueryDocumentSnapshot dogDoc) async {
//   final FirebaseFirestore db = FirebaseFirestore.instance;
//   final matchData = db.collection('matches');
//   DocumentReference dogRef = dogDoc.reference;

//   // Query for matches where the matched dog is dog1 and dog 2 is current_dog and status is "pending"
//   QuerySnapshot matchSnapshot = await matchData
//       .where("dog1", isEqualTo: dogRef)
//       .where("dog2", isEqualTo: db.collection('dogs').doc(dog_id))
//       .where("status", isEqualTo: "Pending")
//       .get();

//   if (matchSnapshot.docs.isEmpty) {
//     print("No pending matches found for this dog. Creating a new match.");

//     // Create a new match document if no pending matches exist
//     await matchData.add({
//       "createdOn": FieldValue.serverTimestamp(),
//       "dog1": dogRef,
//       "dog2": db.collection('dogs').doc(dog_id),
//       "status": "Pending", // pending match
//     });
//   } else {
//     // If not empty, update the status to "Accepted"
//     for (var doc in matchSnapshot.docs) {
//       String matchId = doc.id;
//       await matchData.doc(matchId).update({
//         "status": "Accepted",
//       });
//     }
//   }
// }

// Future<void> rejectDog(QueryDocumentSnapshot dogDoc) async {
//   final FirebaseFirestore db = FirebaseFirestore.instance;
//   final matchData = db.collection('matches');
//   DocumentReference dogRef = dogDoc.reference;

//   await matchData.add({
//     "createdOn": FieldValue.serverTimestamp(),
//     "dog1": db.collection('dogs').doc(dog_id),
//     "dog2": dogRef,
//     "status": "Rejected", // rejected match
//   });
// }

// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_card_swiper/flutter_card_swiper.dart';
// final dog_id = "dogId1";

// Future<List<QueryDocumentSnapshot>> getDogs() async {
//   final FirebaseFirestore db = FirebaseFirestore.instance;
  
//   final dogData = db.collection("dogs");
//   final matchData = db.collection("matches");
//   DocumentReference dogRef = db.collection("dogs").doc(dog_id);

//   // Step 1: Get the list of matches for the current dog (dog1)
//   QuerySnapshot matchSnapshot = await matchData
//       .where("dog1", isEqualTo: dogRef)
//       .get(); 

//   Set<DocumentReference> matchedDogRefs = {};
//   for (var doc in matchSnapshot.docs) {
//     DocumentReference matchedDogRef = doc["dog2"] as DocumentReference;
//     matchedDogRefs.add(matchedDogRef);
//   }

//   QuerySnapshot matchedSnapshot = await matchData
//       .where("dog2", isEqualTo: dogRef)
//       .where("status", isEqualTo: "Accepted")
//       .get(); 

//   for (var doc in matchedSnapshot.docs) {
//     DocumentReference matchedDogRef = doc["dog1"] as DocumentReference;
//     matchedDogRefs.add(matchedDogRef);
//   }

//   // Step 2: Query dogs collection and filter out matched dogs
//   QuerySnapshot dogSnapshot = await dogData.get();

//   List<QueryDocumentSnapshot> filteredDogs = [];
//   for (var dogDoc in dogSnapshot.docs) {
//     if (!matchedDogRefs.contains(dogDoc.reference) && dogDoc.reference != dogRef) {
//       filteredDogs.add(dogDoc);
//     }
//   }

//   return filteredDogs;
// }


// class Example extends StatelessWidget {
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: FutureBuilder<List<QueryDocumentSnapshot>>(
//         future: getDogs(), // Call getDogs() here
//         builder: (context, snapshot) {
//           if (snapshot.connectionState == ConnectionState.waiting) {
//             return Center(child: CircularProgressIndicator());
//           }

//           if (snapshot.hasError) {
//             return Center(child: Text('Error: ${snapshot.error}'));
//           }

//           if (!snapshot.hasData || snapshot.data!.isEmpty) {
//             return Center(child: Text('No dogs to display.'));
//           }

//           snapshot.data!.forEach((dogDoc) {
//             print(dogDoc.data()); // Print the document data to see all available fields
//           });

//           List<Container> cards = snapshot.data!.map((dogDoc) {
//             var dogData = dogDoc.data() as Map<String, dynamic>;  // Cast to Map

//             return Container(
//               padding: EdgeInsets.all(8),
//               child: Column(
//                 mainAxisAlignment: MainAxisAlignment.center,
//                 children: [
//                   Image.network(
//                     dogData["dogPictureURL"] ?? "https://www.ohio.edu/sites/default/files/styles/max_650x650/public/2025-03/Image.jpeg?itok=hc0EF56Z",  // Use a default image if the URL is missing or null
//                     width: 100,
//                     height: 100,
//                     fit: BoxFit.cover,
//                   ),
//                   SizedBox(height: 8),
//                   Text(
//                     dogData["name"] ?? "No name",  // Provide a fallback value if 'name' is missing
//                     style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
//                   ),
//                   SizedBox(height: 4),
//                   Text(
//                     dogData["breed"] ?? "Unknown breed",  // Provide a fallback value if 'breed' is missing
//                     style: TextStyle(fontSize: 14, color: Colors.grey),
//                   ),
//                 ],
//               ),
//               color: Colors.blue[50],
//               margin: EdgeInsets.symmetric(vertical: 8),
//             );
//           }).toList();

//           return Flexible(
//             child: CardSwiper(
//               cardsCount: cards.length,
//               cardBuilder: (context, index, percentThresholdX, percentThresholdY) {
//                 return GestureDetector(
//                   onPanUpdate: (details) {
//                     if (details.localPosition.dx > percentThresholdX) {
//                       // Swiping right
//                       print("Swiped Right");
//                       matchDog(snapshot.data![index]);
//                     } else if (details.localPosition.dx < -percentThresholdX) {
//                       // Swiping left
//                       print("Swiped Left");
//                       rejectDog(snapshot.data![index]);
//                     }
//                   },
//                   onTap: () {
//                     print("Tapped on card");
//                   },
//                   child: cards[index],
//                 );
//               },
//             ),
//           );
//         },
//       ),
//     );
//   }
// }


// Future<void> matchDog(QueryDocumentSnapshot dogDoc) async {
//   final FirebaseFirestore db = FirebaseFirestore.instance;
//   final matchData = db.collection('matches');
//   DocumentReference dogRef = dogDoc.reference; // This gets the reference of the dog document

//   // Query for matches where the matched dog is dog1 and dog 2 is current_dog and status is "pending"
//   QuerySnapshot matchSnapshot = await matchData
//       .where("dog1", isEqualTo: dogRef)  // Directly use the DocumentReference
//       .where("dog2", isEqualTo: db.collection('dogs').doc(dog_id))  // Use DocumentReference for current dog
//       .where("status", isEqualTo: "Pending")
//       .get();

//   if (matchSnapshot.docs.isEmpty) {
//     print("No pending matches found for this dog. Creating a new match.");

//     // Create a new match document if no pending matches exist
//     await matchData.add({
//       "createdOn": FieldValue.serverTimestamp(),
//       "dog1": dogRef,  // Use DocumentReference for the current dog
//       "dog2": db.collection('dogs').doc(dog_id),  // DocumentReference for the other dog
//       "status": "Pending", // pending match
//     });
//   } else {
//     // If not empty, update the status to "Accepted"
//     for (var doc in matchSnapshot.docs) {
//       String matchId = doc.id;
//       await matchData.doc(matchId).update({
//         "status": "Accepted",
//       });
//     }
//   }
// }

// Future<void> rejectDog(QueryDocumentSnapshot dogDoc) async {
//   final FirebaseFirestore db = FirebaseFirestore.instance;
//   final matchData = db.collection('matches');
//   DocumentReference dogRef = dogDoc.reference; // Reference of the dog document

//   await matchData.add({
//     "createdOn": FieldValue.serverTimestamp(),
//     "dog1": db.collection('dogs').doc(dog_id), // Use DocumentReference for the current dog
//     "dog2": dogRef,  // Use DocumentReference for the rejected dog
//     "status": "Rejected", // rejected match
//   });
// }


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