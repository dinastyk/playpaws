import 'package:flutter/material.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:confetti/confetti.dart';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'dog_profile_screen.dart';
import 'dart:math';

// Function to calculate cosine similarity between two vectors
double cosineSimilarity(List<double> vectorA, List<double> vectorB) {
  if (vectorA.length != vectorB.length) {
    throw ArgumentError('Vectors must be the same length');
  }

  double dotProduct = 0;
  double magnitudeA = 0;
  double magnitudeB = 0;

  for (int i = 0; i < vectorA.length; i++) {
    dotProduct += vectorA[i] * vectorB[i];
    magnitudeA += pow(vectorA[i], 2);
    magnitudeB += pow(vectorB[i], 2);
  }

  if (magnitudeA == 0 || magnitudeB == 0) {
    return 0.0; // to avoid division by zero
  }

  return dotProduct / (sqrt(magnitudeA) * sqrt(magnitudeB));
}

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
    return await filteredDogsFuture;
  }

  final scoresDoc = await db.collection("dog_breeds").doc(currentBreed).get();
  Map<String, dynamic> scoresMap = scoresDoc.get("compatibility_scores");

  final filteredDogs = await filteredDogsFuture;
  final User? user = FirebaseAuth.instance.currentUser;
  if (user == null) return [];

  QuerySnapshot userSnapshot = await db.collection("users")
      .where("uid", isEqualTo: user.uid)
      .limit(1)
      .get();

  if (userSnapshot.docs.isNotEmpty) {
    DocumentSnapshot userDoc = userSnapshot.docs.first;
    Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
    // Map<String, dynamic> cosineSimilaritiesMap =
    //     userData['cosineSimilarities'] ?? {};
  

    final preferences = userData['preferences'];
    final weightPref = preferences['maxWeight'] ?? 0.0;

    List<MapEntry<QueryDocumentSnapshot, double>> pairs = await Future.wait(
      filteredDogs.map((dog) async {
        var dogData = dog.data() as Map<String, dynamic>;
        double similarity=0;
        bool hasCosine=false;
        final otherBreed = dog.get('breed');
        double compatScore = (scoresMap[otherBreed] ?? 0).toDouble(); 

if (userData.containsKey('userEmbedding') &&
    dogData.containsKey('dogEmbedding') &&
    userData['userEmbedding'] != null &&
    dogData['dogEmbedding'] != null) {

  List<dynamic> userEmbed = userData['userEmbedding'];
  List<dynamic> dogEmbed = dogData['dogEmbedding'];

  List<double> a = userEmbed.map((e) => (e as num).toDouble()).toList();
  List<double> b = dogEmbed.map((e) => (e as num).toDouble()).toList();

  similarity = cosineSimilarity(a, b);
  hasCosine = true;
}

        // double? cosineSimilarity = cosineSimilaritiesMap[dog.reference];
        double? dogWeight = dog.data().toString().contains('weight') ? (dog.get('weight')?.toDouble() ?? null) : null;

        double? weightScore;
        if (dogWeight != null && weightPref != 0.0) {
          weightScore = (1 - (dogWeight - weightPref).abs() / 10).clamp(0.0, 1.0);
        }

        bool hasCompat = compatScore > 0;
        // bool hasCosine = similarity != null;
        bool hasWeight = weightScore != null;

        double finalScore = 0.0;

        if (hasCompat && hasCosine && hasWeight) {
          finalScore = (compatScore * 0.4) + (similarity! * 0.3) + (weightScore! * 0.3);
        } else if (!hasCosine && hasCompat && hasWeight) {
          finalScore = (compatScore * 0.7) + (weightScore! * 0.3);
        } else if (!hasCompat && hasCosine && hasWeight) {
          finalScore = (similarity! * 0.65) + (weightScore! * 0.35);
        } else if (hasCompat && hasCosine && !hasWeight) {
          finalScore = (compatScore * 0.6) + (similarity! * 0.4);
        } else {
          // none of the scores exist properly, don't calculate
          return MapEntry(dog, -1.0);  // We'll filter these out
        }
          // print('Final Score for ${dog.id}: $finalScore');
        return MapEntry(dog, finalScore);
      }).toList(),
    );

    // Remove entries where final score was -1 (invalid dogs)
    pairs.removeWhere((pair) => pair.value == -1.0);

    // If no valid scoring could happen, just return original list
    if (pairs.isEmpty) {
      return filteredDogs;
    }

    pairs.sort((a, b) => b.value.compareTo(a.value));
    return pairs.map((e) => e.key).toList();
  }

  return [];
}

Future<List<QueryDocumentSnapshot>> getDogs() async {
  final FirebaseFirestore db = FirebaseFirestore.instance;
  final dogData = db.collection("dogs");
  final matchData = db.collection("matches");
  DocumentReference? dogRef = await getDogID();
  if (dogRef == null) {
     print("HERE");
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
  print('Filtered dogs count: ${filteredDogs.length}');

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
  int _currentIndex = 0;

  void onSwipeAction(int previousIndex, CardSwiperDirection direction) async {
    if (previousIndex < 0 || previousIndex >= widget.dogs.length) return;

    QueryDocumentSnapshot dogDoc = widget.dogs[previousIndex];
    var dogData = dogDoc.data() as Map<String, dynamic>;
    print('Swiping on dog: ${dogData['name']}');
    print('Breed: ${dogData['breed']}');
    print('Liked: ${direction == CardSwiperDirection.right}');

    bool isLiked = direction == CardSwiperDirection.right;
    if (isLiked) {
      await matchDog(dogDoc);
    } else {
      await rejectDog(dogDoc);
    }

    setState(() {
      if (_currentIndex < widget.dogs.length - 1) {
        _currentIndex++;
      }
    });

    print('New current index after swipe: $_currentIndex');
  }

 @override
Widget build(BuildContext context) {
  return Scaffold(
    appBar: AppBar(
    // title: const Text("Find Your Pawfect Match!"),
    backgroundColor: const  Color(0xFFD1E4FF), // Customize app bar color
    foregroundColor: Colors.black, // Sets the color of the title and icons
  ),
    backgroundColor: const  Color(0xFFD1E4FF),
    body: Padding(
      padding: const EdgeInsets.all(16.0),
      child: widget.dogs.isEmpty
          ? Center(child: CircularProgressIndicator())
          : CardSwiper(
              controller: _swiperController,
              cardsCount: widget.dogs.length,
              allowedSwipeDirection: AllowedSwipeDirection.only(
                left: true,
                right: true,
                up: false,
                down: false,
              ),
              onSwipe: (previousIndex, currentIndex, direction) {
                if (previousIndex != null) {
                  print('Swiped card at index: $previousIndex, direction: $direction');
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    onSwipeAction(previousIndex, direction);
                  });
                }
                return true;
              },
              cardBuilder: (context, index, _, __) {
                return index >= _currentIndex
                    ? DogCard(dogDoc: widget.dogs[index])
                    : Container(); 
              },
              numberOfCardsDisplayed: 2,
              backCardOffset: Offset(0, 10),
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
  final screenWidth = MediaQuery.of(context).size.width;
  final cardSize = screenWidth * 0.85; // 85% of screen width

  return GestureDetector(
    onTap: () {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => DogProfileScreen(dogData: dogData),
        ),
      );
    },
    child: Card(
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: Color(0xFFD1E4FF),
      shadowColor: Colors.orangeAccent,
      child: Container(
        height: cardSize, // make it square
        width: cardSize,
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.white, Color(0xFFFFF3E0)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.network(
                  dogData["dogPictureURL"] ??
                      "https://www.ohio.edu/sites/default/files/styles/max_650x650/public/2025-03/Image.jpeg?itok=hc0EF56Z",
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              dogData["name"] ?? "No name",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Color(0xFFEF6C00),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              dogData["breed"] ?? "Unknown breed",
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
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

// class DogCard extends StatelessWidget {
//   final QueryDocumentSnapshot dogDoc;

//   const DogCard({Key? key, required this.dogDoc}) : super(key: key);

//   @override
//   Widget build(BuildContext context) {
//     var dogData = dogDoc.data() as Map<String, dynamic>;

//     return Card(
//       elevation: 8,
//       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
//       color: Colors.white, // Keep white for a clean look
//       shadowColor: Colors.orangeAccent, // Orange shadow for depth
//       child: Container(
//         height: double.infinity, // Card takes max height it can
//         padding: const EdgeInsets.all(16.0),
//         decoration: BoxDecoration(
//           gradient: LinearGradient(
//             colors: [Colors.white, Color(0xFFFFF3E0)], // subtle gradient (lighter orange)
//             begin: Alignment.topLeft,
//             end: Alignment.bottomRight,
//           ),
//           borderRadius: BorderRadius.circular(16),
//         ),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.center,
//           children: [
//             Expanded(
//               child: ClipRRect(
//                 borderRadius: BorderRadius.circular(16),
//                 child: Image.network(
//                   dogData["dogPictureURL"] ??
//                       "https://www.ohio.edu/sites/default/files/styles/max_650x650/public/2025-03/Image.jpeg?itok=hc0EF56Z",
//                   width: double.infinity,
//                   fit: BoxFit.cover,
//                 ),
//               ),
//             ),
//             const SizedBox(height: 12),
//             Text(
//               dogData["name"] ?? "No name",
//               style: TextStyle(
//                 fontSize: 22, 
//                 fontWeight: FontWeight.bold, 
//                 color: Color(0xFFEF6C00), // Orange color for name
//               ),
//             ),
//             const SizedBox(height: 6),
//             Text(
//               dogData["breed"] ?? "Unknown breed",
//               style: TextStyle(fontSize: 16, color: Colors.grey),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
// Future<List<QueryDocumentSnapshot>> sortDogs(
//     Future<List<QueryDocumentSnapshot>> filteredDogsFuture,
//     DocumentReference dogRef) async {
//   final FirebaseFirestore db = FirebaseFirestore.instance;

//   final currentBreed = await getBreed(dogRef);
//   if (currentBreed == "") {
//     return await filteredDogsFuture;  // Ensuring you await the future properly
//   }

//   final scoresDoc =
//       await db.collection("dog_breeds").doc(currentBreed).get();
//   Map<String, dynamic> scoresMap = scoresDoc.get("compatibility_scores");

//   final filteredDogs = await filteredDogsFuture;

//   // Get the cosine similarities map directly from the user's document
//   final User? user = FirebaseAuth.instance.currentUser;
//   if (user == null) return []; // Return empty list if no user is logged in

//   // Query to find the document where uid field matches the current user's UID
//   QuerySnapshot userSnapshot = await db.collection("users")
//       .where("uid", isEqualTo: user.uid)
//       .limit(1) // Ensure only one document is returned
//       .get();

//   if (userSnapshot.docs.isNotEmpty) {
//     DocumentSnapshot userDoc = userSnapshot.docs.first;

//     // Get the cosineSimilarities field (a map of DocumentReference to score)
//     Map<String, dynamic> cosineSimilaritiesMap =
//         userDoc.get('cosineSimilarities') ?? {};

//     // Mapping dogs with their final scores
//     List<MapEntry<QueryDocumentSnapshot, double>> pairs = await Future.wait(filteredDogs.map((dog) async {
//       final otherBreed = dog.get('breed');
//       final score = (scoresMap[otherBreed] ?? 0).toDouble();

//       // Get cosine similarity score from the user's field (if available)
//       double cosineSimilarity = cosineSimilaritiesMap[dog.reference] ?? 0.0;

//       // Fetch height and weight comparison from user preferences
//       final userData = userSnapshot.docs.first.data() as Map<String, dynamic>;
//       final preferences = userData['preferences'];
//       // final heightPref = preferences['maxHeight'] ?? 0.0;
//       final weightPref = preferences['maxWeight'] ?? 0.0;
//       // final dogHeight = dog.get('height') ?? 0.0;
//       final dogWeight = dog.get('weight') ?? 0.0;

//       // Normalize height and weight comparisons (scale between 0 and 1)
//       // double heightScore = (1 - (dogHeight - heightPref).abs()) / 10;
//       double weightScore = (1 - (dogWeight - weightPref).abs()) / 10;

//       // Calculate final score with weights
//       // double finalScore = (cosineSimilarity * 0.3) + (score * 0.4) +
//       //     ((heightScore + weightScore) / 2 * 0.3);
//             double finalScore = (cosineSimilarity * 0.3) + (score * 0.4) +
//           (weightScore * 0.3);
//       print('Final Score for ${dog.id}: $finalScore');

//       return MapEntry(dog, finalScore);  // Returning MapEntry for sorting later
//     }).toList());

//     // Sort based on the final score
//     pairs.sort((a, b) => b.value.compareTo(a.value));  // Sort descending

//     return pairs.map((e) => e.key).toList();  // Return sorted dogs list
//   }

//   return []; // Return empty list if user document is not found
// }