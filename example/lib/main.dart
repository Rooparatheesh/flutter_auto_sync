import 'package:flutter/material.dart';
import 'package:flutter_auto_sync/flutter_auto_sync.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AutoSyncManager.init();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text("Auto Sync Example")),
        body: Center(
          child: ElevatedButton(
            onPressed: () async {
              await AutoSyncManager.addToQueue(
                endpoint: "https://api.example.com/data",
                data: {"name": "Roopa"},
              );
            },
            child: const Text("Add Sync Job"),
          ),
        ),
      ),
    );
  }
}
