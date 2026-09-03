import 'package:connectivity_plus/connectivity_plus.dart';

/// Service for handling internet connectivity monitoring.
class ConnectivityService {
  /// Returns a stream of connectivity changes.
  static Stream<List<ConnectivityResult>> get connectionStream {
    return Connectivity().onConnectivityChanged;
  }

  /// Checks if the device is currently online.
  static Future<bool> isOnline() async {
    final result = await Connectivity().checkConnectivity();
    // In connectivity_plus ^6.0.0 and above, it returns a List<ConnectivityResult>
    return !result.contains(ConnectivityResult.none) && result.isNotEmpty;
  }
}
