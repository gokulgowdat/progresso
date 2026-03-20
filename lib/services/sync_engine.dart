import 'dart:io';
import 'dart:convert';
import '../models/system_data.dart';

class SyncEngine {
  HttpServer? _server;
  bool isHosting = false;
  String localIp = "Scanning...";
  SystemData? _currentData;

  SyncEngine() {
    _determineLocalIp();
  }

  // Automatically finds your machine's true local Wi-Fi IP
  Future<void> _determineLocalIp() async {
    try {
      for (var interface in await NetworkInterface.list()) {
        for (var addr in interface.addresses) {
          if (addr.type == InternetAddressType.IPv4 && !addr.isLoopback) {
            localIp = addr.address;
            return;
          }
        }
      }
    } catch (e) {
      localIp = "127.0.0.1";
    }
  }

  // THE FIX: Binding to anyIPv4 allows the phone to connect!
  Future<void> startHosting(SystemData data) async {
    _currentData = data;
    
    if (isHosting) return; // Server is already awake

    try {
      // 0.0.0.0 tells the PC to accept connections from the local router
      _server = await HttpServer.bind(InternetAddress.anyIPv4, 45455);
      isHosting = true;
      
      _server!.listen((HttpRequest request) {
        if (request.uri.path == '/sync') {
          request.response
            ..statusCode = HttpStatus.ok
            ..headers.contentType = ContentType.json
            ..headers.add("Access-Control-Allow-Origin", "*") // Prevent CORS issues
            ..write(jsonEncode(_currentData!.toJson()))
            ..close();
        } else {
          request.response
            ..statusCode = HttpStatus.notFound
            ..close();
        }
      });
    } catch (e) {
      print("Host error: $e");
    }
  }

  // The Client function used by the device asking for data
  Future<SystemData?> fetchRemoteData(String targetIp) async {
    try {
      final client = HttpClient();
      client.connectionTimeout = const Duration(seconds: 5);
      
      final request = await client.getUrl(Uri.parse('http://$targetIp:45455/sync'));
      final response = await request.close();
      
      if (response.statusCode == HttpStatus.ok) {
        final responseBody = await response.transform(utf8.decoder).join();
        return SystemData.fromJson(jsonDecode(responseBody));
      }
    } catch (e) {
      print("Sync error: $e");
    }
    return null;
  }
}