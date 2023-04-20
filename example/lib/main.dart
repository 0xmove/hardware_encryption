import 'dart:io';

import 'package:flutter/material.dart';
import 'package:hardware_encryption/biometric_util.dart';

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
  var _text3 = '';

  var msg = '0x0000';

  var tag = 'hardwareEncryption';

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
                  _text1 = await _hardwareEncryption.encrypt(tag, msg);
                  setState(() {});
                  print(_text1);
                },
                child: const Text('encrypt'),
              ),
              const SizedBox(height: 15),
              Text(_text1),
              const SizedBox(height: 15),
              ElevatedButton(
                onPressed: () async {
                  _decrypt();
                },
                child: const Text('decrypt'),
              ),
              const SizedBox(height: 15),
              Text(_text2),
              const SizedBox(height: 15),
              ElevatedButton(
                onPressed: () async {
                  final result = await _hardwareEncryption.removeKey(tag);
                  setState(() {
                    _text3 = 'removeKey $result';
                  });
                },
                child: const Text('remove'),
              ),
              const SizedBox(height: 15),
              Text(_text3),
            ],
          ),
        ),
      ),
    );
  }

  _decrypt() async {
    int delaySecond = 0;

    /// It will fail if it exceeds the default time of 10 seconds
    Future.delayed(Duration(seconds: delaySecond), () async {
      _text2 = await _hardwareEncryption.decrypt(tag, _text1);
      setState(() {});
    });
  }

  @override
  void dispose() async {
    await _hardwareEncryption.removeKey(tag);
    super.dispose();
  }
}
