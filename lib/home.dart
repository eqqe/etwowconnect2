import 'dart:async';
import 'package:etwowconnect2/scooter.dart';
import 'package:etwowconnect2/types.dart';
import 'package:flutter/material.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:permission_handler/permission_handler.dart';

final flutterReactiveBle = FlutterReactiveBle();

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  bool _checkingDevicesName = false;
  String? _checkingDevicesNameString;
  DiscoveredDevice? _device;
  ConnectionStateUpdate? _connectionState;
  StreamSubscription<ConnectionStateUpdate>? _connectionSubscription;
  late StreamSubscription<DiscoveredDevice> _scanSubscription;
  Scooter? _scooter;

  @override
  void initState() {
    _startScan();
    super.initState();
  }

  @override
  void dispose() {
    _connectionSubscription?.cancel();
    _scanSubscription.cancel();
    super.dispose();
  }

  void _startScan() async {
    await Permission.location.request().isGranted &&
        await Permission.bluetooth.request().isGranted;
    _scanSubscription = flutterReactiveBle
        .scanForDevices(withServices: []).listen((device) async {
      var eTwowDeviceName = getEtwowDeviceName(device);
      setState(() {
        _checkingDevicesName = true;
        _checkingDevicesNameString = device.name;
      });
      if (eTwowDeviceName != null) {
        setState(() {
          _device = device;
        });
        await _scanSubscription.cancel();
        _connectToDevice();
      }
    });
  }

  void _connectToDevice() {
    if (_device != null) {
      _connectionSubscription?.cancel();
      _connectionSubscription = flutterReactiveBle
          .connectToDevice(
              id: _device!.id, connectionTimeout: const Duration(seconds: 5))
          .listen((connectionState) {
        setState(() {
          _connectionState = connectionState;
        });
        if (connectionState.connectionState ==
            DeviceConnectionState.disconnected) {
          setState(() {
            _scooter = null;
          });
          _connectToDevice();
        } else if (connectionState.connectionState ==
            DeviceConnectionState.connected) {
          var model = getEtwowDeviceName(_device!);
          final characteristic = QualifiedCharacteristic(
              serviceId: serviceId[model]!,
              characteristicId: characteristicId[model]!,
              deviceId: connectionState.deviceId);
          flutterReactiveBle
              .subscribeToCharacteristic(characteristic)
              .listen((values) => _updateReadCharacteristics(values));
        }
      });
    }
  }

  void _updateReadCharacteristics(List<int> values) {
    _scooter ??= Scooter();
    _scooter!.updateScooterValues(values);
    setState(() {
      _scooter = _scooter;
    });
  }

  void _send(List<int> values) {
    final characteristic = QualifiedCharacteristic(
        serviceId: serviceId[getEtwowDeviceName(_device!)]!,
        characteristicId: characteristicId[getEtwowDeviceName(_device!)]!,
        deviceId: _device!.id);
    final allValues = [0x55];
    allValues.addAll(values);
    allValues.add(allValues.reduce((p, c) => p + c));
    flutterReactiveBle.writeCharacteristicWithResponse(characteristic,
        value: allValues);
  }

  void _lockOn() {
    _send([0x05, 0x05, 0x01]);
  }

  void _lockOff() {
    _send([0x05, 0x05, 0x00]);
  }

  void _lightOn() {
    _send([0x06, 0x05, 0x01]);
  }

  void _lightOff() {
    _send([0x06, 0x05, 0x00]);
  }

  void _setSpeed(int mode) {
    _send([0x02, 0x05, mode]);
  }

  String get message {
    if (_device == null) {
      return "Searching for ETWOW scooter";
    }
    if (_connectionState == null) {
      return "No connection state";
    }
    switch (_connectionState?.connectionState) {
      case DeviceConnectionState.connecting:
        return "Connecting to ${_device?.name}";
      case DeviceConnectionState.connected:
        return "Connected to ${_device?.name}";
      case DeviceConnectionState.disconnecting:
        return "Disconnecting from ${_device?.name}";
      case DeviceConnectionState.disconnected:
        return "Disconnected from ${_device?.name}";
      default:
        return "";
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.lock_open),
                  color: Colors.green,
                  tooltip: 'Lock',
                  onPressed: _scooter?.locked ?? false ? _lockOff : null,
                  iconSize: 120,
                ),
                IconButton(
                  icon: const Icon(Icons.lock),
                  color: Colors.red,
                  tooltip: 'Lock',
                  onPressed: _scooter?.locked ?? true ? null : _lockOn,
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
                  onPressed: _scooter?.lights ?? false ? _lightOff : null,
                  iconSize: 80,
                ),
                IconButton(
                  icon: const Icon(Icons.lightbulb),
                  tooltip: 'Light',
                  onPressed: _scooter?.lights ?? true ? null : _lightOn,
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
                  onPressed: _scooter?.mode != null && _scooter?.mode != 1
                      ? () => _setSpeed(1)
                      : null,
                  iconSize: 70,
                ),
                IconButton(
                  icon: const Icon(Icons.speed),
                  tooltip: '20km/h',
                  color: Colors.blue,
                  onPressed: _scooter?.mode != null && _scooter?.mode != 2
                      ? () => _setSpeed(2)
                      : null,
                  iconSize: 70,
                ),
                IconButton(
                  icon: const Icon(Icons.speed),
                  tooltip: '25km/h',
                  color: Colors.yellow,
                  onPressed: _scooter?.mode != null && _scooter?.mode != 3
                      ? () => _setSpeed(3)
                      : null,
                  iconSize: 70,
                ),
                IconButton(
                  icon: const Icon(Icons.speed),
                  tooltip: '35km/h',
                  color: Colors.red,
                  onPressed: _scooter?.mode != null && _scooter?.mode != 0
                      ? () => _setSpeed(0)
                      : null,
                  iconSize: 70,
                ),
              ],
            ),
            Text(
              _scooter?.speed != null ? "Speed: ${_scooter!.speed! / 10}" : "",
              style: const TextStyle(fontSize: 20.0),
            ),
            Text(
              _scooter?.trip != null ? "Trip: ${_scooter!.trip! / 10}" : "",
              style: const TextStyle(fontSize: 20.0),
            ),
            Text(
              _scooter?.odo != null ? "Odometer: ${_scooter!.odo}" : "",
              style: const TextStyle(fontSize: 20.0),
            ),
            Text(
              _scooter?.zeroStart != null
                  ? "Zero Start: ${_scooter!.zeroStart}"
                  : "",
              style: const TextStyle(fontSize: 20.0),
            ),
            Text(
              _scooter?.battery != null
                  ? "Battery: ${_scooter!.battery} %"
                  : "",
              style: const TextStyle(fontSize: 20.0),
            ),
            Text(
              message,
              style: const TextStyle(fontSize: 20.0),
            ),
            Text(
              _checkingDevicesName
                  ? "Checking ble device ${_checkingDevicesNameString!.isEmpty ? "<no name>" : _checkingDevicesNameString} to contain $gTName or $gTSportName"
                  : "Not ble device found yet",
              style: const TextStyle(fontSize: 20.0),
            ),
          ],
        ),
      ),
    );
  }
}
