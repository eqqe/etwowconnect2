import 'dart:async';
import 'package:etwowconnect2/scooter.dart';
import 'package:etwowconnect2/types.dart';
import 'package:flutter/material.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:quick_actions/quick_actions.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fluttertoast/fluttertoast.dart';

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
    const QuickActions quickActions = QuickActions();
    quickActions.initialize((shortcutType) async {
      switch (shortcutType) {
        case 'action_lock':
          await _lockOn();
          break;
        case 'action_unlock':
          await _lockOff();
          break;
        case 'action_set_speed_0':
          await _setSpeed(0);
          break;
        case 'action_set_speed_2':
          await _setSpeed(2);
          break;
      }
    });
    quickActions.setShortcutItems(<ShortcutItem>[
      const ShortcutItem(
          type: 'action_lock', localizedTitle: 'lock 🔒', icon: "ic_launcher"),
      const ShortcutItem(
          type: 'action_unlock',
          localizedTitle: 'unlock 🔓',
          icon: "ic_launcher"),
      const ShortcutItem(
          type: 'action_set_speed_2',
          localizedTitle: '20 km/h ⚡️',
          icon: "ic_launcher"),
      const ShortcutItem(
          type: 'action_set_speed_0',
          localizedTitle: '⚡️⚡️⚡️',
          icon: "ic_launcher"),
    ]);
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
    if (await Permission.locationWhenInUse.request().isGranted &&
        await Permission.bluetoothScan.request().isGranted &&
        await Permission.bluetoothConnect.request().isGranted) {
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
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('eTwowDeviceName', eTwowDeviceName);
          await prefs.setString('deviceId', device.id);
          await _scanSubscription.cancel();
          _connectToDevice();
        }
      });
    }
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

  _send(List<int> values) async {
    final String? eTwowDeviceName;
    final String? deviceId;
    if (_device == null) {
      final prefs = await SharedPreferences.getInstance();

      eTwowDeviceName = prefs.getString('eTwowDeviceName');
      deviceId = prefs.getString('deviceId');
    } else {
      eTwowDeviceName = getEtwowDeviceName(_device!);
      deviceId = _device?.id;
    }
    if (eTwowDeviceName == null || deviceId == null) {
      return _startScan();
    }
    final characteristic = QualifiedCharacteristic(
        serviceId: serviceId[eTwowDeviceName]!,
        characteristicId: characteristicId[eTwowDeviceName]!,
        deviceId: deviceId);
    final allValues = [0x55];
    allValues.addAll(values);
    allValues.add(allValues.reduce((p, c) => p + c));
    await flutterReactiveBle.writeCharacteristicWithResponse(characteristic,
        value: allValues);
  }

  _lockOn() async {
    if (_scooter?.speed == 0) {
      await _send([0x05, 0x05, 0x01]);
      toast("Locked");
    } else {
      toast("Cannot lock as speed is not 0");
    }
  }

  _lockOff() async {
    await _send([0x05, 0x05, 0x00]);
    toast("Lock removed");
  }

  _lightOn() async {
    await _send([0x06, 0x05, 0x01]);
    toast("Lights on");
  }

  _lightOff() async {
    await _send([0x06, 0x05, 0x00]);
    toast("Lights off");
  }

  _setSpeed(int mode) async {
    await _send([0x02, 0x05, mode]);
    toast("Speed set to L$mode mode");
  }

  void toast(String message) {
    Fluttertoast.showToast(
        msg: message,
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        timeInSecForIosWeb: 1,
        backgroundColor: Colors.green,
        textColor: Colors.white,
        fontSize: 16.0);
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
                  : "No ble device found yet",
              style: const TextStyle(fontSize: 20.0),
            ),
          ],
        ),
      ),
    );
  }
}
