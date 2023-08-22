//serial_helper.dart
// ignore_for_file: unused_element

import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_libserialport/flutter_libserialport.dart';

class SerialHelper {
  static const _startMarker = '\x01';
  static const _endMarker = '\x04';
  static const _ackSignal = '\x06';
  static const _nakSignal = '\x15';
  bool _isConnected = false;
  Timer? _connectionTimer;
  int _reconnectAttempts = 0;
  static const int maxReconnectAttempts = 5;
  static const int reconnectTimeout = 60000;

  List<SerialPort> _serialPorts = [];
  final Map<String, String> portNamesMap = {};

  Future<void> openSerialPort(String portName) async {
    final serialPort = SerialPort(portName);
    serialPort.openReadWrite();
    _isConnected = true;
    _startConnectionTimer();
    setLastSerialPortInfo(portName);
    _serialPorts.add(serialPort);
  }

  Future<void> closeSerialPort() async {
    for (final serialPort in _serialPorts) {
      serialPort.close();
    }
    _serialPorts.clear();
  }

  Future<void> writePacket(String data) async {
    final packet = '$_startMarker$data$_endMarker';
    for (final serialPort in _serialPorts) {
      serialPort.write(Uint8List.fromList(packet.codeUnits));
    }
  }

  Future<String> readPacket() async {
    String packet = '';
    int startIndex = -1;
    int endIndex = -1;

    while (true) {
      for (final serialPort in _serialPorts) {
        final data = serialPort.read(1);
        if (data == null) {
          continue;
        }

        packet += String.fromCharCodes(data);

        if (startIndex == -1) {
          startIndex = packet.indexOf(_startMarker);
        }
        if (endIndex == -1) {
          endIndex = packet.indexOf(_endMarker);
        }

        if (startIndex != -1 && endIndex != -1) {
          final extractedPacket = packet.substring(startIndex + 1, endIndex);

          // Send ACK for valid packet
          for (final serialPort in _serialPorts) {
            serialPort.write(Uint8List.fromList(_ackSignal.codeUnits));
          }

          return extractedPacket;
        } else {
          // Send NAK for invalid packet
          for (final serialPort in _serialPorts) {
            serialPort.write(Uint8List.fromList(_nakSignal.codeUnits));
          }
          throw Exception('Invalid packet');
        }
      }
    }
  }

  void _startConnectionTimer() {
    _connectionTimer =
        Timer.periodic(const Duration(milliseconds: reconnectTimeout), (timer) {
      if (!_isConnected) {
        _reconnectAttempts++;

        if (_reconnectAttempts <= maxReconnectAttempts) {
          print('Intento de reconexión $_reconnectAttempts');
          openSerialPort(getLastSerialPortInfo());
        } else {
          print(
              'Error: No se pudo establecer la conexión después de $maxReconnectAttempts intentos.');
          _stopConnectionTimer();
        }
      }
    });
  }

  void _stopConnectionTimer() {
    _reconnectAttempts = 0;
    _connectionTimer?.cancel();
  }

  void setLastSerialPortInfo(String portName) {
    final file = File('lastserial_port.txt');
    file.writeAsStringSync(portName);
  }

  String getLastSerialPortInfo() {
    final file = File('lastserial_port.txt');
    return file.readAsStringSync();
  }

  void assignPortName(String portName, String assignedName) {
    portNamesMap[portName] = assignedName;
  }

  String getAssignedName(String portName) {
    return portNamesMap[portName] ?? portName;
  }

  void deleteSerialPortInfo() {
    final file = File('lastserial_port.txt');
    file.deleteSync();
  }

  void deleteSpecificSerialPortInfo(String portName) {
    final file = File('lastserial_port.txt');
    if (!file.existsSync()) {
      return;
    }
  }

  void openLastSerialPort() {
    final lastPort = getLastSerialPortInfo();
    openSerialPort(lastPort);
  }

  List<String> getAvailableSerialPorts() {
    return SerialPort.availablePorts;
  }

  void addNewSerialPort(String portName, String assignedName) {
    final file = File('serial_ports.txt');
    file.writeAsStringSync('$portName $assignedName\n', mode: FileMode.append);
  }

  void writeToLog(String signal, String portName, String assignedName) {
    final file = File('logSerial.txt');
    TimeOfDay now = TimeOfDay.now();
    file.writeAsStringSync('$now $portName $assignedName $signal\n',
        mode: FileMode.append);
  }

  List<String> getLoggedSignals() {
    final file = File('logSerial.txt');
    if (!file.existsSync()) {
      return [];
    }
    return file.readAsLinesSync();
  }

  List<String> getSerialPorts() {
    final file = File('serial_ports.txt');
    if (!file.existsSync()) {
      return [];
    }
    return file.readAsLinesSync();
  }

  List<String> getConnectedSerialPorts() {
    final file = File('serial_ports.txt');
    if (!file.existsSync()) {
      return [];
    }
    return file.readAsLinesSync();
  }
}
