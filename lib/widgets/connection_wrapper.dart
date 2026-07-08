import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';

class ConnectionWrapper extends StatefulWidget {
  final Widget child;
  const ConnectionWrapper({super.key, required this.child});

  @override
  State<ConnectionWrapper> createState() => _ConnectionWrapperState();
}

class _ConnectionWrapperState extends State<ConnectionWrapper> {
  bool _isOnline = true;
  late Stream<bool> _connectionStream;

  @override
  void initState() {
    super.initState();
    _checkInitialConnection();
    _setupConnectionStream();
  }

  Future<void> _checkInitialConnection() async {
    try {
      final isConnected = await InternetConnectionChecker().hasConnection;
      if (mounted) {
        setState(() => _isOnline = isConnected);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isOnline = false);
      }
    }
  }

  void _setupConnectionStream() {
    _connectionStream = Connectivity().onConnectivityChanged.asyncMap((_) async {
      try {
        return await InternetConnectionChecker().hasConnection;
      } catch (e) {
        return false;
      }
    });
    
    _connectionStream.listen((isOnline) {
      if (mounted) {
        setState(() => _isOnline = isOnline);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (!_isOnline) _buildOfflineBanner(),
        Expanded(child: widget.child),
      ],
    );
  }

  Widget _buildOfflineBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(8),
      color: const Color(0xFFE63950),
      child: const Text(
        'No internet connection',
        textAlign: TextAlign.center,
        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      ),
    );
  }
}
