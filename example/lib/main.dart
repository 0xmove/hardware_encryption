import 'package:flutter/material.dart';

import 'biometric_util.dart';
import 'package:hardware_encryption/hardware_encryption.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final _hardwareEncryption = HardwareEncryption();

  var _text1 = '';
  var _text2 = '';

  var msg = '0x0000';

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Plugin example app'),
        ),
        body: Container(
          alignment: Alignment.center,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 15),
              ElevatedButton(
                onPressed: () async {
                  _text1 = await _hardwareEncryption.encrypt(msg);
                  setState(() {});
                },
                child: const Text('encrypt'),
              ),
              const SizedBox(height: 15),
              Text(_text1),
              const SizedBox(height: 15),
              ElevatedButton(
                onPressed: () async {
                  BiometricUtil.checkBiometrics(() {
                    _decrypt();
                  });
                },
                child: const Text('decrypt'),
              ),
              const SizedBox(height: 15),
              Text(_text2),
            ],
          ),
        ),
      ),
    );
  }

  _decrypt() async {
    int delaySecond = 1;

    /// It will fail if it exceeds the default time of 10 seconds
    Future.delayed(Duration(seconds: delaySecond), () async {
      _text2 = await _hardwareEncryption.decrypt(_text1);
      setState(() {});
    });
  }
}
