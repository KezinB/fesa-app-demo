import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:usb_serial/usb_serial.dart';

void main() {
  runApp(const FeSaApp());
}

class FeSaApp extends StatelessWidget {
  const FeSaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FeSa Diagnostic App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF0F172A),
        cardColor: const Color(0xFF1E293B),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF14B8A6),
          secondary: Color(0xFF3B82F6),
        ),
      ),
      home: const FeSaDashboard(),
    );
  }
}

class FeSaDashboard extends StatefulWidget {
  const FeSaDashboard({super.key});

  @override
  State<FeSaDashboard> createState() => _FeSaDashboardState();
}

class _FeSaDashboardState extends State<FeSaDashboard> {
  UsbPort? _port;
  String _status = "DISCONNECTED";
  bool _isConnected = false;
  
  // Diagnostic Metrics
  double _riskPct = 0.0;
  double _ferritin = 28.5;
  double _rStrip = 45.0;
  double _vOut = 1650.0;
  int _rawAdc = 32768;

  StreamSubscription<Uint8List>? _subscription;
  String _incomingBuffer = "";

  @override
  void initState() {
    super.initState();
    UsbSerial.usbEventStream?.listen((UsbEvent event) {
      _getPorts();
    });
    _getPorts();
  }

  void _getPorts() async {
    List<UsbDevice> devices = await UsbSerial.listDevices();
    if (devices.isEmpty) {
      setState(() {
        _status = "NO USB DEVICE DETECTED";
        _isConnected = false;
      });
    }
  }

  Future<bool> _connect() async {
    List<UsbDevice> devices = await UsbSerial.listDevices();
    if (devices.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No USB device connected over OTG cable')),
      );
      return false;
    }

    UsbDevice device = devices.first;
    _port = await device.create();

    bool openResult = await _port!.open();
    if (!openResult) {
      setState(() => _status = "FAILED TO OPEN PORT");
      return false;
    }

    await _port!.setDtr(true);
    await _port!.setRts(true);
    await _port!.setPortParameters(
      115200,
      UsbPort.DATABITS_8,
      UsbPort.STOPBITS_1,
      UsbPort.PARITY_NONE,
    );

    _subscription = _port!.inputStream?.listen((Uint8List event) {
      String dataStr = String.fromCharCodes(event);
      _incomingBuffer += dataStr;
      List<String> lines = _incomingBuffer.split('\n');
      _incomingBuffer = lines.removeLast(); // Keep incomplete tail

      for (String line in lines) {
        if (line.trim().startsWith('{')) {
          _parseJson(line.trim());
        }
      }
    });

    setState(() {
      _isConnected = true;
      _status = "READY";
    });
    return true;
  }

  void _parseJson(String jsonStr) {
    try {
      Map<String, dynamic> data = jsonDecode(jsonStr);
      setState(() {
        if (data.containsKey('state')) _status = data['state'].toString();
        if (data.containsKey('status')) _status = data['status'].toString();
        if (data.containsKey('risk_pct')) _riskPct = (data['risk_pct'] as num).toDouble();
        if (data.containsKey('ferritin_ng_ml')) _ferritin = (data['ferritin_ng_ml'] as num).toDouble();
        if (data.containsKey('r_strip_ohm')) _rStrip = (data['r_strip_ohm'] as num).toDouble() / 1000.0;
        if (data.containsKey('v_out_mv')) _vOut = (data['v_out_mv'] as num).toDouble();
        if (data.containsKey('raw_adc')) _rawAdc = (data['raw_adc'] as num).toInt();
      });
    } catch (e) {
      // JSON parse ignore
    }
  }

  void _disconnect() async {
    _subscription?.cancel();
    await _port?.close();
    setState(() {
      _isConnected = false;
      _status = "DISCONNECTED";
    });
  }

  @override
  void dispose() {
    _disconnect();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🩸 FeSa Salivary Anemia Reader'),
        centerTitle: true,
        backgroundColor: const Color(0xFF1E293B),
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Connect Header Button
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _isConnected ? Colors.redAccent : const Color(0xFF14B8A6),
                        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: _isConnected ? _disconnect : _connect,
                      icon: Icon(_isConnected ? Icons.power_settings_new : Icons.usb),
                      label: Text(
                        _isConnected ? 'Disconnect Device' : 'Connect FeSa USB Reader',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      decoration: BoxDecoration(
                        color: _status == "MEASURING"
                            ? Colors.amber.withOpacity(0.2)
                            : (_status == "COMPLETE" ? Colors.green.withOpacity(0.2) : Colors.blue.withOpacity(0.2)),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        _status,
                        style: TextStyle(
                          color: _status == "MEASURING"
                              ? Colors.amber
                              : (_status == "COMPLETE" ? Colors.green : Colors.tealAccent),
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Key Metrics Card
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    Card(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          children: [
                            const Text('ESTIMATED ANEMIA RISK SCORE', style: TextStyle(color: Colors.grey, fontSize: 12)),
                            const SizedBox(height: 8),
                            Text(
                              '${_riskPct.toStringAsFixed(1)}%',
                              style: const TextStyle(fontSize: 54, fontWeight: FontWeight.w900, color: Color(0xFF14B8A6)),
                            ),
                            const Divider(height: 32, color: Colors.white10),
                            const Text('SALIVARY FERRITIN ESTIMATE', style: TextStyle(color: Colors.grey, fontSize: 12)),
                            const SizedBox(height: 4),
                            Text(
                              '${_ferritin.toStringAsFixed(1)} ng/mL',
                              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.greenAccent),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Grid Metrics
                    Row(
                      children: [
                        Expanded(
                          child: _buildMetricTile('Strip Resistance (R_strip)', '${_rStrip.toStringAsFixed(1)} kΩ'),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildMetricTile('AFE Voltage (V_out)', '${_vOut.toStringAsFixed(0)} mV'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _buildMetricTile('Raw 16-Bit ADC', '$_rawAdc'),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildMetricTile('Sample Type', 'Saliva (30 µL)'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricTile(String label, String value) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey), textAlign: TextAlign.center),
            const SizedBox(height: 6),
            Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
