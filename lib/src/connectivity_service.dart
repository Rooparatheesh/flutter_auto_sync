import 'package:connectivity_plus/connectivity_plus.dart';

class ConnectivityService {
  static Stream<List<ConnectivityResult>> get connectionStream {
    return Connectivity().onConnectivityChanged;
  }

  static Future<bool> isOnline() async {
    final result = await Connectivity().checkConnectivity();
    // ignore: unrelated_type_equality_checks
    return result != ConnectivityResult.none;
  }
}
