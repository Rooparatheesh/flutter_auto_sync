import 'dart:async'; // Add this to the top of your file
import 'package:flutter/material.dart';
import 'package:flutter_auto_sync/flutter_auto_sync.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // 1. Initialize normal foreground/background sync
  await AutoSyncManager.init();
  
  // 2. Initialize native killed-state background sync using Workmanager
  AutoSyncManager.initializeBackgroundSync();
  
  runApp(const MyApp());
}
class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  int _requestCounter = 0;

  void _addManualRequests() async {
    for (int i = 0; i < 100; i++) {
      _requestCounter++;
      
      await AutoSyncManager.addToQueue(
        endpoint: "https://jsonplaceholder.typicode.com/posts",
        method: "POST",
        data: {
          "name": "Roopa",
          "manual_id": _requestCounter,
          "timestamp": DateTime.now().toIso8601String(),
        },
      );
    }
    print("Manually added 100 requests to queue");
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text("Manual Sync Example")),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                "Turn off Wi-Fi/Data and tap the button\nto manually add 100 requests.",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 30),
              
              ElevatedButton.icon(
                onPressed: _addManualRequests,
                icon: const Icon(Icons.add_to_queue),
                label: const Text("Add 100 Requests"),
              ),
              const SizedBox(height: 30),

              // Shows how many items are currently in the offline queue
              StreamBuilder<int>(
                stream: AutoSyncManager.pendingItemsStream,
                initialData: 0,
                builder: (context, snapshot) {
                  return Text(
                    "${snapshot.data} items in offline queue",
                    style: const TextStyle(fontSize: 24, color: Colors.blue, fontWeight: FontWeight.bold),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
