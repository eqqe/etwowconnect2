import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';

const gTName = "E-TWOW";
const gTSportName = "GTSport";

var getEtwowDeviceName = (DiscoveredDevice device) {
  if (device.name.contains(gTName)) {
    return gTName;
  } else if (device.name.contains(gTSportName)) {
    return gTSportName;
  }
  return null;
};

var serviceId = {
  gTName: Uuid.parse("0000ffe0-0000-1000-8000-00805f9b34fb"),
  gTSportName: Uuid.parse("0000ff00-0000-1000-8000-00805f9b34fb"),
};

var readCharacteristicId = {
  gTName: Uuid.parse("0000ffe1-0000-1000-8000-00805f9b34fb"),
  gTSportName: Uuid.parse("0000ff01-0000-1000-8000-00805f9b34fb"),
};

var writeCharacteristicId = {
  gTName: Uuid.parse("0000ffe1-0000-1000-8000-00805f9b34fb"),
  gTSportName: Uuid.parse("0000ff02-0000-1000-8000-00805f9b34fb"),
};

enum ShortcutType { lock, unlock, setSpeed0, setSpeed2 }
