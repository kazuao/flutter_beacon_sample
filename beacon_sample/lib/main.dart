import 'beacon_outgoing.dart';
import 'package:flutter/material.dart';

import 'beacon_receive.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('Beacon Broadcast')),
        body: BodyApp(),
      ),
    );
  }
}

class BodyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        children: [
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => BeaconOutgoing()),
              );
            },
            child: Text('ビーコン発信'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => BeaconReceive()),
              );
            },
            child: Text('ビーコン受信'),
          ),
        ],
      ),
    );
  }
}
