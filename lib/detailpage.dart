import 'dart:async';
import 'dart:convert';
import 'dart:ffi';
import 'dart:typed_data';
import 'package:async/async.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'package:fl_chart/fl_chart.dart';


class DetailPage extends StatefulWidget {

  final BluetoothDevice server;
  const DetailPage({required this.server});

  @override
  State<DetailPage> createState() => _DetailPageState();
}

class _DetailPageState extends State<DetailPage> {

  late StreamController<List<int>> _dataStreamController;
  String receivedData = '';
  BluetoothConnection? connection;
  bool isConnecting = true;

  bool get isConnected => connection != null && connection!.isConnected;
  bool isDisconnecting = false;

  List<List<int>> chunks = <List<int>>[];
  int contentLength = 0;
  late Uint8List _bytes = Uint8List(0);

  late RestartableTimer _timer;
  List<int> allReceivedData = [];


  @override
  void initState() {
    super.initState();
    _dataStreamController = StreamController<List<int>>();
    _getBTConnection();
    _timer = RestartableTimer(Duration(seconds: 1), _writeData);
  }

  @override
  void dispose() {
    _dataStreamController.close(); // Close the StreamController
    if (isConnected) {
      isDisconnecting = true;
      connection!.dispose();
      connection = null;
    }
    _timer.cancel();
    super.dispose();
  }

  _getBTConnection() {
    BluetoothConnection.toAddress(widget.server.address).then((_connection) {
      connection = _connection;
      isConnecting = false;
      isDisconnecting = false;
      setState(() {});
      connection!.input!.listen((_onDataRecieved)).onDone(() {
        if (isDisconnecting) {
          print("DISCONNECTING Locally");
        } else {
          print("DISCONNECTING REMOTELY!");
        }
        if (this.mounted) {
          setState(() {});
        }
        Navigator.of(context).pop();
      });
    }).catchError((error) {
      Navigator.of(context).pop();
    });
  }

  _writeData() {
    if (chunks.length == 0 || contentLength == 0) {
      return;
    }
    _bytes = Uint8List(contentLength);
    int offset = 0;
    for (final List<int> chunk in chunks) {
      _bytes.setRange(offset, offset + chunk.length, chunk);
      offset += chunk.length;
    }
    setState(() {

    });

    contentLength = 0;
    chunks.clear();
  }


  _onDataRecieved(Uint8List data) {
    // Convert the received data to a String
    String receivedString = String.fromCharCodes(data);

    // Append the received data to the existing data
    receivedData += receivedString;

    // Process the received data
    List<String> values = receivedData.split(',');

    // Ensure that there are at least two values separated by a comma
    if (values.length >= 2) {
      // Parse the first value (integer part)
      int analogValue = int.tryParse(values[0]) ?? 0;
      allReceivedData.add(analogValue);
      _dataStreamController.add(allReceivedData);
      _timer.reset();
      print("Analog Value: $analogValue");

      // Remove the processed data from the receivedData string
      receivedData = values[1];
    }

    print("Data Length: ${data.length}");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(title: (isConnecting ? Text("Connecting to ${widget.server.name}...") : isConnected ? Text("Connected with ${widget.server.name}")
          : Text("Disonnected with ${widget.server.name}"))),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0,vertical: 120),
        child: SafeArea(
          child: isConnected
              ? StreamBuilder<List<int>>(
            stream: _dataStreamController.stream,
            initialData: [], // Set initial data as an empty list
            builder: (context, snapshot) {
              final List<int> data = allReceivedData; // Use all received data

              // Prepare the data points for the line chart
              List<FlSpot> spots = [];
              int startIndex = data.length > 100 ? data.length - 100 : 0; // Ekranda 100 veriye kadar gösteriyor eskilerini siliyor.

              for (int i = startIndex; i < data.length; i++) {
                spots.add(FlSpot((i - startIndex).toDouble(), data[i].toDouble()));
              }


              return Container(
                alignment: Alignment.centerLeft,
                color: Colors.white,
                child: LineChart(

                  LineChartData(
                    gridData: FlGridData(show: true,), // Turn on grid lines
                    borderData: FlBorderData(show: false), // Turn off border
                    lineBarsData: [

                      LineChartBarData(
                        color: Colors.green,
                        spots: spots,
                        dotData: FlDotData(show: true,getDotPainter: (p0, p1, p2, p3) {
                          return FlDotCirclePainter(radius: 1);
                        },),



                      ),
                    ],
                  ),

                ),
              );
            },
          )
              : Center(

            child: Column(
              children: [
                Text(
                  "Connecting...",
                  style: TextStyle(
                      fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white
                  ),
                ),
                CircularProgressIndicator(),
              ],
            ),

          ),
        ),
      ),
    );
  }
}
