import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:provider/provider.dart';
import 'tes.dart';
import 'ble/ble_scanner.dart';
import 'ble/ble_device_connector.dart';
import 'ble/ble_device_interactor.dart';
import 'bledata.dart';
import 'control.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:reactive_forms/reactive_forms.dart';

class blescan extends StatelessWidget {
  const blescan({super.key});
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('添加设备')),
      body: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) => Consumer<BleStatus?>(
        builder: (_, status, __) {
          if (status == BleStatus.ready) {
            Provider.of<BleScanner>(context, listen: false).stopScan();
            return AddWidget();
          } else {
            return BleStatusScreen(status: status ?? BleStatus.unknown);
            // return const DeviceListScreen();
          }
        },
      );
}

class BleStatusScreen extends StatelessWidget {
  const BleStatusScreen({required this.status, Key? key}) : super(key: key);

  final BleStatus status;

  String determineText(BleStatus status) {
    switch (status) {
      case BleStatus.unsupported:
        return "This device does not support Bluetooth";
      case BleStatus.unauthorized:
        return "Authorize the FlutterReactiveBle example app to use Bluetooth and location";
      case BleStatus.poweredOff:
        return "Bluetooth is powered off on your device turn it on";
      case BleStatus.locationServicesDisabled:
        return "Enable location services";
      case BleStatus.ready:
        return "Bluetooth is up and running";
      default:
        return "Waiting to fetch Bluetooth status $status";
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        body: Center(
          child: Text(determineText(status)),
        ),
      );
}

class AddWidget extends StatelessWidget {
  AddWidget({super.key});
  List<Uuid> serviceIds = [Uuid.parse("000000ff-0000-1000-8000-00805f9b34fb")];

  String name = '';
  int send = 0;
  int succ = 0;
  int needscan = 0;
  String _deviceid = '';
  FormGroup buildForm() => fb.group(<String, Object>{
        'name': ['', Validators.required, Validators.maxLength(8)],
      });
  @override
  Widget build(BuildContext context) {
    Future<void> _showMyDialog(String devid) async {
      return showDialog<void>(
        context: context,
        barrierDismissible: false, // user must tap button!
        builder: (context) {
          return AlertDialog(
            title: const Text('AlertDialog Title'),
            content: SingleChildScrollView(
              child: Column(
                children: <Widget>[
                  Consumer2<Cou, ConnectionStateUpdate>(
                      builder: ((context, cou, connectionStateUpdate, child) {
                    if (connectionStateUpdate.connectionState !=
                        DeviceConnectionState.connected) {
                      return const Text('正在连接ble');
                    } else {
                      return ble_text(cou.state);
                    }
                  })),
                  TextField(onChanged: ((value) => name = value)),
                ],
              ),
            ),
            actions: <Widget>[
              Consumer3<BleDeviceConnector, ConnectionStateUpdate,
                      BleDeviceInteractor>(
                  builder: (_, deviceConnector, connectionStateUpdate,
                      serviceDiscoverer, __) {
                if (connectionStateUpdate.connectionState ==
                    DeviceConnectionState.connected) {
                  print('conn succ');
                  return TextButton(
                      onPressed: () async {
                        final characteristic0 = QualifiedCharacteristic(
                            serviceId: Uuid.parse(
                                "000000FF-0000-1000-8000-00805F9B34FB"),
                            characteristicId: Uuid.parse(
                                "0000FF01-0000-1000-8000-00805F9B34FB"),
                            deviceId: devid);

                        serviceDiscoverer
                            .readCharacteristic(characteristic0)
                            .then((value) {
                          print(value);
                          if (value[0] == 1) {
                            print('1');
                            succ = 1;
                            getData(context, serviceDiscoverer, deviceConnector,
                                devid, name);
                          } else {
                            print('0');
                            serviceDiscoverer
                                .subScribeToCharacteristic(characteristic0)
                                .listen((event) {
                              print(value[0]);
                              succ = 1;
                              getData(context, serviceDiscoverer,
                                  deviceConnector, devid, name);
                            });
                          }
                        });

                        print('ff');
                      },
                      child: const Text('sure'));
                } else {
                  if (succ == 0) {
                    deviceConnector.connect(devid);
                    print('to conn');
                  }
                  return const TextButton(onPressed: null, child: Text('sure'));
                }
              }),
              TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Text('取消'))
            ],
          );
        },
      );
    }

    return Consumer5<BleScanner, BleScannerState?, BleDeviceConnector,
            ConnectionStateUpdate, BleDeviceInteractor>(
        builder: (_, bleScanner, bleScannerState, deviceConnector,
            connectionStateUpdate, serviceDiscoverer, child) {
      if (bleScannerState!.discoveredDevices.isNotEmpty) {
        print('搜到设备');
        print(bleScannerState.discoveredDevices[0].id);
        _deviceid = bleScannerState.discoveredDevices[0].id;
        if (connectionStateUpdate.connectionState ==
            DeviceConnectionState.connected) {
          succ = 1;
          print('连接成功');
        } else {
          if (succ == 0) {
            deviceConnector.connect(bleScannerState.discoveredDevices[0].id);
            print('连接设备');
          }
        }
        print('界面');
        return SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(
            horizontal: 20.0,
            vertical: 20.0,
          ),
          child: Column(children: [
            Text('搜到设备MAC:${bleScannerState.discoveredDevices[0].id}'),
            Text(succ == 1 ? '连接成功' : '正在连接...'),
            SizedBox(
              height: 10,
            ),
            ReactiveFormBuilder(
              form: buildForm,
              builder: (context, form, child) {
                return Column(
                  children: [
                    ReactiveTextField<String>(
                      formControlName: 'name',
                      // obscureText: true,
                      validationMessages: {
                        ValidationMessage.required: (_) =>
                            'The name must not be empty',
                        ValidationMessage.maxLength: (_) =>
                            'The name must be at least 8 characters',
                      },
                      textInputAction: TextInputAction.done,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        floatingLabelBehavior: FloatingLabelBehavior.auto,
                        alignLabelWithHint: true,
                        labelText: 'Name',
                        helperText: '',
                        helperStyle: TextStyle(height: 0.7),
                        errorStyle: TextStyle(height: 0.7),
                      ),
                    ),
                    const SizedBox(height: 5.0),
                    b_text(send),
                    const SizedBox(height: 5.0),
                    ElevatedButton(
                      onPressed: (succ == 1 && send == 0)
                          ? () {
                              if (form.valid) {
                                print(form.value);
                                name = form.value['name'].toString();

                                send = 1;
                                final characteristic0 = QualifiedCharacteristic(
                                    serviceId: Uuid.parse(
                                        "000000FF-0000-1000-8000-00805F9B34FB"),
                                    characteristicId: Uuid.parse(
                                        "0000FF01-0000-1000-8000-00805F9B34FB"),
                                    deviceId: bleScannerState
                                        .discoveredDevices[0].id);

                                serviceDiscoverer
                                    .readCharacteristic(characteristic0)
                                    .then((value) {
                                  print(value);
                                  if (value[0] == 1) {
                                    print('1');
                                    succ = 1;
                                    getData(
                                        context,
                                        serviceDiscoverer,
                                        deviceConnector,
                                        bleScannerState.discoveredDevices[0].id,
                                        name);
                                  } else {
                                    print('0');
                                    serviceDiscoverer
                                        .subScribeToCharacteristic(
                                            characteristic0)
                                        .listen((event) {
                                      print(value[0]);
                                      succ = 1;
                                      getData(
                                          context,
                                          serviceDiscoverer,
                                          deviceConnector,
                                          bleScannerState
                                              .discoveredDevices[0].id,
                                          name);
                                    });
                                  }
                                });

                                print('ff');
                              } else {
                                form.markAllAsTouched();
                              }
                            }
                          : null,
                      child: const Text('Sign Up'),
                    ),
                  ],
                );
              },
            ),
          ]),
        );
      } else {
        print('scan');
        if (!bleScannerState.scanIsInProgress && needscan == 0) {
          List<String> idlist = Provider.of<Cou>(context).devid;
          idlist.add(_deviceid);
          print(idlist);
          bleScanner.startScan(serviceIds, idlist);
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const Text(
              '正在搜索设备....',
              style: TextStyle(fontSize: 20),
            ),
            Expanded(
                child: Align(
              alignment: FractionalOffset(0.5, 0.5),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  LoadingAnimationWidget.staggeredDotsWave(
                    color: Color.fromARGB(255, 119, 163, 212),
                    size: 60,
                  ),
                  Text('请靠近设备')
                ],
              ),
            )),
          ],
        );
      }
    });
  }
}

Future<void> getData(BuildContext context, BleDeviceInteractor servic,
    BleDeviceConnector con, String deviceid, String name) async {
  String clientPem = '';
  String clientKey = '';
  String clientId = '';
  List chars = [];
  print(name);
  Map<String, Object?> a = {
    'client_pem': '',
    'client_key': '',
    'client_id': '',
    'iot_name': '',
    'name': '',
    'deviced_id': '',
    'ble_type': 0
  };

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

  Provider.of<Cou>(context, listen: false).setState(3);
  clientPem = clientPem +
      String.fromCharCodes(await servic.readCharacteristic(characteristic1));
  print('1');
  clientPem = clientPem +
      String.fromCharCodes(await servic.readCharacteristic(characteristic2));
  print('2');
  clientPem = clientPem +
      String.fromCharCodes(await servic.readCharacteristic(characteristic3));
  print('3');
  clientKey = clientKey +
      String.fromCharCodes(await servic.readCharacteristic(characteristic4));
  print('4');
  clientKey = clientKey +
      String.fromCharCodes(await servic.readCharacteristic(characteristic5));
  print('5');
  clientKey = clientKey +
      String.fromCharCodes(await servic.readCharacteristic(characteristic6));
  print('6');
  clientKey = clientKey +
      String.fromCharCodes(await servic.readCharacteristic(characteristic7));
  print('7');
  // ignore: prefer_interpolation_to_compose_strings
  clientId =
      String.fromCharCodes(await servic.readCharacteristic(characteristic8));
  print(clientId.length);
  Provider.of<Cou>(context, listen: false).setState(0);
  a['name'] = name;
  a['deviced_id'] = deviceid;
  a['client_pem'] = clientPem;
  a['client_key'] = clientKey;
  a['client_id'] = '${clientId}_1';
  a['iot_name'] = clientId.split("_")[1];
  // await DBManager().update(a, deviceid);
  DBManager().saveData(BleData.fromMap(a));
  // Provider.of<BleScanner>(context, listen: false).stopScan();
  // Provider.of<BleScanner>(context, listen: false).clearState();
  con.disconnect(deviceid);
  // Navigator.of(context).pushNamedAndRemoveUntil('/', (Route route) => false,
  //     arguments: deviceid);
  Navigator.pop(context);
}

// ignore: non_constant_identifier_names
Row ble_text(int state) {
  switch (state) {
    case 1:
      return Row(
        children: [
          const Text('正在连接蓝牙'),
          const SizedBox(width: 20),
          LoadingAnimationWidget.hexagonDots(
            color: Color.fromARGB(255, 119, 163, 212),
            size: 20,
          ),
        ],
      );
    case 2:
      return Row(
        children: [
          const Text('正在连接蓝牙'),
          const SizedBox(width: 20),
          LoadingAnimationWidget.hexagonDots(
            color: Color.fromARGB(255, 119, 163, 212),
            size: 20,
          ),
        ],
      );
    case 3:
      return Row(
        children: [
          const Text('正在传输数据'),
          const SizedBox(width: 20),
          LoadingAnimationWidget.hexagonDots(
            color: Color.fromARGB(255, 119, 163, 212),
            size: 20,
          ),
        ],
      );
    case 4:
      return Row(
        children: const [Text('传输完成')],
      );
    default:
      return Row(
        children: const [Text('请确认')],
      );
  }
}

Row b_text(int state) {
  if (state == 1) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text('正在传输数据'),
        const SizedBox(width: 20),
        LoadingAnimationWidget.hexagonDots(
          color: Color.fromARGB(255, 119, 163, 212),
          size: 20,
        ),
      ],
    );
  } else {
    return Row(
      children: [
        const Text(''),
      ],
    );
  }
}
