import 'dart:io';

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
      title: 'Flutter Demo',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // Try running your application with "flutter run". You'll see the
        // application has a blue toolbar. Then, without quitting the app, try
        // changing the primarySwatch below to Colors.green and then invoke
        // "hot reload" (press "r" in the console where you ran "flutter run",
        // or simply save your changes to "hot reload" in a Flutter IDE).
        // Notice that the counter didn't reset back to zero; the application
        // is not restarted.
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key? key, required this.title}) : super(key: key);

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final _flutterReactiveBle = FlutterReactiveBle();
  final _serviceId = Uuid.parse("0000ffe0-0000-1000-8000-00805f9b34fb");
  final _serviceIdRead = Uuid.parse("0000ffe1-0000-1000-8000-00805f9b34fb");
  final _characteristicId = Uuid.parse("0000ffe1-0000-1000-8000-00805f9b34fb");
  bool? locked;
  bool? lights;
  String? _id;
  ConnectionStateUpdate? _connectionState;

  bool get _connected =>
      _connectionState?.connectionState == DeviceConnectionState.connected;

  void initState() {
    super.initState();
    () async {
      final granted = await Permission.location.request().isGranted;
      if (!granted) {
        return;
      }
      _flutterReactiveBle.scanForDevices(withServices: []).listen((device) {
        if (device.name.contains("E-TWOW")) {
          setState(() {
            _id = device.id;
          });
          listenToDevice(device);
        }
      });
    }();
  }

  void listenToDevice(DiscoveredDevice device) {
    _flutterReactiveBle
        .connectToDevice(id: device.id)
        .listen((connectionState) {
      setState(() {
        _connectionState = connectionState;
      });
      if (_connected) {
        final characteristic = QualifiedCharacteristic(
            serviceId: _serviceIdRead,
            characteristicId: _characteristicId,
            deviceId: _id!);
        _flutterReactiveBle
            .subscribeToCharacteristic(characteristic)
            .listen((values) => _updateReadCharacteristics(values));
      }
    });
  }

  void _updateReadCharacteristics(List<int> values) {
    if (values[0] == 1) {
      final speed = values[1];
      print("speed: " + speed.toString());
    }
    if (values[0] == 2) {
      final batteryLevel = values[1];
      print("batteryLevel: " + batteryLevel.toString());
    }
    if (values[0] == 3) {
      setState(() {
        lights = values[1] == 0x52 || values[1] == 0x72;
        locked = values[1] == 0x62 || values[1] == 0x72;
      });
    }
    if (values[0] == 5 && values[1] == 1 && values[2] == 0x5f) {
      final trip = values[3] + values[4] + values[5];
      print("trip: " + trip.toString());
    }
  }

  void _writeCharacteristic(List<int> value) {
    if (_id != null && _connected) {
      final characteristic = QualifiedCharacteristic(
          serviceId: _serviceId,
          characteristicId: _characteristicId,
          deviceId: _id!);
      _flutterReactiveBle.writeCharacteristicWithResponse(characteristic,
          value: value);
    }
  }

  void _lock() {
    if (locked ?? false) {
      _writeCharacteristic([0x55, 0x05, 0x05, 0x00, 0x5f]);
    } else {
      _writeCharacteristic([0x55, 0x05, 0x05, 0x01, 0x60]);
    }
  }

  void _light() {
    if (lights ?? false) {
      _writeCharacteristic([0x55, 0x06, 0x05, 0x00, 0x60]);
    } else {
      _writeCharacteristic([0x55, 0x06, 0x05, 0x01, 0x61]);
    }
  }

  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return Scaffold(
        appBar: AppBar(
          // Here we take the value from the MyHomePage object that was created by
          // the App.build method, and use it to set our appbar title.
          title: Text(widget.title),
        ),
        body: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.lock_open),
                  tooltip: 'Lock',
                  onPressed: _lock,
                  iconSize: 48,
                ),
                IconButton(
                  icon: const Icon(Icons.lightbulb),
                  tooltip: 'Light',
                  onPressed: _light,
                  iconSize: 48,
                ),
              ],
            ),
            Text('Connecting to: ${_id ?? "searching"}')
          ],
        ));
  }
}
