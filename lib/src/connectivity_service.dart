import 'package:connectivity_plus/connectivity_plus.dart';

class ConnectivityService {
  static Stream<ConnectivityResult> get connectionStream {
    return Connectivity().onConnectivityChanged;
  }

  static Future<bool> isOnline() async {
    final result = await Connectivity().checkConnectivity();
    return result != ConnectivityResult.none;
  }
}
