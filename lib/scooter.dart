import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';

class Scooter {
  DeviceConnectionState? connectionState;
  bool? locked;
  bool? zeroStart;
  bool? lights;
  int? mode;
  int? odo;
  int? trip;
  int? battery;
  int? speed;

  Scooter();

  Scooter.fromScooter(Scooter scooter, List<int> values) {
    connectionState = scooter.connectionState;
    locked = scooter.locked;
    zeroStart = scooter.zeroStart;
    lights = scooter.lights;
    mode = scooter.mode;
    odo = scooter.odo;
    trip = scooter.trip;
    battery = scooter.battery;
    speed = scooter.speed;
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
  }

}