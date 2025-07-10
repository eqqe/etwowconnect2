import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:etwowconnect2/types.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:quick_actions/quick_actions.dart';
import 'package:shared_preferences/shared_preferences.dart';
class ScooterInfo {
  int? mode;
  bool? locked;
  bool? zeroStart;
  bool? lights;
  int? odo;
  int? trip;
  int? battery;
  int? speed;

  ScooterInfo();
  ScooterInfo.from(this.mode, this.locked, this.zeroStart, this.lights, this.odo, this.trip, this.battery, this.speed);
}
class ScooterModel extends ScooterInfo with ChangeNotifier {
  String? deviceId;
  String? deviceName;
  DeviceConnectionState? connectionState;
  ShortcutType? shortcutType;
  StreamSubscription<List<int>>? characteristicsSubscription;

  bool get connected => connectionState == DeviceConnectionState.connected;

  final FlutterReactiveBle _ble;

  ScooterModel(this._ble);

  void toast(String message) {
    if (Platform.environment.containsKey('FLUTTER_TEST')) {
      return;
    }
    Fluttertoast.showToast(
        msg: message,
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        timeInSecForIosWeb: 1,
        backgroundColor: Colors.green,
        textColor: Colors.white,
        fontSize: 16.0);
  }

  Future<void> scan() async {
    // Check if running in a test environment. If so, skip permission checks.
    if (Platform.environment.containsKey('FLUTTER_TEST')) {
      if (kDebugMode) {
        print('Running in FLUTTER_TEST environment, skipping permission checks.');
      }
      return;
    }

    // Request and check Location When In Use permission
    var locationStatus = await Permission.locationWhenInUse.request();
    if (!locationStatus.isGranted) {
      // You can throw a more specific exception or handle it as needed
      throw Exception('Location When In Use permission not granted.');
    }
    if (kDebugMode) {
      print('Location When In Use permission granted.');
    }


    if (Platform.isAndroid) {
        // For Android, request both Bluetooth Scan and Bluetooth Connect
        var bluetoothScanStatus = await Permission.bluetoothScan.request();
        if (!bluetoothScanStatus.isGranted) {
          throw Exception('Bluetooth Scan permission not granted.');
        }
        if (kDebugMode) {
          print('Bluetooth Scan permission granted.');
        }

        var bluetoothConnectStatus = await Permission.bluetoothConnect.request();
        if (!bluetoothConnectStatus.isGranted) {
          throw Exception('Bluetooth Connect permission not granted.');
        }
        if (kDebugMode) {
          print('Bluetooth Connect permission granted.');
        }
      } else if (Platform.isIOS) {
        // For iOS, only request the general Bluetooth permission
        var bluetoothStatus = await Permission.bluetooth.request();
        if (!bluetoothStatus.isGranted) {
          throw Exception('Bluetooth permission not granted.');
        }
        if (kDebugMode) {
          print('Bluetooth permission granted.');
        }
      } else {
        // Handle other platforms if necessary, or throw an unsupported error
        if (kDebugMode) {
          print('Bluetooth permissions not explicitly handled for this platform.');
        }
      }

    // If all checks pass, you can proceed with your application logic
    if (kDebugMode) {
      print('All required permissions are granted!');
    }

    if (!Platform.environment.containsKey('FLUTTER_TEST')) {
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
    }
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
            deviceName = gTSportName;
            sharedPref.setString(prefDeviceName, gTSportName);
          }
          break;
        }
      }
    }

    final characteristic = QualifiedCharacteristic(
        serviceId: serviceId[deviceName]!, characteristicId: readCharacteristicId[deviceName]!, deviceId: deviceId!);

    while (true) {
      await for (final update in _ble.connectToDevice(id: deviceId!, connectionTimeout: const Duration(seconds: 10))) {
        connectionState = update.connectionState;
        if (connected) {
          await executeShortcut();
          characteristicsSubscription = _ble.subscribeToCharacteristic(characteristic).listen((values) async {
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
                trip = value + values[2];
                break;
              case 5:
                odo = values[3] + values[4] + values[5];
                break;
              default:
                break;
            }
            notifyListeners();
          });
        } else if (connectionState == DeviceConnectionState.disconnected) {
          characteristicsSubscription?.cancel();
          mode = null;
          locked = null;
          zeroStart = null;
          lights = null;
          odo = null;
          trip = null;
          battery = null;
          speed = null;
          notifyListeners();
        }
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
          action = () => setMode(0);
          break;
        case ShortcutType.setSpeed2:
          action = () => setMode(2);
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

  Future<bool> setMode(int mode) async {
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
        if (Platform.isAndroid) {
          await _ble.writeCharacteristicWithResponse(characteristic, value: allValues);
        }
        else {
          await _ble.writeCharacteristicWithoutResponse(characteristic, value: allValues);
        }
      } catch (e) {
        toast('Could not write characteristic.');
        return false;
      }
      return true;
    } else {
      toast("Error trying to send while not connected");
      return false;
    }
  }
}
