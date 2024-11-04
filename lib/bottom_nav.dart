import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'styled_button.dart';
import 'models/app_state.dart';
import 'models/state_manager_model.dart';


class BottomNav extends StatelessWidget{
  const BottomNav();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.teal,
      child: Row(
        children: [
          TextButton(
            onPressed: () {
              print("button 1 is pressed");
            },
            style: TextButton.styleFrom(
              foregroundColor: Colors.white,
              backgroundColor: Colors.red,
            ),
            child: const Text("1"),
          ),
          TextButton(
            onPressed: () {
              print("button 2 is pressed");
            },
            style: TextButton.styleFrom(
              foregroundColor: Colors.white,
              backgroundColor: Colors.blue,
            ),
            child: const Text("2"),
          )
        ]
      )
    );
  }

}