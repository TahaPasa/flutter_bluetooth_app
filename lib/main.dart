import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'package:yeni_app/BluetoothDeviceListEntry.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:yeni_app/detailpage.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> with WidgetsBindingObserver {

  BluetoothState _bluetoothState = BluetoothState.UNKNOWN;

  List<BluetoothDevice> devices = <BluetoothDevice>[];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _getBTState();
    _stateChangeListener();
    _listBondedDevices();
    Permission.bluetooth.request();
    Permission.bluetoothConnect.request();
    Permission.bluetoothAdvertise.request();
    Permission.bluetoothScan.request();
  }

  @override
  void dispose(){
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state){
    if(state.index ==0){
      //resume
      if(_bluetoothState.isEnabled){
        _listBondedDevices();
      }
    }

  }

  _getBTState(){
    FlutterBluetoothSerial.instance.state.then((state){
      _bluetoothState = state;
      if(_bluetoothState.isEnabled){
        _listBondedDevices();
      }
      setState(() {});
    });
  }

  _stateChangeListener(){
    FlutterBluetoothSerial.instance.onStateChanged().listen((BluetoothState state) {
        _bluetoothState = state;
        if(_bluetoothState.isEnabled){
          _listBondedDevices();
        }else{
          devices.clear();
        }
        print("state is enabled: ${state}");
        setState(() {});
    });
  }

  _listBondedDevices(){
    FlutterBluetoothSerial.instance.getBondedDevices().then((List<BluetoothDevice> bondedDevices){
      devices=bondedDevices;
      print("TotalNumber Of devices: ${devices.length}");
      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            SwitchListTile(
              title: Text("Enable Bluetooth"),
                value: _bluetoothState.isEnabled,
                onChanged: (bool value){
                  future() async{
                    if(value){
                      await FlutterBluetoothSerial.instance.requestEnable();
                    }else{
                      await FlutterBluetoothSerial.instance.requestDisable();
                    }
                    future().then((_){
                      setState(() {});
                    });
                  }
                }
            ),
            ListTile(
              title: Text("Bluetooth STATUS"),
              subtitle: Text(_bluetoothState.toString()),
              trailing: ElevatedButton(
                child: Text("Settings"),
                  onPressed: () {
                    FlutterBluetoothSerial.instance.openSettings();
                    _listBondedDevices();
                  },
              ),
            ),
            Expanded(child: ListView(children: devices.map((_device) => BluetoothDeviceListEntry(
              device: _device,
              enabled: true,
              onTap: () {
                print("Item");
                _startDataConnect(context,_device);
              },

            )).toList(),))
          ],
        ),
      ),

    );
  }

  void _startDataConnect(BuildContext context,BluetoothDevice server){

    Navigator.of(context).push(MaterialPageRoute(builder: (context) {
      return DetailPage(server: server);
    },));

  }
}
