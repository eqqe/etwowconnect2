import 'package:etwowconnect2/scooter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
void main() {
  runApp(const ListenableBuilderScooter());
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
                        onPressed: _scooterNotifier.mode != null && _scooterNotifier.mode != 1 ? () => _scooterNotifier.setMode(1) : null,
                        iconSize: 70,
                      ),
                      IconButton(
                        icon: const Icon(Icons.speed),
                        tooltip: '20km/h',
                        color: Colors.blue,
                        onPressed: _scooterNotifier.mode != null && _scooterNotifier.mode != 2 ? () => _scooterNotifier.setMode(2) : null,
                        iconSize: 70,
                      ),
                      IconButton(
                        icon: const Icon(Icons.speed),
                        tooltip: '25km/h',
                        color: Colors.yellow,
                        onPressed: _scooterNotifier.mode != null && _scooterNotifier.mode != 3 ? () => _scooterNotifier.setMode(3) : null,
                        iconSize: 70,
                      ),
                      IconButton(
                        icon: const Icon(Icons.speed),
                        tooltip: '35km/h',
                        color: Colors.red,
                        onPressed: _scooterNotifier.mode != null && _scooterNotifier.mode != 0 ? () => _scooterNotifier.setMode(0) : null,
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
