import 'package:flutter/material.dart';
import 'package:freedompay/freedompay.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final _freedompayPlugin = Freedompay();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('Plugin example app')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              'Freedompay plugin is ready.\n'
              'Call initialize() with your merchant credentials before starting a payment flow.\n\n'
              'Instance: ${_freedompayPlugin.runtimeType}',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }
}
