import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';
import 'package:riverpod/riverpod.dart';


final networkServiceProvider = Provider<NetworkService>((ref) {
  return NetworkService();
});

final networkStatusProvider = StreamProvider<bool>((ref) {
  final networkService = ref.watch(networkServiceProvider);
  return networkService.onInternetStatusChanged;
});


class NetworkManager extends ConsumerStatefulWidget {
  final Widget child;

  const NetworkManager({super.key, required this.child});

  @override
  ConsumerState<NetworkManager> createState() => _NetworkManagerState();
}

class _NetworkManagerState extends ConsumerState<NetworkManager> {
  bool _showSnackbar = false;

  @override
  Widget build(BuildContext context) {
    final networkStatus = ref.watch(networkStatusProvider);

    networkStatus.when(
      data: (hasInternet) {
        _handleNetworkChange(hasInternet);
      },
      error: (error, stack) {
        print('Network error: $error');
      },
      loading: () {},
    );

    return widget.child;
  }

  void _handleNetworkChange(bool hasInternet) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final scaffoldMessenger = ScaffoldMessenger.of(context);

      if (!hasInternet && !_showSnackbar) {
        _showSnackbar = true;
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.wifi_off, color: Colors.white),
                SizedBox(width: 8),
                Text('No Internet Connection'),
              ],
            ),
            backgroundColor: Colors.red,
            duration: Duration(days: 365),
          ),
        );
      } else if (hasInternet && _showSnackbar) {
        _showSnackbar = false;
        scaffoldMessenger.hideCurrentSnackBar();
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.wifi, color: Colors.white),
                SizedBox(width: 8),
                Text('Back Online!'),
              ],
            ),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    });
  }
}



class NetworkService {
  final Connectivity _connectivity = Connectivity();
  final InternetConnectionChecker _connectionChecker = InternetConnectionChecker();

  // Check if device has any network connection
  Future<bool> hasNetworkConnection() async {
    final result = await _connectivity.checkConnectivity();
    return result != ConnectivityResult.none;
  }

  // Check if device has actual internet access
  Future<bool> hasInternetAccess() async {
    return await _connectionChecker.hasConnection;
  }

  // Stream of internet status changes
  Stream<bool> get onInternetStatusChanged {
    return _connectionChecker.onStatusChange.map((status) {
      return status == InternetConnectionStatus.connected;
    });
  }

  // Stream of network status changes
  Stream<bool> get onNetworkStatusChanged {
    return _connectivity.onConnectivityChanged.map((result) {
      return result != ConnectivityResult.none;
    });
  }
}
