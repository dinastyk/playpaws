import 'package:flutter/material.dart';
import 'package:flutter_swipable/flutter_swipable.dart';
class DogCard extends StatelessWidget {
  final color;
  DogCard({required this.color});

  @override
  Widget build(BuildContext context){
    return Swipable(
      onSwipeLeft: (finalPosition){
        print('Rejected');
      },
      onSwipeRight: (finalPosition){
        print('Accepted');
      },
      child: Container(
        color: color,
      ),
    );
  }
}