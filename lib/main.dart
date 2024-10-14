import 'package:flutter/material.dart';
import 'package:vector_math/vector_math_64.dart' as vmath;
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'package:cupertino_icons/cupertino_icons.dart';

enum AppState {
  drawing,
  lassoing,
  erasing,
  resizing,
  none,
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
          _styledButton(Icons.highlight_alt, null, 'Lasso'),
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
          // child: Text(
          //   label,
          //   style: const TextStyle(
          //     fontSize: 14.0,  // Text size
          //     color: Colors.black,  // Text color
          //   ),
          // ),
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
  List<Offset> points = [];  // Store the points where the user drags
  Offset totalPanOffset = Offset.zero;
  final TransformationController  _transformationController = TransformationController();

  double eraserRadius = 15.0;



  @override
  Widget build(BuildContext context) {

    final AppState currentState = context.watch<StateManagerModel>().currentState; 

     return InteractiveViewer(
      transformationController: _transformationController,
      boundaryMargin: const EdgeInsets.all(double.infinity),  // Allow panning without limits
      minScale: 0.2,  // Minimum zoom scale
      maxScale: 4.0,  // Maximum zoom scale
      onInteractionStart: (details) {
        if (widget.isZoomingMode) {
          print('Zoom started' );
          
        }
      },
       onInteractionUpdate: (details) {
        if (widget.isZoomingMode) {
          // Use focalPointDelta to track panning or zoom changes
          setState(() {
            totalPanOffset += details.focalPointDelta;
          });
          print('Zoom scale: ${details.scale}');
        }
      },
      onInteractionEnd: (details) {
        if (widget.isZoomingMode) {
          print('Zoom ended');
        }
      },
      child: widget.isZoomingMode  // Disable gesture detection when zooming
          ? Container( //when zooming Mode is enabled 
              color: const Color.fromARGB(255, 223, 188, 210),
              //padding: const EdgeInsets.all(8),
              child: CustomPaint(
                painter: _CanvasPainter(points: points),  // Pass the points to the painter
                size: const Size(1000, 1000),
              ),
            )
          : GestureDetector( // Drawing mode is enabled 
              onPanUpdate: (details) {
                //if (widget.isDrawingMode) {
                  if(currentState == AppState.drawing){
                  setState(() {
                    RenderBox renderBox = context.findRenderObject() as RenderBox;

                    Matrix4 matrix = _transformationController.value;
                    
                    Offset localPosition = renderBox.globalToLocal(details.globalPosition);
                    localPosition = _applyMatrixToPoint(localPosition, matrix);
                    points.add(localPosition);  // Add the current drag position to the list
                  });
                }else if(currentState == AppState.erasing){ // Perform erasing
                  
                   setState(() {
                    _erasePoint(details.globalPosition);  
                  });
                }
              },
              onPanEnd: (details) {
                if (widget.isDrawingMode) {
                  setState(() {
                    points.add(const Offset(-1, -1));  // Add a sentinel value to indicate a stroke end
                  });
                }
              },
              child: ColoredBox(
                color: const Color.fromARGB(255, 223, 188, 210),  // Background color
                child: CustomPaint(
                  painter: _CanvasPainter(points: points),
                  size: const Size(1000, 1000),
                ),
              )
            ),
    );
  }

  Offset _applyMatrixToPoint(Offset point, Matrix4 matrix) {
    // Apply the inverse of the transformation matrix
    Matrix4 inverseMatrix = Matrix4.inverted(matrix);
    final vmath.Vector3 transformed3 = inverseMatrix.transform3(vmath.Vector3(point.dx, point.dy, 0));
    return Offset(transformed3.x, transformed3.y);
  }

  // Erase points that are near the eraser's position
  void _erasePoint(Offset globalPosition) {
    RenderBox renderBox = context.findRenderObject() as RenderBox;
    Offset localPosition = renderBox.globalToLocal(globalPosition);

    print("local pos: ${localPosition}");
    points.removeWhere((point) => (point - localPosition).distance < eraserRadius);
  }

}




class _CanvasPainter extends CustomPainter {
  final List<Offset> points;  // List of points to draw

  _CanvasPainter({required this.points});

  @override
  void paint(Canvas canvas, Size size) {
    Paint paint = Paint()
      ..color = Colors.blue
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 5.0;

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