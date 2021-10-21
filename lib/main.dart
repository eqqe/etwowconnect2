import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:permission_handler/permission_handler.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'E-Twow GT SE Unofficial App',
      theme: ThemeData(
        primarySwatch: Colors.yellow,
      ),
      home: MyHomePage(title: 'E-Twow GT SE Unofficial App'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final _ble = FlutterReactiveBle();
  final _serviceId = Uuid.parse("0000ffe0-0000-1000-8000-00805f9b34fb");
  final _serviceIdRead = Uuid.parse("0000ffe1-0000-1000-8000-00805f9b34fb");
  final _characteristicId = Uuid.parse("0000ffe1-0000-1000-8000-00805f9b34fb");
  late StreamSubscription<DiscoveredDevice> listener;
  bool? _locked;
  bool? _lights;
  int? _odo;
  int? _battery;
  int? _speed;
  String? _id;
  ConnectionStateUpdate? _connectionState;

  bool get _connected =>
      _connectionState?.connectionState == DeviceConnectionState.connected;

  bool get _disconnected =>
      _connectionState?.connectionState == DeviceConnectionState.disconnected;

  void _connect() async {
    final granted = await Permission.location.request().isGranted &&
        await Permission.bluetooth.request().isGranted;
    if (!granted) {
      return;
    }
    if (_id != null) {
      return listenToDevice(_id!);
    }
    listener = _ble.scanForDevices(withServices: []).listen((device) async {
      if (device.name.contains("E-TWOW")) {
        setState(() {
          _id = device.id;
        });
        await _ble.requestConnectionPriority(
            deviceId: device.id, priority: ConnectionPriority.highPerformance);
        listenToDevice(device.id);
        listener.cancel();
      }
    });
  }

  void initState() {
    super.initState();
    _connect();
  }

  void listenToDevice(String id) {
    _ble.connectToDevice(id: id).listen((connectionState) {
      setState(() {
        _connectionState = connectionState;
      });
      if (_connected) {
        final characteristic = QualifiedCharacteristic(
            serviceId: _serviceIdRead,
            characteristicId: _characteristicId,
            deviceId: _id!);
        _ble
            .subscribeToCharacteristic(characteristic)
            .listen((values) => _updateReadCharacteristics(values));
      } else if (_disconnected) {
        setState(() {
          _locked = null;
          _lights = null;
          _odo = null;
          _battery = null;
          _speed = null;
        });
      }
    });
  }

  void _updateReadCharacteristics(List<int> values) {
    final value = values[1];
    if (values[0] == 1) {
      _speed = value;
    }
    if (values[0] == 2) {
      _battery = value;
    }
    if (values[0] == 3) {
      setState(() {
        print(value.toRadixString(16));
        _lights =
            value == 0x51 || value == 0x52 || value == 0x71 || value == 0x72;
        _locked =
            value == 0x61 || value == 0x62 || value == 0x71 || value == 0x72;
      });
    }
    if (values[0] == 5 && values[1] == 1 && values[2] == 0x5f) {
      _odo = values[3] + values[4] + values[5];
    }
  }

  void _send(List<int> values) {
    if (_id != null && _connected) {
      final characteristic = QualifiedCharacteristic(
          serviceId: _serviceId,
          characteristicId: _characteristicId,
          deviceId: _id!);
      values.add(values.reduce((p, c) => p + c));
      _ble.writeCharacteristicWithResponse(characteristic, value: values);
    }
  }

  void _lockOn() {
    _send([0x55, 0x05, 0x05, 0x01]);
  }

  void _lockOff() {
    _send([0x55, 0x05, 0x05, 0x00]);
  }

  void _lightOn() {
    _send([0x55, 0x06, 0x05, 0x01]);
  }

  void _lightOff() {
    _send([0x55, 0x06, 0x05, 0x00]);
  }

  void _setSpeed(int mode) {
    _send([0x55, 0x02, 0x05, mode]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.lock_open),
                color: Colors.green,
                tooltip: 'Lock',
                onPressed: _locked ?? false ? _lockOff : null,
                iconSize: 120,
              ),
              IconButton(
                icon: const Icon(Icons.lock),
                color: Colors.red,
                tooltip: 'Lock',
                onPressed: _locked ?? true ? null : _lockOn,
                iconSize: 120,
              ),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.lightbulb),
                tooltip: 'Light',
                color: Colors.yellow,
                onPressed: _lights ?? false ? _lightOff : null,
                iconSize: 80,
              ),
              IconButton(
                icon: const Icon(Icons.lightbulb),
                tooltip: 'Light',
                onPressed: _lights ?? true ? null : _lightOn,
                iconSize: 80,
              ),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.speed),
                tooltip: '6km/h',
                color: Colors.green,
                onPressed: _connected ? () => _setSpeed(1) : null,
                iconSize: 70,
              ),
              IconButton(
                icon: const Icon(Icons.speed),
                tooltip: '20km/h',
                color: Colors.blue,
                onPressed: _connected ? () => _setSpeed(2) : null,
                iconSize: 70,
              ),
              IconButton(
                icon: const Icon(Icons.speed),
                tooltip: '25km/h',
                color: Colors.yellow,
                onPressed: _connected ? () => _setSpeed(3) : null,
                iconSize: 70,
              ),
              IconButton(
                icon: const Icon(Icons.speed),
                tooltip: '35km/h',
                color: Colors.red,
                onPressed: _connected ? () => _setSpeed(0) : null,
                iconSize: 70,
              ),
            ],
          ),
          Text(
            'MAC: ${_disconnected ? "lost connection" : (_id ?? "searching")}',
            style: TextStyle(fontSize: 20.0),
          ),
          Text(
            '${_speed != null ? "Speed: ${_speed! / 10}" : ""}',
            style: TextStyle(fontSize: 20.0),
          ),
          Text(
            '${_odo != null ? "Odometer: $_odo" : ""}',
            style: TextStyle(fontSize: 20.0),
          ),
          Text(
            '${_battery != null ? "Battery: $_battery %" : ""}',
            style: TextStyle(fontSize: 20.0),
          )
        ],
      ),
      floatingActionButton: _disconnected
          ? FloatingActionButton.extended(
              onPressed: _connect,
              icon: Icon(Icons.bluetooth),
              backgroundColor: Colors.blue,
              label: Text("Reconnect"))
          : null,
    );
  }
}
