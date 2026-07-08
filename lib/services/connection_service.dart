// lib/services/connection_service.dart
import 'package:internet_connection_checker/internet_connection_checker.dart';

class ConnectionService {
  static final ConnectionService _instance = ConnectionService._internal();
  factory ConnectionService() => _instance;
  ConnectionService._internal();

  final InternetConnectionChecker _connectionChecker = InternetConnectionChecker();

  Stream<bool> get connectionStream => _connectionChecker.onStatusChange
      .map((status) => status == InternetConnectionStatus.connected);

  Future<bool> get isConnected async => await _connectionChecker.hasConnection;
}
