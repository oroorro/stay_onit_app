import 'package:flutter/material.dart';
import 'package:vector_math/vector_math_64.dart' as vmath;
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'package:cupertino_icons/cupertino_icons.dart';
import 'dart:ui' as ui;

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
      body: Column(
        children: [
          _TopNav(setDrawingMode: setDrawingMode, setZoomingMode: setZoomingMode,),  // Pass callback to _TopNav
          Expanded(
            child: _MiddleView(isDrawingMode: isDrawingMode, isZoomingMode: isZoomingMode),  // Pass state to _MiddleView
          ),
        ],
      ),
    );
  }
}




class _TopNav extends StatelessWidget {
  final Function(bool) setDrawingMode;
  final Function(bool) setZoomingMode;

  const _TopNav({required this.setDrawingMode, required this.setZoomingMode});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 5.0),
      color: Colors.blueAccent,
      child: Row(
        //mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _styledButton(Icons.home,null, 'Home'),
          _styledButton(Icons.assignment, null, 'Markdown'),
          _styledButton(Icons.zoom_in, null, 'Zoom', 
            (){
              setZoomingMode(true);
              setDrawingMode(false);
              print('Zoom Mode: true, Drawing Mode: false');
            }
          ),
          _styledButton(Icons.brush, null, 'Paint', 
            (){
              setZoomingMode(false);
              setDrawingMode(true);
              print('Zoom Mode: false, Drawing Mode: true');
              context.read<StateManagerModel>().updateCurrentState(AppState.drawing);
            }
          ),
          _styledButton(Icons.add, null, 'New Block'),
          _styledButton(Icons.publish, null, 'Import'),
          _styledButton(null,
              'assets/images/eraser-icon.svg',  // SVG asset path
              'Logo',                           // Label
              (){
                context.read<StateManagerModel>().updateCurrentState(AppState.erasing);
              }
            ),
          _styledButton(Icons.highlight_alt, null, 'Lasso',
          (){
            print("lasso started");
            context.read<StateManagerModel>().updateCurrentState(AppState.lassoing);
          }),
          _styledButton(Icons.open_in_full, null, 'Resize'),
        ],
      ),
    );
  }

  // Method to style each button
  Widget _styledButton(IconData? icon, String? svgAssetPath, String label, [void Function()? delegatedOnPressed]) {
    return Container(
      margin: const EdgeInsets.fromLTRB(0, 0, 7, 0),  // Margin outside the button
      child: SizedBox(
        width: 40,  // Set button width
        height: 40,  // 
        child: ElevatedButton(
          onPressed: delegatedOnPressed ?? (){

          },
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.all(1.0),  // Padding inside the button
            backgroundColor: Colors.white,  // Button background color
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.0),  // Rounded corners
            ),
            elevation: 4,  // Add shadow for depth
          ),
          child: Column( children: [
            // Conditionally render either an Icon or SvgPicture based on the parameters
            if (icon != null) ...[ // Display Icon if IconData is passed
              Icon(icon, size: 36.0),  
            ] 
            else if (svgAssetPath != null) ...[  // Display SvgPicture if an SVG asset path is passed
              SvgPicture.asset(
                svgAssetPath,
                width: 30,
                height: 30,
              ), 
              ],
            ]
            )
        ),
      ),
    );
  }
}

class _MiddleView extends StatefulWidget {
  final bool isDrawingMode;  // Flag to indicate whether it's drawing mode
  final bool isZoomingMode; 

  const _MiddleView({required this.isDrawingMode, required this.isZoomingMode});

  @override
  State<_MiddleView> createState() => _MiddleViewState();
}

class _MiddleViewState extends State<_MiddleView> {
  //List<Offset> points = [];  // Store the points where the user drags
  Offset totalPanOffset = Offset.zero;
  final TransformationController  _transformationController = TransformationController();
  double eraserRadius = 15.0;


  int foundPathIndex = -1; 
  List<List<Offset>> paths = [];
  List<Offset> currentPath = [];
  List<Offset> selectedPoints = []; //track selected lines within the lasso area
  List<Offset> lassoPath = []; //track lasso drawing 

  bool isMovingPoints = false; // Track if points are being moved
  Offset initialDragOffset = Offset.zero; // Track the initial drag start point

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
        if (widget.isZoomingMode) {
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
              //padding: const EdgeInsets.all(8),
              child: (() {
                // print('Current points:');
                //   for (var point in points) {
                //     print(point); // Print each point individually
                //   }// Print points to console
                return CustomPaint(
                  painter: DrawingPainter(paths, currentPath, selectedPoints, lassoPath),  // Pass the points to the painter
                  size: const Size(1000, 1000),
                );
              })(), 
            )
          : GestureDetector( // Drawing mode is enabled 
              onPanStart: (details) {
                setState(() {
                  if(currentState == AppState.drawing){
                    currentPath = [details.localPosition];
                  }else if(currentState == AppState.lassoing){
                    if(selectedPoints.isNotEmpty){
                      // Start moving points if any are selected
                      isMovingPoints = true;
                      initialDragOffset = details.localPosition;
                    }else{
                      lassoPath = [details.localPosition];
                    } 
                  }
                });
              },
              onPanUpdate: (details) {
                //if (widget.isDrawingMode) {
                  if(currentState == AppState.drawing){
                  setState(() {
                    RenderBox renderBox = context.findRenderObject() as RenderBox;

                    Matrix4 matrix = _transformationController.value;
                    
                    Offset localPosition = renderBox.globalToLocal(details.globalPosition);
                    localPosition = _applyMatrixToPoint(localPosition, matrix);
                    //points.add(localPosition);  // Add the current drag position to the list
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

                    if (isMovingPoints && selectedPoints.isNotEmpty){ //
                        Offset delta = details.localPosition - initialDragOffset;
                      for (int i = 0; i < paths[foundPathIndex].length; i++) {
                        paths[foundPathIndex][i] = paths[foundPathIndex][i] + delta;
                      }
                      initialDragOffset = details.localPosition; // Update the drag point
                    }else{
                      RenderBox renderBox = context.findRenderObject() as RenderBox;
                      Offset localPosition = renderBox.globalToLocal(details.globalPosition);
                      //lassoPoints.add(localPosition);  // Store points for the lasso trail
                      lassoPath.add(localPosition);
                    }
                  });
                }
              },
              onPanEnd: (details) {
                if (currentState == AppState.lassoing ) {

                  // Check if lasso is closed or delete it if not
                  // if (!isLassoClosed()) {
                  //   setState(() {
                  //     lassoPoints.clear();  // Clear the lasso if not closed
                  //   });
                  //   print('Lasso not closed, clearing points');
                  // } else {
                  //   // Optionally handle any other logic when the lasso is properly closed
                  //   setState(() {
                  //     // Use the lasso if needed, e.g., selecting points inside the lasso
                  //     selectedPoints = _getSelectedLines(createLassoPath());
                  //   });
                  //   print('Lasso closed, selecting points');
                  // }
                   // Finalize the lasso
                  print('isMovingPoints $isMovingPoints');
                  if (isMovingPoints) {
                  // Stop moving points
                    isMovingPoints = false;
                  }else{
                    selectPointsInsideLasso();
                    lassoPath = []; // Clear lasso after selection
                  }
                }
                else if (widget.isDrawingMode) {
                  setState(() {
                    //points.add(const Offset(-1, -1));  // Add a sentinel value to indicate a stroke end
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
                      painter: DrawingPainter(paths, currentPath, selectedPoints, lassoPath),
                      size: const Size(1000, 1000),
                    ),
                    // CustomPaint(  //old version of drawing lines 
                    //   painter: _CanvasPainter(points: points),
                    //   size: const Size(1000, 1000),
                    // ),
                    // CustomPaint(
                    //   painter: _LassoCreater(
                    //     selectedPoints: selectedPoints, 
                    //     lassoPath: createLassoPath(),
                    //   ),
                    //   size: const Size(1000, 1000),
                    // ),
                    
                  ],
                ) 
              )
            ),
    );
  }

  // bool isLassoClosed() {
  //   if (lassoPoints.length > 2) {
  //     return (lassoPoints.first - lassoPoints.last).distance < 10.0;  // Threshold to close lasso
  //   }
  //   return false;
  // }

  void selectPointsInsideLasso() {

    //reset 
    foundPathIndex = -1;
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
          //print('isApointNotBelong $isApointNotBelong : $i');
          //isApointNotBelong = false;
          continue; // If a point is outside, no need to check further in this pathList, go to next path
        }
        //start count the number of point exist in paths[i] that belongs to lasso area
        else{
          countPointInLassoErea++;
        }

      }
      //handle the case where no path was found
      // If all points belong to the lasso, mark the pathList and store the index
      //print('countPointInLassoErea $i : $countPointInLassoErea, ${pathList.length}');

      if (countPointInLassoErea == pathList.length) {
        selectedPoints = List.from(pathList); // Copy the pathList to selectedPoints
        foundPathIndex = i; // Store the indexof the found path

        if (foundPathIndex == -1) {
          print("No path fully inside the lasso.");
          //if no path was found then we need to remove lasso's path 
        } else {
          print("Path found at index: $foundPathIndex"); // of course will not get printed 
        }
        break; // Stop after finding the first matching path
      }

      

    }

  }


  // Path createLassoPath() {
  //   Path path = Path();
  //   if (lassoPoints.isNotEmpty) {
  //     path.moveTo(lassoPoints.first.dx, lassoPoints.first.dy);
  //     for (var point in lassoPoints) {
  //       path.lineTo(point.dx, point.dy);
  //     }
  //     if (isLassoClosed()) {
  //       path.close();  // Close the lasso if necessary
  //     }
  //   }
  //   return path;
  // }

  // Check which lines are inside the lasso area (both start and end of the line must be inside)
  // List<Offset> _getSelectedLines(Path lassoPath) {
  //   List<Offset> selected = [];
  //   for (int i = 0; i < points.length - 1; i++) {
  //     if (points[i] != const Offset(-1, -1) && points[i + 1] != const Offset(-1, -1)) {
  //       if (lassoPath.contains(points[i]) && lassoPath.contains(points[i + 1])) {
  //         selected.add(points[i]);     // Add both start and end points to the selected list
  //         selected.add(points[i + 1]); // Add the end point
  //       }
  //     }
  //   }
  //   return selected;  // Return selected points within the lasso area
  // }
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
class DrawingPainter extends CustomPainter {
  final List<List<Offset>> paths;
  final List<Offset> currentPath;
  final List<Offset> selectedPoints;
  final List<Offset> lassoPath;

  DrawingPainter(this.paths, this.currentPath, this.selectedPoints, this.lassoPath);

  @override
  void paint(Canvas canvas, Size size) {
    // Draw previous paths
    for (var path in paths) {
      if (path.isNotEmpty) {
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
    final selectedPaint = Paint()
      ..color = Colors.red
      ..style = PaintingStyle.fill;

    for (var point in selectedPoints) {
      canvas.drawCircle(point, 5.0, selectedPaint);
    }

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