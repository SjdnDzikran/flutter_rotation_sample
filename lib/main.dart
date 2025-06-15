import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:dynamic_color/dynamic_color.dart';
import 'dart:async';
import 'dart:math' show pi;

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]).then((_) {
    runApp(const MyApp());
  });
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  ThemeMode _themeMode = ThemeMode.system;

  void _toggleThemeMode(bool isDarkMode) {
    setState(() {
      _themeMode = isDarkMode ? ThemeMode.dark : ThemeMode.light;
    });
  }

  @override
  Widget build(BuildContext context) {
    return DynamicColorBuilder(
      builder: (ColorScheme? lightDynamic, ColorScheme? darkDynamic) {
        ColorScheme lightColorScheme;
        ColorScheme darkColorScheme;

        if (lightDynamic != null && darkDynamic != null) {
          lightColorScheme = lightDynamic.harmonized();
          darkColorScheme = darkDynamic.harmonized();
        } else {
          // Otherwise, use a fallback color scheme.
          lightColorScheme = ColorScheme.fromSeed(seedColor: Colors.deepPurple);
          darkColorScheme = ColorScheme.fromSeed(
            seedColor: Colors.deepPurple,
            brightness: Brightness.dark,
          );
        }

        return MaterialApp(
          title: 'Flutter Demo',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            colorScheme: lightColorScheme,
            useMaterial3: true,
          ),
          darkTheme: ThemeData(
            colorScheme: darkColorScheme,
            useMaterial3: true,
          ),
          themeMode: _themeMode, // Apply the theme mode
          home: MyHomePage(
            title: 'Flutter Demo Home Page',
            onThemeModeChanged: _toggleThemeMode,
          ),
        );
      },
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title, required this.onThemeModeChanged});

  final String title;
  final ValueChanged<bool> onThemeModeChanged;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;
  double _rotationAngle = 0.0;
  StreamSubscription<AccelerometerEvent>? _accelerometerSubscription;

  @override
  void initState() {
    super.initState();
    _accelerometerSubscription =
        accelerometerEventStream(samplingPeriod: SensorInterval.uiInterval)
            .listen((AccelerometerEvent event) {
      setState(() {
        // Determine rotation based on accelerometer data
        // Assuming portrait up is 0 degrees
        // Landscape left (home button right) is -pi/2
        // Landscape right (home button left) is pi/2
        // Portrait down (upside down) is pi

        // Threshold to determine if the device is mostly horizontal or vertical
        const double threshold = 7.0; // Adjust this value as needed

        if (event.y.abs() > threshold && event.x.abs() < threshold) {
          // Portrait or Portrait Down
          _rotationAngle = 0.0; // Always keep upright relative to app's portrait
        } else if (event.x.abs() > threshold && event.y.abs() < threshold) {
          // Landscape left or Landscape right (opposite rotation)
          if (event.x < 0) {
            _rotationAngle = -pi / 2; // Opposite of Landscape right (home button left)
          } else {
            _rotationAngle = pi / 2; // Opposite of Landscape left (home button right)
          }
        }
        // If neither condition is met, it means the device is flat or in an intermediate state.
        // In this case, _rotationAngle retains its last value, or you could set it to 0.0
        // For now, we'll let it retain its last value to avoid jitter when flat.
      });
    });
  }

  @override
  void dispose() {
    _accelerometerSubscription?.cancel();
    super.dispose();
  }

  void _incrementCounter() {
    setState(() {
      _counter++;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
        actions: [
          Switch(
            value: Theme.of(context).brightness == Brightness.dark,
            onChanged: widget.onThemeModeChanged,
            activeColor: Theme.of(context).colorScheme.onPrimary,
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text('You have pushed the button this many times:'),
            AnimatedRotation(
              turns: _rotationAngle / (2 * pi), // Convert radians to turns
              duration: const Duration(milliseconds: 300), // Animation duration
              child: Text(
                '$_counter',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _incrementCounter,
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ),
    );
  }
}
