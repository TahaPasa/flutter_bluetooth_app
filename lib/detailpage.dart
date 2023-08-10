import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:async/async.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';


class DetailPage extends StatefulWidget {

  final BluetoothDevice server;
  const DetailPage({required this.server});

  @override
  State<DetailPage> createState() => _DetailPageState();
}

class _DetailPageState extends State<DetailPage> {

  late StreamController<String> _dataStreamController; // Add this line
  String receivedData = '';
  BluetoothConnection? connection;
  bool isConnecting = true;
  bool get isConnected => connection != null && connection!.isConnected;
  bool isDisconnecting = false;

  List<List<int>> chunks  = <List<int>>[];
  int contentLength = 0;
  late Uint8List _bytes = Uint8List(0);

  late RestartableTimer _timer;

  @override
  void initState() {
    super.initState();
    _dataStreamController = StreamController<String>();
    _getBTConnection();
    _timer = RestartableTimer(Duration(seconds: 1), _writeData);
  }

  @override
  void dispose(){
    _dataStreamController.close(); // Close the StreamController
    if(isConnected){
      isDisconnecting = true;
      connection!.dispose();
      connection = null;
    }
    _timer.cancel();
    super.dispose();
  }

  _getBTConnection()
  {
    BluetoothConnection.toAddress(widget.server.address).then((_connection) {
      connection = _connection;
      isConnecting = false;
      isDisconnecting = false;
      setState(() {});
      connection!.input!.listen((_onDataRecieved)).onDone(() {
        if(isDisconnecting){
          print("DISCONNECTING Locally");
        }else{
          print("DISCONNECTING REMOTELY!");
        }
        if(this.mounted){
          setState(() {});
        }
        Navigator.of(context).pop();
      });

    }).catchError((error){
      Navigator.of(context).pop();
    });
  }

  _writeData(){
    if(chunks.length ==0 || contentLength ==0){
      return;
    }
    _bytes = Uint8List(contentLength);
    int offset =0;
    for(final List<int> chunk in chunks){
      _bytes.setRange(offset, offset+chunk.length, chunk);
      offset+= chunk.length;
    }
    setState(() {

    });

    contentLength =0;
    chunks.clear();
  }


  _onDataRecieved(Uint8List data) {
    if (data != null && data.length > 0) {
      String newData = utf8.decode(data); // Convert bytes to string
      receivedData += newData; // Append the new data to receivedData
      _dataStreamController.add(receivedData); // Add the data to the stream
      _timer.reset();
    }

    print("Data Length: ${data.length}, receivedData Length: ${receivedData.length}");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
        appBar: AppBar(title: (isConnecting ? Text("Connecting to ${widget.server.name}...") : isConnected ? Text("Connected with ${widget.server.name}")
            : Text("Disonnected with ${widget.server.name}"))),
      body: SafeArea(
        child: isConnected
            ? StreamBuilder<String>(
          stream: _dataStreamController.stream, // Provide the stream to listen for new data
          initialData: receivedData, // Set initial data
          builder: (context, snapshot) {
            return Column(
              children: [
                Text(snapshot.data!,style: TextStyle(color: Colors.white)), // Display the received data from the snapshot
              ],
            );
          },
        )
            : Center(
          child: Text(
            "Connecting...",
            style: TextStyle(
                fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
          ),
        ),
      ),
    );
  }
}

