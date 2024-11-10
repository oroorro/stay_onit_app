import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'styled_button.dart';
import 'models/app_state.dart';
import 'models/state_manager_model.dart';


class BottomNav extends StatelessWidget{
  final VoidCallback onNewDrawingView;
  final Function(int) onSelectDrawingView;
  final int drawingViewCount;

   const BottomNav({
    required this.onNewDrawingView,
    required this.onSelectDrawingView,
    required this.drawingViewCount,
  });

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
              onNewDrawingView(); // add _MiddleView into drawingViews from index 0 .. 1 .. 2
            },
             
            style: TextButton.styleFrom(
              foregroundColor: Colors.white,
              backgroundColor: const Color.fromARGB(255, 0, 0, 0),
            ),
            child: const Text("New"),
          ),
          // Create a button for each drawing view instance
          ...List.generate(drawingViewCount, (index) {
            final viewId = index + 1;
            return TextButton(
              
              onPressed: () => {
                print("index at onPressed $index"),
                onSelectDrawingView(index)
                },
              style: TextButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: Colors.blue,
              ),
              child: Text(viewId.toString()),
            );
          }),
        ]
      )
    );
  }

}