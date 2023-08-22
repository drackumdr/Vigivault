import 'package:flutter/material.dart';
import 'serial_helper.dart';
import 'tcp_helper.dart';

class ConnectUI extends StatefulWidget {
  const ConnectUI({super.key});

  @override
  _ConnectUIState createState() => _ConnectUIState();
}

class _ConnectUIState extends State<ConnectUI> {
  final SerialHelper serialHelper = SerialHelper();
  final TcpHelper tcpHelper = TcpHelper();
  final TextEditingController ipAddressController = TextEditingController();
  final TextEditingController portController = TextEditingController();
  final TextEditingController assignedNameController = TextEditingController();

  @override
  void dispose() {
    serialHelper.closeSerialPort();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ConnectUI'),
      ),
      body: Row(
        children: [
          Expanded(
            flex: 1,
            child: Column(
              children: [
                const Text('Available Serial Ports'),
                ElevatedButton(
                  onPressed: () {
                    final availablePorts =
                        serialHelper.getAvailableSerialPorts();
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Select Serial Port'),
                        content: Column(
                          children: availablePorts.map((port) {
                            return ListTile(
                              title: Text(port),
                              onTap: () {
                                serialHelper.openSerialPort(port);
                                Navigator.pop(context);
                              },
                            );
                          }).toList(),
                        ),
                      ),
                    );
                  },
                  child: const Text('Connect to Serial Port'),
                ),
                const Text('Connected Ports'),
                ElevatedButton(
                  onPressed: () {
                    serialHelper.closeSerialPort();
                  },
                  child: const Text('Disconnect'),
                ),
                const Text('Add TCP Connection'),
                ElevatedButton(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Add TCP Connection'),
                        content: Column(
                          children: [
                            TextField(
                              controller: ipAddressController,
                              decoration: const InputDecoration(
                                labelText: 'IP Address',
                              ),
                            ),
                            TextField(
                              controller: portController,
                              decoration: const InputDecoration(
                                labelText: 'Port',
                              ),
                            ),
                            TextField(
                              controller: assignedNameController,
                              decoration: const InputDecoration(
                                labelText: 'Assigned Name',
                              ),
                            ),
                          ],
                        ),
                        actions: [
                          ElevatedButton(
                            onPressed: () {
                              final ipAddress = ipAddressController.text;
                              final port = int.parse(portController.text);
                              final assignedName = assignedNameController.text;
                              tcpHelper.connectToTcp(ipAddress, port);
                              tcpHelper.assignConnectionName(
                                  ipAddress, port, assignedName);
                              Navigator.pop(context);
                            },
                            child: const Text('Add'),
                          ),
                        ],
                      ),
                    );
                  },
                  child: const Icon(Icons.add),
                ),
                const Text('TCP Connections'),
                ElevatedButton(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('TCP Connections'),
                        content: Column(
                          children:
                              tcpHelper.getTcpConnections().map((connection) {
                            final connectionInfo = connection.split(' ');
                            final ipAddress = connectionInfo[0];
                            final port = int.parse(connectionInfo[1]);
                            final assignedName = connectionInfo[2];
                            return ListTile(
                              title: Text('$ipAddress:$port ($assignedName)'),
                              trailing: IconButton(
                                icon: const Icon(Icons.delete),
                                onPressed: () {
                                  tcpHelper.deleteSpecificTcpConnectionInfo(
                                      ipAddress, port);
                                  setState(() {});
                                },
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    );
                  },
                  child: const Text('View TCP Connections'),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 1,
            child: Column(
              children: [
                const Text('Received Signals'),
                ElevatedButton(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Received Signals'),
                        content: Column(
                          children: [
                            ElevatedButton(
                              onPressed: () {
                                // Clear received signals
                              },
                              child: const Text('Clear'),
                            ),
                            ElevatedButton(
                              onPressed: () {
                                // Filter signals by specific port
                              },
                              child: const Text('Filter by Port'),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                  child: const Text('View Received Signals'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
