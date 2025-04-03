import 'package:flutter/material.dart';
import 'SwipeCard.dart';
import 'CardSwipe.dart';

class HomePage extends StatelessWidget
{
  const HomePage({super.key});

  @override
  Widget build(BuildContext context)
  {
    return Scaffold
    (
      body: Column
      (
        children: 
        [
          Expanded
          (
            child: CardSwipe(),
          )
        ]
      )
    );
  }
}