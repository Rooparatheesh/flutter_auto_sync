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
    // ignore: unrelated_type_equality_checks
    return result != ConnectivityResult.none;
  }
}
