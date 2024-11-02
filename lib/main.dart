import 'package:flutter/material.dart';
import 'package:vector_math/vector_math_64.dart' as vmath;
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'package:cupertino_icons/cupertino_icons.dart';
import 'dart:ui' as ui;
import 'styled_button.dart';


enum AppState {
  drawing,
  lassoing,
  erasing,
  resizing,
  none,
  zooming,
}

// Model to hold and manage states
class StateManagerModel extends ChangeNotifier {

  AppState _currentState = AppState.none;

  AppState get currentState => _currentState;

  void updateCurrentState(AppState newState) {
    print("newState is :${newState}");
    _currentState = newState;
    notifyListeners();
  }
}


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
  bool isDrawingMode = false;
  bool isZoomingMode = false;


  void setDrawingMode(bool enabled) {
    setState(() {
      isDrawingMode = enabled;
    });
  }

  void setZoomingMode(bool enabled) {
    setState(() {
      isZoomingMode = enabled;
      print("zoom Mode enabled");
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: const Column(
        children: [
          _TopNav(),  // Pass callback to _TopNav
          Expanded(
            child: _MiddleView(),  // Pass state to _MiddleView
          ),
        ],
      ),
    );
  }
}




class _TopNav extends StatelessWidget {
  // final Function(bool) setDrawingMode;
  // final Function(bool) setZoomingMode;

  //const _TopNav({required this.setDrawingMode, required this.setZoomingMode});
  const _TopNav();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 5.0),
      color: Colors.blueAccent,
      child: Row(
        //mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          StyledButton(Icons.home,null, 'Home'),
          StyledButton(Icons.assignment, null, 'Markdown'),
          StyledButton(Icons.zoom_in, null, 'Zoom', 
            (){
              context.read<StateManagerModel>().updateCurrentState(AppState.zooming);
            }
          ),
          StyledButton(Icons.brush, null, 'Paint', 
            (){
              context.read<StateManagerModel>().updateCurrentState(AppState.drawing);
            }
          ),
          StyledButton(Icons.add, null, 'New Block'),
          StyledButton(Icons.publish, null, 'Import'),
          StyledButton(
              // 'assets/images/eraser-icon.svg',  // SVG asset path
              Icons.check_box_outline_blank,
              null,
              'Logo',                           // Label
              (){
                context.read<StateManagerModel>().updateCurrentState(AppState.erasing);
              }
            ),
          StyledButton(Icons.highlight_alt, null, 'Lasso',
          (){
            //if app state was already lasso, make app state to none 
            //final AppState lassoState = context.watch<StateManagerModel>().currentState == AppState.lassoing ? AppState.none: AppState.lassoing;
            
            final AppState currentState = Provider.of<StateManagerModel>(context, listen: false).currentState;
            final AppState lassoState = currentState == AppState.lassoing ? AppState.none : AppState.lassoing;
            //Provider.of<StateManagerModel>(context, listen: false).updateCurrentState(lassoState);
            context.read<StateManagerModel>().updateCurrentState(lassoState);
          }),
          StyledButton(Icons.open_in_full, null, 'Resize'),
        ],
      ),
    );
  }
}

class _MiddleView extends StatefulWidget {
  //final bool isDrawingMode;  // Flag to indicate whether it's drawing mode
  //final bool isZoomingMode; 
  //const _MiddleView({required this.isDrawingMode, required this.isZoomingMode});
  const _MiddleView();

  @override
  State<_MiddleView> createState() => _MiddleViewState();
}

class _MiddleViewState extends State<_MiddleView> {
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
      child: currentState == AppState.zooming //widget.isZoomingMode  // Disable gesture detection when zooming
          ? Container( //when zooming Mode is enabled 
              color: const Color.fromARGB(255, 223, 188, 210),
              child: (() {
                return CustomPaint(
                  painter: DrawingPainter(paths, currentPath, selectedPoints, lassoPath, foundPathIndex, foundPathIndices),  // Pass the points to the painter
                  size: const Size(1000, 1000),
                );
              })(), 
            )
          : GestureDetector( // Drawing mode is enabled 
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
                  });
                }else if(currentState == AppState.erasing){ // Perform erasing
                  //  setState(() {
                  //   _erasePoint(details.globalPosition);  
                  // });
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
                      Offset localPosition = renderBox.globalToLocal(details.globalPosition);
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
                      painter: DrawingPainter(paths, currentPath, selectedPoints, lassoPath, foundPathIndex, foundPathIndices),
                      size: const Size(1000, 1000),
                    ),
                  ],
                ) 
              )
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
    bool isApointNotBelong = true;
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
  // void _erasePoint(Offset globalPosition) {
  //   RenderBox renderBox = context.findRenderObject() as RenderBox;
  //   Offset localPosition = renderBox.globalToLocal(globalPosition);

  //   // Track the indices of the points to remove
  //   setState(() {
  //     // Remove points near the eraser and insert a sentinel value (-1, -1) to break the line
  //     for (int i = 0; i < points.length; i++) {
  //       if ((points[i] - localPosition).distance < eraserRadius) {
  //         points[i] = const Offset(-1, -1);  // Insert sentinel value to break the line
  //       }
  //     }
  //   });
  // }

}



class _LassoCreater extends CustomPainter{
  final List<Offset> selectedPoints;
  final Path lassoPath;

  _LassoCreater({required this.selectedPoints, required this.lassoPath});

  @override
  void paint(Canvas canvas, Size size) {
    Paint paint = Paint()
      ..color = Colors.blue
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 5.0;

    // Highlight selected lines
    paint.color = Colors.red;  // Use a different color to highlight selected lines
    for (int i = 0; i < selectedPoints.length - 1; i += 2) {
      canvas.drawLine(selectedPoints[i], selectedPoints[i + 1], paint);
    }

    // Draw the bounding box for the selected points
    if (selectedPoints.isNotEmpty) {
      Rect boundingBox = getBoundingBox(selectedPoints);
      paint.color = Colors.green;
      paint.style = PaintingStyle.stroke;
      canvas.drawRect(boundingBox, paint);
    }

    // Draw lasso path
    if (lassoPath != null) {
      paint.color = Colors.purple;
      paint.style = PaintingStyle.stroke;
      canvas.drawPath(lassoPath, paint);
    }
  }

    // Calculate the bounding box for the selected points
  Rect getBoundingBox(List<Offset> points) {
    if (points.isEmpty) return Rect.zero;

    // Find the minimum and maximum x and y coordinates
    double minX = points.map((p) => p.dx).reduce((a, b) => a < b ? a : b);
    double maxX = points.map((p) => p.dx).reduce((a, b) => a > b ? a : b);
    double minY = points.map((p) => p.dy).reduce((a, b) => a < b ? a : b);
    double maxY = points.map((p) => p.dy).reduce((a, b) => a > b ? a : b);

    // Create a rectangle from the min and max values
    return Rect.fromLTRB(minX, minY, maxX, maxY);
  }



  @override
  bool shouldRepaint(_LassoCreater oldDelegate) {
    return true;  // Always repaint when the points list updates
  }

}


//previosly attempt on drawing lines  
class _CanvasPainter extends CustomPainter {
  final List<Offset> points;  // List of points to draw
  
  _CanvasPainter({required this.points});

  @override
  void paint(Canvas canvas, Size size) {
    Paint paint = Paint()
      ..color = Colors.blue
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 15.0;

    //canvas.drawPoints(ui.PointMode.points, points, paint);
    for (int i = 0; i < points.length - 1; i++) {
      if (points[i] != const Offset(-1, -1) && points[i + 1] != const Offset(-1, -1)) {
        // Draw a line between consecutive points, excluding sentinel (-1, -1)
        canvas.drawLine(points[i], points[i + 1], paint);
        
      }
    }
  }

  @override
  bool shouldRepaint(_CanvasPainter oldDelegate) {
    return true;  // Always repaint when the points list updates
  }
}



//new line drawing Widget 
//for passed indices of selected path, chang
class DrawingPainter extends CustomPainter {
  final List<List<Offset>> paths;
  final List<Offset> currentPath;
  final List<Offset> selectedPoints;
  final List<Offset> lassoPath;
  final int foundPathIndex;
  final List<int> foundPathIndices;

  DrawingPainter(this.paths, this.currentPath, this.selectedPoints, this.lassoPath, this.foundPathIndex, this.foundPathIndices);

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
  }
}