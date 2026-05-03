import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/system_controller.dart';

class DualBandSyncCard extends StatefulWidget {
  const DualBandSyncCard({super.key});

  @override
  State<DualBandSyncCard> createState() => _DualBandSyncCardState();
}

class _DualBandSyncCardState extends State<DualBandSyncCard> {
  // true = WiFi (IP based), false = Bluetooth (Identity based)
  bool isWifiMode = true; 

  @override
  Widget build(BuildContext context) {
    final system = context.watch<SystemController>();
    final isDark = system.systemData.isDarkMode;
    
    final Color cardBg = isDark ? const Color(0xFF2C2C2C) : Colors.white;
    final Color border = isDark ? const Color(0xFF444444) : Colors.grey.shade300;
    final Color text = isDark ? Colors.white : Colors.black;
    final Color subText = isDark ? Colors.grey : Colors.grey.shade600;
    final Color accent = isDark ? const Color(0xFFEBFB7E) : const Color(0xFF0EA5E9);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: border),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 10)]
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // HEADER & MODE TOGGLE
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("NETWORK RADAR", style: TextStyle(color: accent, fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
              
              // Custom Segmented Control
              Container(
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF171717) : Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: border)
                ),
                child: Row(
                  children: [
                    InkWell(
                      onTap: () => setState(() => isWifiMode = true),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
                        decoration: BoxDecoration(
                          color: isWifiMode ? accent : Colors.transparent,
                          borderRadius: BorderRadius.circular(7)
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.wifi, size: 16, color: isWifiMode ? Colors.black : subText),
                            const SizedBox(width: 5),
                            Text("WiFi", style: TextStyle(color: isWifiMode ? Colors.black : subText, fontWeight: FontWeight.bold, fontSize: 12))
                          ],
                        ),
                      ),
                    ),
                    InkWell(
                      onTap: () => setState(() => isWifiMode = false),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
                        decoration: BoxDecoration(
                          color: !isWifiMode ? Colors.blueAccent : Colors.transparent,
                          borderRadius: BorderRadius.circular(7)
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.bluetooth, size: 16, color: !isWifiMode ? Colors.white : subText),
                            const SizedBox(width: 5),
                            Text("Bluetooth", style: TextStyle(color: !isWifiMode ? Colors.white : subText, fontWeight: FontWeight.bold, fontSize: 12))
                          ],
                        ),
                      ),
                    )
                  ],
                ),
              )
            ],
          ),
          
          const SizedBox(height: 10),
          Text(system.syncStatusMessage, style: TextStyle(color: subText, fontSize: 12, fontStyle: FontStyle.italic)),
          const SizedBox(height: 20),

          // THE DEVICE LIST
          Container(
            height: 150,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF171717) : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: border)
            ),
            child: _buildDeviceList(system, text, subText, accent),
          ),
          
          const SizedBox(height: 20),
          
          // SCAN BUTTON
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              onPressed: () {
                if (isWifiMode) {
                  system.runRadarScan();
                } else {
                  system.runBluetoothScan();
                }
              },
              icon: system.isScanning || system.isBluetoothScanning 
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2)) 
                : const Icon(Icons.radar, color: Colors.black),
              label: Text(system.isScanning || system.isBluetoothScanning ? "SCANNING..." : "INITIATE SCAN", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black, letterSpacing: 1)),
              style: ElevatedButton.styleFrom(
                backgroundColor: isWifiMode ? accent : Colors.blueAccent, 
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildDeviceList(SystemController system, Color text, Color subText, Color accent) {
    if (isWifiMode) {
      if (system.syncEngine.discoveredDevices.isEmpty) {
        return Center(child: Text("No WiFi Nodes Detected.", style: TextStyle(color: subText)));
      }
      return ListView.builder(
        itemCount: system.syncEngine.discoveredDevices.length,
        itemBuilder: (context, index) {
          String ip = system.syncEngine.discoveredDevices[index].ip;
          String name = system.syncEngine.discoveredDevices[index].name;
          return ListTile(
            leading: const Icon(Icons.computer, color: Colors.greenAccent),
            title: Text(name, style: TextStyle(color: text, fontWeight: FontWeight.bold)),
            subtitle: Text(ip, style: TextStyle(color: subText, fontSize: 10, fontFamily: 'monospace')),
            trailing: ElevatedButton(
              onPressed: () => system.syncWithDevice(ip),
              style: ElevatedButton.styleFrom(backgroundColor: accent, foregroundColor: Colors.black),
              child: const Text("SYNC", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
            ),
          );
        }
      );
    } else {
      if (system.discoveredBluetoothDevices.isEmpty) {
        return Center(child: Text("No Bluetooth Nodes Detected.", style: TextStyle(color: subText)));
      }
      return ListView.builder(
        itemCount: system.discoveredBluetoothDevices.length,
        itemBuilder: (context, index) {
          var device = system.discoveredBluetoothDevices[index];
          return ListTile(
            leading: const Icon(Icons.bluetooth_connected, color: Colors.blueAccent),
            title: Text(device['name']!, style: TextStyle(color: text, fontWeight: FontWeight.bold)),
            subtitle: Text(device['id']!, style: TextStyle(color: subText, fontSize: 10, fontFamily: 'monospace')),
            trailing: ElevatedButton(
              onPressed: () => system.syncWithBluetoothDevice(device['id']!),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent, foregroundColor: Colors.white),
              child: const Text("PAIR", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
            ),
          );
        }
      );
    }
  }
}