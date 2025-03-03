import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
//  import 'package:get/get.dart';
//  import 'package:swipe_card_demo/widget/colors.dart';
//  import 'package:swipe_card_demo/widget/text_widget.dart';

//  import '../controllers/home_controller.dart';
// import '../firebase_options.dart';
// import '../main.dart';
class SwipeCardsDemo extends StatefulWidget {
  @override
  _SwipeCardsDemoState createState() => _SwipeCardsDemoState();
}

class _SwipeCardsDemoState extends State<SwipeCardsDemo> {
  List<String> cardList = ["Card 1", "Card 2", "Card 3", "Card 4", "Card 5"];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Swipe Cards Demo"),
      ),
      body: Center(
        child: Stack(
          children: cardList.map((card) {
            int index = cardList.indexOf(card);
            return Dismissible(
              key: Key(card),
              direction: DismissDirection.horizontal,
              onDismissed: (direction) {
                setState(() {
                  cardList.removeAt(index);
                });
                if (direction == DismissDirection.endToStart) {
                  // Handle left swipe
                  print("Swiped left on card $index");
                } else if (direction == DismissDirection.startToEnd) {
                  // Handle right swipe
                  print("Swiped right on card $index");
                }
              },
              background: Container(
                color: Colors.red,
                alignment: Alignment.centerLeft,
                child: Icon(Icons.thumb_down, color: Colors.white),
              ),
              secondaryBackground: Container(
                color: Colors.green,
                alignment: Alignment.centerRight,
                child: Icon(Icons.thumb_up, color: Colors.white),
              ),
              child: Card(
                child: Center(
                  child: Text(
                    card,
                    style: TextStyle(fontSize: 24.0),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}