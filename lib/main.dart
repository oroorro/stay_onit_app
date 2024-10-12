import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Project Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.white10),
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


  void setDrawingMode(bool enabled) {
    setState(() {
      isDrawingMode = enabled;
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
          _TopNav(setDrawingMode: setDrawingMode),  // Pass callback to _TopNav
          Expanded(
            child: _MiddleView(isDrawingMode: isDrawingMode),  // Pass state to _MiddleView
          ),
        ],
      ),
    );
  }
}




class _TopNav extends StatelessWidget {
  final Function(bool) setDrawingMode;

  const _TopNav({required this.setDrawingMode});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8.0),
      color: Colors.blueAccent,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          ElevatedButton(
            onPressed: () => {},  
            child: const Text('Home'),
          ),
          ElevatedButton(
            onPressed: () => {},  
            child: const Text('Import'),
          ),
          ElevatedButton(
            onPressed: () => setDrawingMode(true),  // Enable drawing mode
            child: const Text('Draw'),
          ),
          ElevatedButton(
            onPressed: () => setDrawingMode(false),  // Enable typing mode
            child: const Text('Type'),
          ),
          ElevatedButton(
            onPressed: () => {},  // Enable drawing mode
            child: const Text('New'),
          ),
          ElevatedButton(
            onPressed: () => {},  
            child: const Text('Resize'),
          ),
        ],
      ),
    );
  }
}

class _MiddleView extends StatefulWidget {
  final bool isDrawingMode;  // Flag to indicate whether it's drawing mode

  const _MiddleView({required this.isDrawingMode});

  @override
  State<_MiddleView> createState() => _MiddleViewState();
}

class _MiddleViewState extends State<_MiddleView> {
  List<Offset> points = [];  // Store the points where the user drags

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanUpdate: (details) {
        if (widget.isDrawingMode) {
          setState(() {
            RenderBox renderBox = context.findRenderObject() as RenderBox;
            Offset localPosition = renderBox.globalToLocal(details.globalPosition);
            points.add(localPosition);  // Add the current drag position to the list
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
      child: CustomPaint(
        painter: _CanvasPainter(points: points),  // Pass the points to the painter
        size: Size.infinite,
      ),
    );
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