import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';

String gTName = "E-TWOW";
String gTSportName = "GTSport";

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
var characteristicId = {
  gTName: Uuid.parse("0000ffe1-0000-1000-8000-00805f9b34fb"),
  gTSportName: Uuid.parse("0000ff03-0000-1000-8000-00805f9b34fb"),
};
