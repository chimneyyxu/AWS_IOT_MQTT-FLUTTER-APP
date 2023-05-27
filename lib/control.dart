import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'tes.dart';
import 'ble_scan.dart';
import 'ble/ble_device_connector.dart';
import 'ble/ble_device_interactor.dart';
import 'ble/ble_scanner.dart';
import 'ble/ble_status_monitor.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'ble/ble_logger.dart';
import 'bledata.dart';
import 'aws_mqtt.dart';

// A Widget that extracts the necessary arguments from
// the ModalRoute.
class control extends StatelessWidget {
  control({super.key});
  @override
  Widget build(BuildContext context) {
    // Extract the arguments from the current ModalRoute
    // settings and cast them as ScreenArguments.
    String devcid = ModalRoute.of(context)!.settings.arguments as String;

    return Scaffold(
      appBar: AppBar(
        title: Text('df'),
      ),
      body: Center(
        child: DeviceInteractionTab(deviceid: devcid),
      ),
    );
  }
}

class DeviceInteractionTab extends StatelessWidget {
  final String deviceid;

  DeviceInteractionTab({
    required this.deviceid,
    Key? key,
  }) : super(key: key);

  String client_pem = '';
  String client_key = '';
  String client_id = '';
  List chars = [];

  Map<String, Object?> a = {
    'client_pem': '',
    'client_key': '',
    'client_id': '',
    'iot_name': ''
  };

  @override
  Widget build(BuildContext context) {
    final characteristic0 = QualifiedCharacteristic(
        serviceId: Uuid.parse("000000FF-0000-1000-8000-00805F9B34FB"),
        characteristicId: Uuid.parse("0000FF01-0000-1000-8000-00805F9B34FB"),
        deviceId: deviceid);
    final characteristic1 = QualifiedCharacteristic(
        serviceId: Uuid.parse("000000FF-0000-1000-8000-00805F9B34FB"),
        characteristicId: Uuid.parse("0000FF02-0000-1000-8000-00805F9B34FB"),
        deviceId: deviceid);
    final characteristic2 = QualifiedCharacteristic(
        serviceId: Uuid.parse("000000FF-0000-1000-8000-00805F9B34FB"),
        characteristicId: Uuid.parse("0000FF03-0000-1000-8000-00805F9B34FB"),
        deviceId: deviceid);

    final characteristic3 = QualifiedCharacteristic(
        serviceId: Uuid.parse("000000FF-0000-1000-8000-00805F9B34FB"),
        characteristicId: Uuid.parse("0000FF04-0000-1000-8000-00805F9B34FB"),
        deviceId: deviceid);

    final characteristic4 = QualifiedCharacteristic(
        serviceId: Uuid.parse("000000FF-0000-1000-8000-00805F9B34FB"),
        characteristicId: Uuid.parse("0000FF05-0000-1000-8000-00805F9B34FB"),
        deviceId: deviceid);
    final characteristic5 = QualifiedCharacteristic(
        serviceId: Uuid.parse("000000FF-0000-1000-8000-00805F9B34FB"),
        characteristicId: Uuid.parse("0000FF06-0000-1000-8000-00805F9B34FB"),
        deviceId: deviceid);

    final characteristic6 = QualifiedCharacteristic(
        serviceId: Uuid.parse("000000FF-0000-1000-8000-00805F9B34FB"),
        characteristicId: Uuid.parse("0000FF07-0000-1000-8000-00805F9B34FB"),
        deviceId: deviceid);
    final characteristic7 = QualifiedCharacteristic(
        serviceId: Uuid.parse("000000FF-0000-1000-8000-00805F9B34FB"),
        characteristicId: Uuid.parse("0000FF08-0000-1000-8000-00805F9B34FB"),
        deviceId: deviceid);
    final characteristic8 = QualifiedCharacteristic(
        serviceId: Uuid.parse("000000FF-0000-1000-8000-00805F9B34FB"),
        characteristicId: Uuid.parse("0000FF09-0000-1000-8000-00805F9B34FB"),
        deviceId: deviceid);

    void getData(BleDeviceInteractor servic) async {
      client_pem = client_pem +
          String.fromCharCodes(
              await servic.readCharacteristic(characteristic1));
      print('1');
      client_pem = client_pem +
          String.fromCharCodes(
              await servic.readCharacteristic(characteristic2));
      print('2');
      client_pem = client_pem +
          String.fromCharCodes(
              await servic.readCharacteristic(characteristic3));
      print('3');
      client_key = client_key +
          String.fromCharCodes(
              await servic.readCharacteristic(characteristic4));
      print('4');
      client_key = client_key +
          String.fromCharCodes(
              await servic.readCharacteristic(characteristic5));
      print('5');
      client_key = client_key +
          String.fromCharCodes(
              await servic.readCharacteristic(characteristic6));
      print('6');
      client_key = client_key +
          String.fromCharCodes(
              await servic.readCharacteristic(characteristic7));
      print('7');
      // ignore: prefer_interpolation_to_compose_strings
      client_id = String.fromCharCodes(
          await servic.readCharacteristic(characteristic8));
      print(client_id.length);
      a['client_pem'] = client_pem;
      a['client_key'] = client_key;
      a['client_id'] = '${client_id}_1';
      a['iot_name'] = client_id.split("_")[1];
      DBManager().update(a, deviceid);
      // my_mqtt(deviceid);
    }

    return Consumer3<BleDeviceConnector, ConnectionStateUpdate,
            BleDeviceInteractor>(
        builder:
            (_, deviceConnector, connectionStateUpdate, serviceDiscoverer, __) {
      print(connectionStateUpdate.connectionState);
      if (connectionStateUpdate.connectionState ==
          DeviceConnectionState.connected) {
        print('conn succ');
        serviceDiscoverer.readCharacteristic(characteristic0).then((value) {
          print(value);
          if (value[0] == 1) {
            print('1');
            getData(serviceDiscoverer);
          } else {
            print('0');
            serviceDiscoverer
                .subScribeToCharacteristic(characteristic0)
                .listen((event) {
              print(value[0]);
              getData(serviceDiscoverer);
            });
          }
        });
      } else {
        deviceConnector.connect(deviceid);
        print('fail');
      }
      return Column();
    });
  }
}
