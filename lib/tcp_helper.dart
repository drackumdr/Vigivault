//tcp_helper.dart

import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

class TcpHelper {
  static const _startMarker = '\x01';
  static const _endMarker = '\x04';
  static const _ackSignal = '\x06';
  static const _nakSignal = '\x15';
  final List<Socket> _activeConnections = [];
  final Map<String, String> connectionNamesMap = {};

  Future<void> connectToTcp(String ipAddress, int port) async {
    final socket = await Socket.connect(ipAddress, port);
    _activeConnections.add(socket);
    _startConnectionHandler(socket);
    print('Connected to: $ipAddress:$port');
  }

  Future<void> closeTcpConnection(Socket socket) async {
    socket.close();
    _activeConnections.remove(socket);
  }

  Future<void> sendPacket(Socket socket, String data) async {
    final packet = '$_startMarker$data$_endMarker';
    socket.add(Uint8List.fromList(packet.codeUnits));
  }

  Future<String> receivePacket(Socket socket) async {
    String packet = '';
    int startIndex = -1;
    int endIndex = -1;

    while (true) {
      final data = await socket.first;
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
        socket.add(Uint8List.fromList(_ackSignal.codeUnits));

        return extractedPacket;
      } else {
        // Send NAK for invalid packet
        socket.add(Uint8List.fromList(_nakSignal.codeUnits));
        throw Exception('Invalid packet');
      }
    }
  }

  void _startConnectionHandler(Socket socket) {
    socket.listen((data) {
      // Handle received data from the socket
      final receivedPacket = String.fromCharCodes(data);
      // Process the received packet as needed
      print('Received packet: $receivedPacket');
    }, onError: (error) {
      // Handle socket error
      print('Socket error: $error');
      closeTcpConnection(socket);
    }, onDone: () {
      // Handle socket closed
      print('Socket closed');
      closeTcpConnection(socket);
    });
  }

  void assignConnectionName(String ipAddress, int port, String assignedName) {
    final connectionKey = '$ipAddress:$port';
    connectionNamesMap[connectionKey] = assignedName;
  }

  String getConnectionName(String ipAddress, int port) {
    final connectionKey = '$ipAddress:$port';
    return connectionNamesMap[connectionKey] ?? connectionKey;
  }

  void deleteTcpConnectionInfo() {
    final file = File('last_tcp_connection.txt');
    file.deleteSync();
  }

  void deleteSpecificTcpConnectionInfo(String ipAddress, int port) {
    final file = File('last_tcp_connection.txt');
    if (!file.existsSync()) {
      return;
    }
    final lines = file.readAsLinesSync();
    final newLines = lines.where((line) {
      final connectionInfo = line.split(' ');
      return connectionInfo[0] != ipAddress || connectionInfo[1] != port;
    });
    file.writeAsStringSync(newLines.join('\n'));
  }

  void openLastTcpConnection() {
    final lastConnectionInfo =
        File('last_tcp_connection.txt').readAsStringSync().split(' ');
    final ipAddress = lastConnectionInfo[0];
    final port = int.parse(lastConnectionInfo[1]);
    final assignedName = lastConnectionInfo[2];
    connectToTcp(ipAddress, port);
  }

  void addNewTcpConnection(String ipAddress, int port, String assignedName) {
    final file = File('tcp_connections.txt');
    file.writeAsStringSync('$ipAddress $port $assignedName\n',
        mode: FileMode.append);
  }

  void writeToLog(
      String signal, String ipAddress, int port, String assignedName) {
    final file = File('logTcp.txt');
    final now = DateTime.now();
    file.writeAsStringSync('$now $ipAddress $port $assignedName $signal\n',
        mode: FileMode.append);
  }

  List<String> getLoggedSignals() {
    final file = File('logTcp.txt');
    if (!file.existsSync()) {
      return [];
    }
    return file.readAsLinesSync();
  }

  List<String> getTcpConnections() {
    final file = File('tcp_connections.txt');
    if (!file.existsSync()) {
      return [];
    }
    return file.readAsLinesSync();
  }

  List<String> getActiveTcpConnections() {
    final activeConnections = _activeConnections.map((socket) {
      final ipAddress = socket.remoteAddress.address;
      final port = socket.remotePort;
      final assignedName = getConnectionName(ipAddress, port);
      return '$ipAddress $port $assignedName';
    });
    return activeConnections.toList();
  }

  List<String> getReceivedSignals() {
    final receivedSignals = _activeConnections.map((socket) {
      final ipAddress = socket.remoteAddress.address;
      final port = socket.remotePort;
      final assignedName = getConnectionName(ipAddress, port);
      return '$ipAddress $port $assignedName';
    });
    return receivedSignals.toList();
  }
}
