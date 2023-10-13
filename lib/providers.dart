import 'dart:async';

import 'package:etwowconnect2/scooter.dart';
import 'package:etwowconnect2/toast.dart';
import 'package:etwowconnect2/types.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:quick_actions/quick_actions.dart';

final ble = FlutterReactiveBle();

final sharedPrefsProvider = Provider((ref) => SharedPreferences.getInstance());

class ScooterNotifier extends StateNotifier<Scooter> {
  ScooterNotifier() : super(Scooter());

  void updateValues(List<int> values) async {
    state = Scooter.fromScooter(state, values);
    if (state.shortcutType == "action_lock" && state.speed == 0) {
      if (await lockOn()) {
        state.shortcutType = null;
      }
    }
  }

  void reset() {
    state.battery = null;
    state.lights = null;
    state.locked = null;
    state.mode = null;
    state.odo = null;
    state.speed = null;
    state.trip = null;
    state.zeroStart = null;
  }

  Future<bool> lockOn() async {
    if (state.speed == 0) {
      if (await send([0x05, 0x05, 0x01])) {
        toast("Locked");
        return true;
      }
    } else {
      toast("Cannot lock as speed is not 0");
    }
    return false;
  }

  Future<bool> lockOff() async {
    if (await send([0x05, 0x05, 0x00])) {
      toast("Lock removed");
      return true;
    }
    return false;
  }

  lightOn() async {
    if (await send([0x06, 0x05, 0x01])) {
      toast("Lights on");
      return true;
    }
    return false;
  }

  lightOff() async {
    if (await send([0x06, 0x05, 0x00])) {
      toast("Lights off");
      return true;
    }
    return false;
  }

  setSpeed(int mode) async {
    if (await send([0x02, 0x05, mode])) {
      toast("Speed set to L$mode mode");
      return true;
    }
    return false;
  }

  Future<bool> send(List<int> values) async {
    if (state.connectionState == DeviceConnectionState.connected) {
      final characteristic = QualifiedCharacteristic(
          serviceId: serviceId[state.deviceName]!, characteristicId: writeCharacteristicId[state.deviceName]!, deviceId: state.deviceId!);
      final allValues = [0x55];
      allValues.addAll(values);
      allValues.add(allValues.reduce((p, c) => p + c));
      await ble.writeCharacteristicWithResponse(characteristic, value: allValues);
      return true;
    } else {
      toast("Error trying to send while not connected");
      return false;
    }
  }
}

final scooterProvider = StateNotifierProvider<ScooterNotifier, Scooter>((ref) {
  return ScooterNotifier();
});

const prefDeviceId = "prefDeviceId";
const prefDeviceName = "prefDeviceName";

final bleScanner = StreamProvider.autoDispose<ConnectionStateUpdate>((ref) async* {
  final prefs = await ref.watch(sharedPrefsProvider);
  final scooter = ref.watch(scooterProvider);
  final scooterNotifier = ref.watch(scooterProvider.notifier);

  if (!await Permission.locationWhenInUse.request().isGranted ||
      !await Permission.bluetoothScan.request().isGranted ||
      !await Permission.bluetoothConnect.request().isGranted) {
    toast("Please accept permissions");
    return;
  }

  scooter.deviceId = prefs.getString(prefDeviceId);
  scooter.deviceName = prefs.getString(prefDeviceName);

  if (scooter.deviceId == null || scooter.deviceName == null) {
    await for (final device in ble.scanForDevices(withServices: [])) {
      if (device.name.contains(gTName) || device.name.contains(gTSportName)) {
        scooter.deviceId = device.id;
        prefs.setString(prefDeviceId, device.id);
        if (device.name.contains(gTName)) {
          scooter.deviceName = gTName;
          prefs.setString(prefDeviceName, gTName);
        } else if (device.name.contains(gTSportName)) {
          scooter.deviceName = gTName;
          prefs.setString(prefDeviceName, gTName);
        }
        break;
      }
    }
  }

  const QuickActions quickActions = QuickActions();
  quickActions.initialize((shortcutType) async {
    scooter.shortcutType = shortcutType;
  });
  quickActions.setShortcutItems(<ShortcutItem>[
    const ShortcutItem(type: 'action_lock', localizedTitle: 'Lock 🔒', icon: "ic_launcher"),
    const ShortcutItem(type: 'action_unlock', localizedTitle: 'Unlock 🔓', icon: "ic_launcher"),
    const ShortcutItem(type: 'action_set_speed_2', localizedTitle: '20 km/h ⚡️', icon: "ic_launcher"),
    const ShortcutItem(type: 'action_set_speed_0', localizedTitle: '⚡️⚡️⚡️', icon: "ic_launcher"),
  ]);

  Stream<ConnectionStateUpdate> connect() async* {
    while (true) {
      yield* ble.connectToDevice(id: scooter.deviceId!, connectionTimeout: const Duration(seconds: 10));
      await Future.delayed(const Duration(seconds: 5));
    }
  }

  StreamSubscription<List<int>>? characteristicSubscription;
  await for (final connectionState in connect()) {
    scooter.connectionState = connectionState.connectionState;
    if (connectionState.connectionState == DeviceConnectionState.connected) {
      if (scooter.shortcutType != null) {
        Future<bool> Function()? actionFunction;
        switch (scooter.shortcutType) {
          case 'action_unlock':
            actionFunction = scooterNotifier.lockOff;
            break;
          case 'action_set_speed_0':
            actionFunction = () => scooterNotifier.setSpeed(0);
            break;
          case 'action_set_speed_2':
            actionFunction = () => scooterNotifier.setSpeed(2);
            break;
        }
        if (actionFunction != null) {
          if (await actionFunction()) {
            scooter.shortcutType = null;
          }
        }
      }
      final characteristic = QualifiedCharacteristic(
          serviceId: serviceId[scooter.deviceName]!,
          characteristicId: readCharacteristicId[scooter.deviceName]!,
          deviceId: scooter.deviceId!);
      characteristicSubscription = ble.subscribeToCharacteristic(characteristic).listen((value) {
        scooterNotifier.updateValues(value);
      });
    } else if (connectionState.connectionState == DeviceConnectionState.disconnected) {
      characteristicSubscription?.cancel();
      scooterNotifier.reset();
    }
    yield connectionState;
  }
});
