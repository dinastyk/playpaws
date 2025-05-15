import 'package:flutter/material.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'dog_profile_screen.dart';
import 'CardSwipe.dart';
class SwipeCard extends StatefulWidget {
  final List<QueryDocumentSnapshot> dogs;

  const SwipeCard({Key? key, required this.dogs}) : super(key: key);

  @override
  _SwipeCardState createState() => _SwipeCardState();
}

class _SwipeCardState extends State<SwipeCard> {
  late List<QueryDocumentSnapshot> dogCards;

  @override
  void initState() {
    super.initState();
    dogCards = List.from(widget.dogs); // Copy so we can remove cards
  }

  void handleSwipe(DismissDirection direction, QueryDocumentSnapshot dogDoc) async {
    var dogData = dogDoc.data() as Map<String, dynamic>;
    print('Swiped on ${dogData['name']} (${dogData['breed']})');

    bool isLiked = direction == DismissDirection.startToEnd;
    if (isLiked) {
      await matchDog(dogDoc);
    } else {
      await rejectDog(dogDoc);
    }

    setState(() {
      dogCards.remove(dogDoc);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Find Your Pawfect Match!"),
        backgroundColor: const Color(0xFFD1E4FF),
        foregroundColor: Colors.black,
      ),
      backgroundColor: const Color(0xFFD1E4FF),
      body: Center(
        child: dogCards.isEmpty
            ? const Text("No more dogs!", style: TextStyle(fontSize: 20))
            : Stack(
                children: dogCards.reversed.map((dogDoc) {
                  return Dismissible(
                    key: Key(dogDoc.id),
                    direction: DismissDirection.horizontal,
                    onDismissed: (direction) => handleSwipe(direction, dogDoc),
                    background: swipeBackground(isRightSwipe: true),
                    secondaryBackground: swipeBackground(isRightSwipe: false),
                    child: DogCards(dogDoc: dogDoc),
                  );
                }).toList(),
              ),
      ),
    );
  }

  Widget swipeBackground({required bool isRightSwipe}) {
    return Container(
      color: isRightSwipe ? Colors.blue  : Colors.orange,
      alignment: isRightSwipe ? Alignment.centerLeft : Alignment.centerRight,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Text(
        isRightSwipe ? '🐶' : '😢',
        style: const TextStyle(fontSize: 48),
      ),
    );
  }
}


class DogCards extends StatelessWidget {
  final QueryDocumentSnapshot dogDoc;

  const DogCards({Key? key, required this.dogDoc}) : super(key: key);

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

// import 'package:flutter/material.dart';
// import 'package:firebase_core/firebase_core.dart';
// //  import 'package:get/get.dart';
// //  import 'package:swipe_card_demo/widget/colors.dart';
// //  import 'package:swipe_card_demo/widget/text_widget.dart';

// //  import '../controllers/home_controller.dart';
// // import '../firebase_options.dart';
// // import '../main.dart';
// class SwipeCardsDemo extends StatefulWidget {
//   @override
//   _SwipeCardsDemoState createState() => _SwipeCardsDemoState();
// }

// class _SwipeCardsDemoState extends State<SwipeCardsDemo> {
//   List<String> cardList = ["Card 1", "Card 2", "Card 3", "Card 4", "Card 5"];

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text("Swipe Cards Demo"),
//       ),
//       body: Center(
//         child: Stack(
//           children: cardList.map((card) {
//             int index = cardList.indexOf(card);
//             return Dismissible(
//               key: Key(card),
//               direction: DismissDirection.horizontal,
//               onDismissed: (direction) {
//                 setState(() {
//                   cardList.removeAt(index);
//                 });
//                 if (direction == DismissDirection.endToStart) {
//                   // Handle left swipe
//                   print("Swiped left on card $index");
//                 } else if (direction == DismissDirection.startToEnd) {
//                   // Handle right swipe
//                   print("Swiped right on card $index");
//                 }
//               },
//               background: Container(
//                 color: Colors.red,
//                 alignment: Alignment.centerLeft,
//                 child: Icon(Icons.thumb_down, color: Colors.white),
//               ),
//               secondaryBackground: Container(
//                 color: Colors.green,
//                 alignment: Alignment.centerRight,
//                 child: Icon(Icons.thumb_up, color: Colors.white),
//               ),
//               child: Card(
//                 child: Center(
//                   child: Text(
//                     card,
//                     style: TextStyle(fontSize: 24.0),
//                   ),
//                 ),
//               ),
//             );
//           }).toList(),
//         ),
//       ),
//     );
//   }
// }