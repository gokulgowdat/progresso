import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../models/system_data.dart';

class DiscoveredVault {
  final String name;
  final String ip;
  DiscoveredVault(this.name, this.ip);
}

class SyncEngine {
  HttpServer? _tcpServer;
  RawDatagramSocket? _udpSocket;
  bool isHosting = false;
  String localIp = "Not Connected";
  
  List<DiscoveredVault> discoveredDevices = [];

  Future<void> startHosting(SystemData data) async {
    if (isHosting) return;
    try {
      // 1. Identify Local IP
      var interfaces = await NetworkInterface.list();
      for (var interface in interfaces) {
        for (var addr in interface.addresses) {
          if (addr.type == InternetAddressType.IPv4 && !addr.isLoopback) {
            localIp = addr.address;
            break;
          }
        }
      }

      // 2. Start TCP Server (The Data Tunnel on port 8080)
      _tcpServer = await HttpServer.bind(InternetAddress.anyIPv4, 8080);
      _tcpServer!.listen((HttpRequest request) {
        if (request.uri.path == '/sync') {
          request.response
            ..headers.contentType = ContentType.json
            ..write(jsonEncode(data.toJson()))
            ..close();
        } else {
          request.response..statusCode = HttpStatus.notFound..close();
        }
      });

      // 3. Start UDP Listener (The Radar Receiver on port 8081)
      _udpSocket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 8081);
      _udpSocket!.broadcastEnabled = true;
      
      _udpSocket!.listen((RawSocketEvent e) {
        if (e == RawSocketEvent.read) {
          Datagram? dg = _udpSocket!.receive();
          if (dg != null) {
            String message = utf8.decode(dg.data);
            if (message == "HUNTER_RADAR_PING") {
              // =========================================================
              // THE FIX: Shout back our exact custom Identity + Hex Tag!
              // =========================================================
              String reply = "VAULT_IDENTITY:${data.deviceName} #${data.deviceShortId}";
              _udpSocket!.send(utf8.encode(reply), dg.address, dg.port);
            }
          }
        }
      });

      isHosting = true;
    } catch (e) {
      print("Sync Engine Hosting Error: $e");
    }
  }

  // 📡 THE RADAR PING
  Future<void> scanNetwork() async {
    discoveredDevices.clear();
    RawDatagramSocket? scannerSocket;
    
    try {
      // Open a temporary socket to shout to the network
      scannerSocket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
      scannerSocket.broadcastEnabled = true;

      // Listen for anyone shouting back
      scannerSocket.listen((RawSocketEvent e) {
        if (e == RawSocketEvent.read) {
          Datagram? dg = scannerSocket!.receive();
          if (dg != null) {
            String reply = utf8.decode(dg.data);
            if (reply.startsWith("VAULT_IDENTITY:")) {
              String name = reply.split(":")[1];
              String ip = dg.address.address;
              
              // Add to the list if it's not us and not already listed
              if (ip != localIp && !discoveredDevices.any((d) => d.ip == ip)) {
                discoveredDevices.add(DiscoveredVault(name, ip));
              }
            }
          }
        }
      });

      // Blast the Ping to the entire subnet
      scannerSocket.send(
        utf8.encode("HUNTER_RADAR_PING"), 
        InternetAddress("255.255.255.255"), 
        8081
      );

      // Keep the radar spinning for exactly 3 seconds to catch replies
      await Future.delayed(const Duration(seconds: 3));
      
    } catch (e) {
      print("Radar Scanner Error: $e");
    } finally {
      scannerSocket?.close();
    }
  }

  Future<SystemData?> fetchRemoteData(String ipAddress) async {
    try {
      final response = await http.get(Uri.parse('http://$ipAddress:8080/sync')).timeout(const Duration(seconds: 5));
      if (response.statusCode == 200) {
        return SystemData.fromJson(jsonDecode(response.body));
      }
    } catch (e) {
      return null;
    }
    return null;
  }
}