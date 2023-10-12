import 'dart:async';

import 'package:etwowconnect2/scooter.dart';
import 'package:etwowconnect2/types.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:shared_preferences/shared_preferences.dart';

final ble = FlutterReactiveBle();

final sharedPrefsProvider = Provider((ref) => SharedPreferences.getInstance());

class ScooterNotifier extends StateNotifier<Scooter> {
  ScooterNotifier() : super(Scooter());

  String? deviceId;
  String? deviceName;

  void updateValues(List<int> values) {
    state = Scooter.fromScooter(state, values);
  }

  void reset(){
    state = Scooter();
  }

  Future<void> send(List<int> values) async {
    final characteristic = QualifiedCharacteristic(
        serviceId: serviceId[deviceName]!, characteristicId: writeCharacteristicId[deviceName]!, deviceId: deviceId!);
    final allValues = [0x55];
    allValues.addAll(values);
    allValues.add(allValues.reduce((p, c) => p + c));
    await ble.writeCharacteristicWithResponse(characteristic, value: allValues);
  }
}

final scooterProvider = StateNotifierProvider<ScooterNotifier, Scooter>((ref) {
  return ScooterNotifier();
});

const prefDeviceId = "prefDeviceId";
const prefDeviceName = "prefDeviceName";

final bleScanner = StreamProvider.autoDispose<ConnectionStateUpdate>((ref) async* {
  final prefs = await ref.watch(sharedPrefsProvider);
  var deviceId = prefs.getString(prefDeviceId);
  var deviceName = prefs.getString(prefDeviceName);
  final scooterNotifier = ref.watch(scooterProvider.notifier);

  if (deviceId == null || deviceName == null) {
    await for (final device in ble.scanForDevices(withServices: [])) {
      if (device.name.contains(gTName) || device.name.contains(gTSportName)) {
        deviceId = device.id;
        prefs.setString(prefDeviceId, deviceId);
        if (device.name.contains(gTName)) {
          deviceName = gTName;
          prefs.setString(prefDeviceName, gTName);
        } else if (device.name.contains(gTSportName)) {
          deviceName = gTName;
          prefs.setString(prefDeviceName, gTName);
        }
        break;
      }
    }
  }

  scooterNotifier.deviceId = deviceId;
  scooterNotifier.deviceName = deviceName;

  Stream<ConnectionStateUpdate> connect() async* {
    while (true) {
      yield* ble.connectToDevice(id: deviceId!, connectionTimeout: const Duration(seconds: 10));
      await Future.delayed(const Duration(seconds: 5));
    }
  }

  StreamSubscription<List<int>>? characteristicSubscription;
  await for (final connectionState in connect()) {
    if (connectionState.connectionState == DeviceConnectionState.connected) {
      final characteristic = QualifiedCharacteristic(
          serviceId: serviceId[deviceName]!, characteristicId: readCharacteristicId[deviceName]!, deviceId: deviceId!);
      characteristicSubscription = ble.subscribeToCharacteristic(characteristic).listen((value) {
        scooterNotifier.updateValues(value);
      });
    }
    else if (connectionState.connectionState == DeviceConnectionState.disconnected) {
      characteristicSubscription?.cancel();
      scooterNotifier.reset();
    }
    yield connectionState;
  }
});
