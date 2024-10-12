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
      padding: EdgeInsets.all(8.0),
      color: Colors.blueAccent,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          ElevatedButton(
            onPressed: () => setDrawingMode(true),  // Enable drawing mode
            child: Text('Draw'),
          ),
          ElevatedButton(
            onPressed: () => setDrawingMode(false),  // Enable typing mode
            child: Text('Type'),
          ),
        ],
      ),
    );
  }
}

class _MiddleView extends StatelessWidget {
  final bool isDrawingMode;

  const _MiddleView({required this.isDrawingMode});

  @override
  Widget build(BuildContext context) {
    return InteractiveViewer(
      boundaryMargin: EdgeInsets.all(double.infinity),
      minScale: 0.5,
      maxScale: 4.0,
      child: Container(
        color: const Color.fromARGB(255, 203, 174, 174),
        child: GestureDetector(
          onPanUpdate: (details) {
            if (isDrawingMode) {
              // Handle drawing mode
            }
          },
          onTapDown: (details) {
            if (!isDrawingMode) {
              // Handle typing mode
            }
          },
          child: CustomPaint(
            painter: _CanvasPainter(),  // Custom painter for drawing
            size: Size(1000, 1000),
          ),
        ),
      ),
    );
  }
}


// class _TopNav extends StatefulWidget {
//   @override
//   State<_TopNav> createState() => _TopNavState();
// }

// class _MiddleView extends StatefulWidget {
//   @override
//   State<_MiddleView> createState() => _MiddleViewState();
// }


class _CanvasPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Drawing logic, e.g., rendering strokes, lines, etc.
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return true;  // Repaint whenever the drawing state changes
  }
}








// class _MyHomePageState extends State<MyHomePage> {
//   int _counter = 0;

//   void _incrementCounter() {
//     setState(() {
//       _counter++;
//     });
//   }

//   @override
//   Widget build(BuildContext context) {
//     // This method is rerun every time setState is called, for instance as done
//     // by the _incrementCounter method above.
//     //
//     // The Flutter framework has been optimized to make rerunning build methods
//     // fast, so that you can just rebuild anything that needs updating rather
//     // than having to individually change instances of widgets.
//     return Scaffold(
//       appBar: AppBar(
   
//         backgroundColor: Theme.of(context).colorScheme.inversePrimary,
//         // Here we take the value from the MyHomePage object that was created by
//         // the App.build method, and use it to set our appbar title.
//         title: Text(widget.title),
//       ),
//       body: Center(

//         child: Column(
 
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: <Widget>[
//             const Text(
//               'You have pushed the button this many times:',
//             ),
//             Text(
//               '$_counter',
//               style: Theme.of(context).textTheme.headlineMedium,
//             ),
//           ],
//         ),
//       ),
//       floatingActionButton: FloatingActionButton(
//         onPressed: _incrementCounter,
//         tooltip: 'Increment',
//         child: const Icon(Icons.add),
//       ), // This trailing comma makes auto-formatting nicer for build methods.
//     );
//   }
// }