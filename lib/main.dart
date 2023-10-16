import 'package:flutter/material.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:etwowconnect2/types.dart';
import 'package:etwowconnect2/fake.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:quick_actions/quick_actions.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const ListenableBuilderScooter());
}

class ScooterModel with ChangeNotifier {
  int? mode;
  bool? locked;
  bool? zeroStart;
  bool? lights;
  int? odo;
  int? trip;
  int? battery;
  int? speed;
  String? deviceId;
  String? deviceName;
  DeviceConnectionState? connectionState;
  ShortcutType? shortcutType;

  bool get connected => connectionState == DeviceConnectionState.connected;

  final FlutterReactiveBle _ble;

  ScooterModel(this._ble);

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

  void setMode(int value) {
    mode = value;
    notifyListeners();
  }

  Future<void> scan() async {
    if (!await Permission.locationWhenInUse.request().isGranted ||
        !await Permission.bluetoothScan.request().isGranted ||
        !await Permission.bluetoothConnect.request().isGranted) {
      return;
    }

    const QuickActions quickActions = QuickActions();
    quickActions.initialize((shortcutType) async {
      this.shortcutType = ShortcutType.values.byName(shortcutType);
    });
    quickActions.setShortcutItems(<ShortcutItem>[
      ShortcutItem(type: ShortcutType.lock.toString(), localizedTitle: 'Lock 🔒', icon: "ic_launcher"),
      ShortcutItem(type: ShortcutType.unlock.toString(), localizedTitle: 'Unlock 🔓', icon: "ic_launcher"),
      ShortcutItem(type: ShortcutType.setSpeed2.toString(), localizedTitle: '20 km/h ⚡️', icon: "ic_launcher"),
      ShortcutItem(type: ShortcutType.setSpeed0.toString(), localizedTitle: '⚡️⚡️⚡️', icon: "ic_launcher"),
    ]);
    final sharedPref = await SharedPreferences.getInstance();

    deviceId = sharedPref.getString(prefDeviceId);
    deviceName = sharedPref.getString(prefDeviceName);

    if (deviceId == null || deviceName == null) {
      await for (final device in _ble.scanForDevices(withServices: [])) {
        if (device.name.contains(gTName) || device.name.contains(gTSportName)) {
          deviceId = device.id;
          sharedPref.setString(prefDeviceId, device.id);
          if (device.name.contains(gTName)) {
            deviceName = gTName;
            sharedPref.setString(prefDeviceName, gTName);
          } else if (device.name.contains(gTSportName)) {
            deviceName = gTName;
            sharedPref.setString(prefDeviceName, gTSportName);
          }
          break;
        }
      }
    }

    final readCharacteristic = QualifiedCharacteristic(
        serviceId: serviceId[deviceName]!, characteristicId: readCharacteristicId[deviceName]!, deviceId: deviceId!);

    while (true) {
      await for (final update in _ble.connectToDevice(id: deviceId!, connectionTimeout: const Duration(seconds: 10))) {
        connectionState = update.connectionState;
        if (connected) {
          await executeShortcut();
          await for (final values in _ble.subscribeToCharacteristic(readCharacteristic)) {
            await executeShortcut();
            final value = values[1];
            switch (values[0]) {
              case 1:
                speed = value + (values[2] == 1 ? 0xff : 0);
                break;
              case 2:
                battery = value;
                break;
              case 3:
                final first = value ~/ 0x10;
                lights = [5, 7, 0xd, 0xf].contains(first);
                locked = [6, 7, 0xe, 0xf].contains(first);
                zeroStart = [0xc, 0xd, 0xe, 0xf].contains(first);
                mode = value % 0x10;
                break;
              case 4:
                trip = values[1] + values[2];
                break;
              case 5:
                odo = values[3] + values[4] + values[5];
                break;
              default:
                break;
            }
            notifyListeners();
          }
        } else if (connectionState == DeviceConnectionState.disconnected) {
          mode = null;
          locked = null;
          zeroStart = null;
          lights = null;
          odo = null;
          trip = null;
          battery = null;
          speed = null;
        }
        notifyListeners();
      }
    }
  }

  Future<void> executeShortcut() async {
    if (shortcutType != null) {
      Future<bool> Function() action;
      switch (shortcutType!) {
        case ShortcutType.lock:
          action = lock;
          break;
        case ShortcutType.unlock:
          action = unlock;
          break;
        case ShortcutType.setSpeed0:
          action = () => setSpeed(0);
          break;
        case ShortcutType.setSpeed2:
          action = () => setSpeed(2);
          break;
      }
      if (await action()) {
        shortcutType = null;
      }
    }
  }

  Future<bool> lock() async {
    if (speed == 0) {
      if (await send([0x05, 0x05, 0x01])) {
        toast("Locked");
        return true;
      }
    } else {
      toast("Cannot lock as speed is not 0");
    }
    return false;
  }

  Future<bool> unlock() async {
    if (await send([0x05, 0x05, 0x00])) {
      toast("Lock removed");
      return true;
    }
    return false;
  }

  Future<bool> lightOn() async {
    if (await send([0x06, 0x05, 0x01])) {
      toast("Lights on");
      return true;
    }
    return false;
  }

  Future<bool> lightOff() async {
    if (await send([0x06, 0x05, 0x00])) {
      toast("Lights off");
      return true;
    }
    return false;
  }

  Future<bool> setSpeed(int mode) async {
    if (await send([0x02, 0x05, mode])) {
      toast("Speed set to L$mode mode");
      return true;
    }
    return false;
  }

  Future<bool> send(List<int> values) async {
    if (connected) {
      final characteristic = QualifiedCharacteristic(
          serviceId: serviceId[deviceName]!, characteristicId: writeCharacteristicId[deviceName]!, deviceId: deviceId!);
      final allValues = [0x55];
      allValues.addAll(values);
      allValues.add(allValues.reduce((p, c) => p + c));
      try {
        await _ble.writeCharacteristicWithResponse(characteristic, value: allValues);
      } catch (e) {
        return false;
      }
      return true;
    } else {
      toast("Error trying to send while not connected");
      return false;
    }
  }
}

class ListenableBuilderScooter extends StatefulWidget {
  const ListenableBuilderScooter({super.key});

  @override
  State<ListenableBuilderScooter> createState() => _ListenableBuilderScooterState();
}

class _ListenableBuilderScooterState extends State<ListenableBuilderScooter> {
  final ScooterModel _scooterNotifier;

  _ListenableBuilderScooterState() : _scooterNotifier = ScooterModel(FlutterReactiveBle()) {
    _scooterNotifier.scan();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('E-Twow GT Unofficial App')),
        body: ListenableBuilder(
          listenable: _scooterNotifier,
          builder: (BuildContext context, Widget? child) {
            return Center(
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
                        onPressed: _scooterNotifier.connected ? _scooterNotifier.unlock : null,
                        iconSize: 120,
                      ),
                      IconButton(
                        icon: const Icon(Icons.lock),
                        color: Colors.red,
                        tooltip: 'Lock',
                        onPressed: _scooterNotifier.connected ? _scooterNotifier.lock : null,
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
                        onPressed: _scooterNotifier.connected ? _scooterNotifier.lightOff : null,
                        iconSize: 80,
                      ),
                      IconButton(
                        icon: const Icon(Icons.lightbulb),
                        tooltip: 'Light',
                        onPressed: _scooterNotifier.connected ? _scooterNotifier.lightOn : null,
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
                        onPressed: _scooterNotifier.mode != null && _scooterNotifier.mode != 1 ? () => _scooterNotifier.setSpeed(1) : null,
                        iconSize: 70,
                      ),
                      IconButton(
                        icon: const Icon(Icons.speed),
                        tooltip: '20km/h',
                        color: Colors.blue,
                        onPressed: _scooterNotifier.mode != null && _scooterNotifier.mode != 2 ? () => _scooterNotifier.setSpeed(2) : null,
                        iconSize: 70,
                      ),
                      IconButton(
                        icon: const Icon(Icons.speed),
                        tooltip: '25km/h',
                        color: Colors.yellow,
                        onPressed: _scooterNotifier.mode != null && _scooterNotifier.mode != 3 ? () => _scooterNotifier.setSpeed(3) : null,
                        iconSize: 70,
                      ),
                      IconButton(
                        icon: const Icon(Icons.speed),
                        tooltip: '35km/h',
                        color: Colors.red,
                        onPressed: _scooterNotifier.mode != null && _scooterNotifier.mode != 0 ? () => _scooterNotifier.setSpeed(0) : null,
                        iconSize: 70,
                      ),
                    ],
                  ),
                  Text(
                    _scooterNotifier.speed != null ? "Speed: ${_scooterNotifier.speed! / 10}" : "",
                    style: const TextStyle(fontSize: 20.0),
                  ),
                  Text(
                    _scooterNotifier.trip != null ? "Trip: ${_scooterNotifier.trip! / 10}" : "",
                    style: const TextStyle(fontSize: 20.0),
                  ),
                  Text(
                    _scooterNotifier.odo != null ? "Odometer: ${_scooterNotifier.odo}" : "",
                    style: const TextStyle(fontSize: 20.0),
                  ),
                  Text(
                    _scooterNotifier.zeroStart != null ? "Zero Start: ${_scooterNotifier.zeroStart}" : "",
                    style: const TextStyle(fontSize: 20.0),
                  ),
                  Text(
                    _scooterNotifier.battery != null ? "Battery: ${_scooterNotifier.battery} %" : "",
                    style: const TextStyle(fontSize: 20.0),
                  ),
                  Text(
                    _scooterNotifier.connected ? "Connected" : "Trying to connect",
                    style: const TextStyle(fontSize: 20.0),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
