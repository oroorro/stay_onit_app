import 'package:flutter/material.dart';
import 'package:vector_math/vector_math_64.dart' as vmath;
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'package:cupertino_icons/cupertino_icons.dart';
import 'dart:ui' as ui;
import 'styled_button.dart';

import 'models/app_state.dart';
import 'models/state_manager_model.dart';

import 'top_nav.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (context) => StateManagerModel(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Project Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color.fromARGB(26, 255, 255, 255)),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Home'), 
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();

}


class _MyHomePageState extends State<MyHomePage> {

  Size boxSize = const Size(800, 750); // Initial size

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Column(
        children: [
          TopNav(),  // Pass callback to _TopNav
          SizedBox(
            width: boxSize.width,
            height: boxSize.height,
            child: _MiddleView(boxSize: boxSize, onResize: (newSize) {
              setState(() {
                boxSize = newSize; // Update box size dynamically
              });
            }),
          ),
        ],
      ),
    );
  }
}


class _MiddleView extends StatefulWidget {

  final Size boxSize;
  final ValueChanged<Size> onResize; // Callback to update size
  
  
  const _MiddleView({required this.boxSize, required this.onResize});

  
  
  @override
  State<_MiddleView> createState() => _MiddleViewState();
}

class _MiddleViewState extends State<_MiddleView> {
  Key _interactiveViewerKey = UniqueKey();
  //List<Offset> points = [];  // Store the points where the user drags
  Offset totalPanOffset = Offset.zero;
  final TransformationController  _transformationController = TransformationController();
  double eraserRadius = 15.0;


  int foundPathIndex = -1; 
  List<int> foundPathIndices = [];

  List<List<Offset>> paths = [];
  List<Offset> currentPath = [];
  List<Offset> selectedPoints = []; //track selected lines within the lasso area
  List<Offset> lassoPath = []; //track lasso drawing 

  bool isMovingPoints = false; // Track if points are being moved
  Offset initialDragOffset = Offset.zero; // Track the initial drag start point

  Offset? lastTapLocation; // Store last tap location for click detection

  Size boxSize = const Size(400, 600); // Initial ColoredBox size
  bool resizeHappened = false;  //flag to control repaint on resize, will be set true when resizingBlock gets triggered in _buildResizeHandle; onpanUpdate and set to false again onPanEnd in _buildResizeHandle 

  @override
  Widget build(BuildContext context) {

    final AppState currentState = context.watch<StateManagerModel>().currentState; 

     return InteractiveViewer(
      transformationController: _transformationController,
      boundaryMargin: const EdgeInsets.all(double.infinity),  // Allow panning without limits
      minScale: 0.2,  // Minimum zoom scale
      maxScale: 4.0,  // Maximum zoom scale
      onInteractionStart: (details) {

      },
       onInteractionUpdate: (details) {
        if (currentState == AppState.zooming) {
          // Use focalPointDelta to track panning or zoom changes
          setState(() {
            totalPanOffset += details.focalPointDelta;
          });
        }
      },
      onInteractionEnd: (details) {
      },
     child: _buildViewBasedOnState(currentState),
    );
  }


  Widget _buildViewBasedOnState(AppState currentState) {
    switch (currentState) {
      case AppState.zooming:
        return _buildZoomingView();
      case AppState.resizingBlock:
        return _buildResizingView();
      case AppState.drawing:
      case AppState.erasing:
      case AppState.lassoing:
      default:
        return _buildDrawingView();
    }
  }

  Widget _buildDrawingView() {
    final AppState currentState = context.watch<StateManagerModel>().currentState;
    return GestureDetector( // Drawing mode is enabled 
      onTapUp: (details) {
                  handleTap(details.localPosition); // Check if tap clears selection
              },
      onPanStart: (details) {
        setState(() {
          if(currentState == AppState.drawing){
            currentPath = [details.localPosition];
          }else if(currentState == AppState.lassoing){
            if(selectedPoints.isNotEmpty){ //when selected path exist, Start moving points if any are selected
              isMovingPoints = true;
              initialDragOffset = details.localPosition;
            }else{ // save currently drawn path as lasso path 
              lassoPath = [details.localPosition];
            } 
          }
        });
      },
      onPanUpdate: (details) {
        if(currentState == AppState.drawing){
          setState(() {
            RenderBox renderBox = context.findRenderObject() as RenderBox;
            Matrix4 matrix = _transformationController.value;
            Offset localPosition = renderBox.globalToLocal(details.globalPosition);
            localPosition = _applyMatrixToPoint(localPosition, matrix);
            currentPath.add(details.localPosition);  //uc-7
            _updateBoxSizeForPath(localPosition);
          });
        }else if(currentState == AppState.erasing){ // Perform erasing
            setState(() {
            RenderBox renderBox = context.findRenderObject() as RenderBox;
            Offset localPosition = renderBox.globalToLocal(details.globalPosition);
            Matrix4 matrix = _transformationController.value;
            localPosition = _applyMatrixToPoint(localPosition, matrix);
            //_erasePoint(details.globalPosition);  
            _erasePoint(localPosition);  
          });
        }
        else if(currentState == AppState.lassoing){ //Perform Lasso
          //draw points when dragging on the canvas 
          setState(() {
            if (isMovingPoints && selectedPoints.isNotEmpty){ 
              Offset delta = details.localPosition - initialDragOffset;
              for (var foundIndex in foundPathIndices) {
                for (int i = 0; i < paths[foundIndex].length; i++) {
                  paths[foundIndex][i] = paths[foundIndex][i] + delta;
                }
              }
              initialDragOffset = details.localPosition; // Update the drag point
            }else{
              RenderBox renderBox = context.findRenderObject() as RenderBox;
              Matrix4 matrix = _transformationController.value;
              Offset localPosition = renderBox.globalToLocal(details.globalPosition);
              localPosition = _applyMatrixToPoint(localPosition, matrix);
              lassoPath.add(localPosition);
            }
          });
        }
      },
      onPanEnd: (details) {
        if (currentState == AppState.lassoing) {
          if (isMovingPoints) { // interaction ended when selected path has been dragging made from lasso feature
            isMovingPoints = false; // then unselect the selected path from lasso
            selectedPoints.clear(); 
          }else{
            selectPointsInsideLasso();
            setState(() {
              lassoPath = []; // Clear lasso after selection
            });
          }
        }
        else if (currentState == AppState.drawing) {
          setState(() {
            paths.add(currentPath); // uc-7
            currentPath = []; // Clear current path for new drawing uc-7
          });
        }
      },
      child: ColoredBox(
        color: const Color.fromARGB(255, 223, 188, 210),  // Background color
        child: Stack(
          children: [
            CustomPaint(
              painter: DrawingPainter(paths, currentPath, selectedPoints, lassoPath, foundPathIndex, foundPathIndices, resizeHappened),
              size: boxSize,
            ),
          ],
        ) 
      )
    );
  }
  void _updateBoxSizeForPath(Offset point) {
    bool needsResize = false;
    double newWidth = boxSize.width;
    double newHeight = boxSize.height;

    const padding = 10.0;

    print('updateBoxSize $point $boxSize');
    if (point.dx > boxSize.width - padding ) {
      newWidth = point.dx + 20; // Add padding
      needsResize = true;
    }
    if (point.dy > boxSize.height - padding ) {
      newHeight = point.dy + 20; // Add padding
      needsResize = true;
    }

    if (needsResize) {
      setState(() {
        boxSize = Size(newWidth, newHeight);
        widget.onResize(boxSize);
        print("Box size updated to: $boxSize"); // Log the new box size
      });
      
    }
  }

  Widget _buildZoomingView() {
    
    return Container(
      color: const Color.fromARGB(255, 223, 188, 210),
      child: CustomPaint(
        painter: DrawingPainter(paths, currentPath, selectedPoints, lassoPath, foundPathIndex, foundPathIndices, resizeHappened),
        size: boxSize,
      ),
    );
  }

  Widget _buildResizingView() {
  //print('_buildResizingView :resizeHappened $resizeHappened $boxSize');
  double dynamicBoundary = widget.boxSize.width > widget.boxSize.height
    ? widget.boxSize.width
    : widget.boxSize.height;

  return GestureDetector(
    child: Container(
      color: const Color.fromARGB(255, 229, 110, 186),
      width: boxSize.width,
      height: boxSize.height,
      child: InteractiveViewer(
        //key: _interactiveViewerKey,
        transformationController: _transformationController,
        boundaryMargin: EdgeInsets.all(dynamicBoundary), // Update based on box size
        minScale: 0.2,
        maxScale: 4.0,
        child: Stack(
          children: [
            CustomPaint(
              painter: DrawingPainter(
                paths,
                currentPath,
                selectedPoints,
                lassoPath,
                foundPathIndex,
                foundPathIndices,
                resizeHappened
              ),
              size: boxSize,
            ),
            Positioned(
              right: 0,
              bottom: 0,
              child: Transform.scale(
                scale: 1 / _transformationController.value.getMaxScaleOnAxis(),
                child: _buildResizeHandle(),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}




  //helper method that gets triggered when edge anchor gets clicked, it is used to resize the block 
  Widget _buildResizeHandle() {
    return GestureDetector(
      onPanUpdate: (details) {
        
        final newSize = Size(
          (widget.boxSize.width + details.delta.dx).clamp(200, double.infinity),
          (widget.boxSize.height + details.delta.dy).clamp(200, double.infinity),
        );
        setState(() {
          widget.onResize(newSize);
          //_interactiveViewerKey = UniqueKey(); 
        });
        
        print('Updated boxSize in _buildResizeHandle: $newSize');
      },
      onPanEnd: (details) {
        setState(() {
          resizeHappened = false;  // Reset the flag after resizing ends
        });
      },
      child: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          color: Colors.blue,
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }


  // Method to handle tap location and clear selection if outside
  void handleTap(Offset tapPosition) {
    bool tapIsNearSelected = selectedPoints.any((point) {     // Calculate if tap is close to any selected points
      return (point - tapPosition).distance < 15; // Adjust the distance threshold as needed
    });

    if (!tapIsNearSelected) {
      setState(() {
        selectedPoints.clear();
        foundPathIndices.clear();
      });
    }
  }


  void selectPointsInsideLasso() {

    //reset 
    foundPathIndex = -1;
    foundPathIndices = [];
    //flag that indicates either entire path in List<Offset> in paths[i] belong to selected lasso area
    selectedPoints.clear();
    
    // Create a Path from lasso points
    final createdPath = ui.Path()..addPolygon(lassoPath, true);

    for (int i = 0; i < paths.length; i++) {

      int countPointInLassoErea = 0;
      List<Offset> pathList = paths[i];
      
      // Check if all points in the current pathList are inside the lasso path
      for (var point in pathList) {
        if (!createdPath.contains(point)) {
          continue; // If a point is outside, no need to check further in this pathList, go to next path
        }
        else{ //start count the number of point exist in paths[i] that belongs to lasso area
          countPointInLassoErea++;
        }
      }
      //handle the case where no path was found
      // If all points belong to the lasso, mark the pathList and store the index
      //print('countPointInLassoErea $i : $countPointInLassoErea, ${pathList.length}');

      if (countPointInLassoErea == pathList.length) {
        selectedPoints = List.from(pathList); // Copy the pathList to selectedPoints
        foundPathIndex = i; // Store the indexof the found path
        foundPathIndices.add(i);
        if (foundPathIndex == -1) {
          print("No path fully inside the lasso.");
          //if no path was found then we need to remove lasso's path 
        } else {
          print("Path found at index: $foundPathIndex"); // of course will not get printed 
        }
      }
    }
  }

  Offset _applyMatrixToPoint(Offset point, Matrix4 matrix) {
    // Apply the inverse of the transformation matrix
    Matrix4 inverseMatrix = Matrix4.inverted(matrix);
    final vmath.Vector3 transformed3 = inverseMatrix.transform3(vmath.Vector3(point.dx, point.dy, 0));
    return Offset(transformed3.x, transformed3.y);
  }

  // Erase points that are near the eraser's position
  void _erasePoint(Offset localPosition) {
    setState(() {

      for (int i = 0; i < paths.length; i++) {
        List<Offset> path = paths[i];
        bool splitOccurred = false;

        for (int j = 0; j < path.length; j++) {
          // Check if the point is near the eraser
          if ((path[j] - localPosition).distance < eraserRadius) {
            // Split path into two segments around the erased point
            List<Offset> firstSegment = path.sublist(0, j);
            List<Offset> secondSegment = path.sublist(j + 1);

            // Remove the original path and replace it with new segments
            paths.removeAt(i);
            if (firstSegment.isNotEmpty) paths.insert(i, firstSegment);
            
            if (secondSegment.isNotEmpty){
              if(i == paths.length){
                paths.add(secondSegment); //prevents error of using insert; it throws an error when inserting into bigger than length of List
              }else{
                paths.insert(i + 1, secondSegment);
              }
            } 

            splitOccurred = true;
            break;
          }
        }
        if (splitOccurred) break; // Stop checking if a split occurred
      }
    });
  }

}

class DrawingPainter extends CustomPainter {
  final List<List<Offset>> paths;
  final List<Offset> currentPath;
  final List<Offset> selectedPoints;
  final List<Offset> lassoPath;
  final int foundPathIndex;
  final List<int> foundPathIndices;
  final bool resizeHappened;

  DrawingPainter(this.paths, this.currentPath, this.selectedPoints, this.lassoPath, this.foundPathIndex, this.foundPathIndices,this.resizeHappened,);

  @override
  void paint(Canvas canvas, Size size) {
    // Draw previous paths
    for (int pathIndex = 0; pathIndex < paths.length; pathIndex++) {
      List<Offset> path = paths[pathIndex];
      if (path.isNotEmpty) {

        for(int i = 0; i < foundPathIndices.length; i++){
          if (pathIndex == foundPathIndices[i]) {
            final borderPaint = Paint()
              ..color = Colors.orangeAccent // Choose a border color for highlighting
              ..strokeCap = StrokeCap.round
              ..strokeWidth = 9.0 // Width slightly larger than the main path
              ..style = PaintingStyle.stroke;

            for (int i = 0; i < path.length - 1; i++) {
              canvas.drawLine(path[i], path[i + 1], borderPaint); // Draw border line
            }
          }
        }
        

        final paint = Paint()
          ..color = Colors.black
          ..strokeCap = StrokeCap.round
          ..strokeWidth = 5.0;
        for (int i = 0; i < path.length - 1; i++) {
          canvas.drawLine(path[i], path[i + 1], paint);
        }
      } 
    }

    // Draw the current path being drawn
    if (currentPath.isNotEmpty) {
      final paint = Paint()
        ..color = Colors.blue
        ..strokeCap = StrokeCap.round
        ..strokeWidth = 5.0;
      for (int i = 0; i < currentPath.length - 1; i++) {
        canvas.drawLine(currentPath[i], currentPath[i + 1], paint);
      }
    }

    // Draw selected points
    // final selectedPaint = Paint()
    //   ..color = Colors.red
    //   ..style = PaintingStyle.fill;

    // for (var point in selectedPoints) {
    //   canvas.drawCircle(point, 5.0, selectedPaint);
    // }

    // Draw lasso path
    if (lassoPath.isNotEmpty) {
      final lassoPaint = Paint()
        ..color = Colors.green
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0;
      for (int i = 0; i < lassoPath.length - 1; i++) {
        canvas.drawLine(lassoPath[i], lassoPath[i + 1], lassoPaint);
      }
    }


  }

@override
bool shouldRepaint(DrawingPainter oldDelegate) {
  return true;
        oldDelegate.resizeHappened !=  resizeHappened||
        oldDelegate.paths != paths ||
        oldDelegate.currentPath != currentPath ||
        oldDelegate.selectedPoints != selectedPoints ||
        oldDelegate.lassoPath != lassoPath ||
        oldDelegate.foundPathIndex != foundPathIndex ||
        oldDelegate.foundPathIndices != foundPathIndices;
}
}