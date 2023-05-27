import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:mya/aws_mqtt.dart';
import 'package:provider/provider.dart';
import 'tes.dart';
import 'ble_scan.dart';
import 'ble/ble_device_connector.dart';
import 'ble/ble_device_interactor.dart';
import 'ble/ble_scanner.dart';
import 'ble/ble_status_monitor.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:permission_handler/permission_handler.dart';
import 'ble/ble_logger.dart';
import 'bledata.dart';
import 'control.dart';
import 'mqtt_control.dart';
import 'myicon.dart';
import 'UserPage.dart';
import 'package:dropdown_button2/dropdown_button2.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  final _bleLogger = BleLogger();
  final _ble = FlutterReactiveBle();
  final _scanner = BleScanner(ble: _ble, logMessage: _bleLogger.addToLog);

  final _monitor = BleStatusMonitor(_ble);
  final _connector = BleDeviceConnector(
    ble: _ble,
    logMessage: _bleLogger.addToLog,
  );
  final _serviceDiscoverer = BleDeviceInteractor(
    bleDiscoverServices: _ble.discoverServices,
    readCharacteristic: _ble.readCharacteristic,
    writeWithResponse: _ble.writeCharacteristicWithResponse,
    writeWithOutResponse: _ble.writeCharacteristicWithoutResponse,
    subscribeToCharacteristic: _ble.subscribeToCharacteristic,
    logMessage: _bleLogger.addToLog,
  );
  runApp(
    /// Providers are above [MyApp] instead of inside it, so that tests
    /// can use [MyApp] while mocking the providers
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => Cou()),
        ChangeNotifierProvider<LedModel>(create: ((context) => LedModel())),
        ChangeNotifierProvider<UserLog>(create: ((context) => UserLog())),
        Provider.value(value: _scanner),
        Provider.value(value: _monitor),
        Provider.value(value: _connector),
        Provider.value(value: _serviceDiscoverer),
        Provider.value(value: _bleLogger),
        StreamProvider<BleScannerState?>(
          create: (_) => _scanner.state,
          initialData: const BleScannerState(
            discoveredDevices: [],
            scanIsInProgress: false,
          ),
        ),
        StreamProvider<BleStatus?>(
          create: (_) => _monitor.state,
          initialData: BleStatus.unknown,
        ),
        StreamProvider<ConnectionStateUpdate>(
          create: (_) => _connector.state,
          initialData: const ConnectionStateUpdate(
            deviceId: 'Unknown device',
            connectionState: DeviceConnectionState.disconnected,
            failure: null,
          ),
        ),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  //static const String _title = 'Flutter Code Sample';

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      // title: _title,
      // home: Scaffold(
      //   appBar: AppBar(title: const Text(_title)),
      //   body: const MyStatefulWidget(),
      // ),

      initialRoute: '/',
      routes: {
        '/': (context) => const MyStatefulWidget(),
        '/blecan': (context) => const blescan(),
        '/control': (context) => control(),
        '/mqttcontrol': ((context) => mqttControl())
      },
    );
  }
}

class MyStatefulWidget extends StatefulWidget {
  const MyStatefulWidget({super.key});

  @override
  State<MyStatefulWidget> createState() => _MyStatefulWidgetState();
}

class _MyStatefulWidgetState extends State<MyStatefulWidget> {
  int _currentIndex = 0; //记录当前选中哪个页面

  //第1步，声明PageController
  List<Widget> _pages = [MqttfulWidget(), UserPage()];
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_currentIndex == 0 ? "石铁" : "用户"),
        centerTitle: true,
        actions: _currentIndex == 0
            ? <Widget>[
                //导航栏右侧菜单
                IconButton(
                    icon: Icon(Icons.add_box_rounded),
                    onPressed: () async {
                      final result =
                          await Navigator.pushNamed(context, '/blecan');
                      log('message');
                      print(result);
                      Provider.of<BleScanner>(context, listen: false)
                          .stopScan();
                      Provider.of<BleScanner>(context, listen: false)
                          .clearState();
                      Provider.of<Cou>(context, listen: false).increment();
                    }),
                SizedBox(
                  width: 10,
                ),
              ]
            : null,
      ),
      body: _pages.elementAt(_currentIndex),
      bottomNavigationBar: BottomNavigationBar(
        selectedItemColor: Colors.amber[800],
        backgroundColor: Color.fromARGB(255, 96, 108, 221),
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            //第4步，设置点击底部Tab的时候的页面跳转
            _currentIndex = index;
          });
        },
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.account_circle_sharp),
            label: 'User',
          ),
        ],
      ),
    );
  }
}

class MqttfulWidget extends StatefulWidget {
  const MqttfulWidget({super.key});

  @override
  State<MqttfulWidget> createState() => _MqttfulWidgetState();
}

class _MqttfulWidgetState extends State<MqttfulWidget> {
  // bool _open = false;

  Widget buildGrid(Cou a) {
    List<Widget> tiles = []; //先建一个数组用于存放循环生成的widget
    Widget content; //单独一个widget组件，用于返回需要生成的内容widget
    a.devid = [];
    for (var item in a.get()) {
      a.devid.add(item['deviced_id']);
      tiles.add(Container(
        margin: const EdgeInsets.all(10),
        child: Column(children: <Widget>[
          DropdownButton2(
            customButton: GestureDetector(
              onTap: (() => {
                    Navigator.pushNamed(context, '/mqttcontrol', arguments: {
                      'deviceid': item['deviced_id'],
                      'iot_name': item['iot_name'],
                      'name': item['name'],
                    })
                  }),
              child: Column(
                children: [
                  Icon(
                    Charingicon.charing,
                    size: 30,
                    //  color: _open ? Colors.red : Colors.black,
                  ),
                  // const SizedBox(
                  //   height: 5,
                  // ),
                  Text(
                    item['name'],
                  ),
                ],
              ),
            ),
            onMenuStateChange: (value) {
              // setState(() {
              //   _open = value;
              // });
            },
            openWithLongPress: true,
            customItemsHeights: [
              ...List<double>.filled(MenuItems.firstItems.length, 48),
              // 8,
              // ...List<double>.filled(MenuItems.secondItems.length, 48),
            ],
            items: [
              ...MenuItems.firstItems.map(
                (item) => DropdownMenuItem<MenuItem>(
                  value: item,
                  child: MenuItems.buildItem(item),
                ),
              ),
              // const DropdownMenuItem<Divider>(enabled: false, child: Divider()),
              // ...MenuItems.secondItems.map(
              //   (item) => DropdownMenuItem<MenuItem>(
              //     value: item,
              //     child: MenuItems.buildItem(item),
              //   ),
              // ),
            ],
            onChanged: (value) {
              MenuItems.onChanged(
                  context, value as MenuItem, item['deviced_id']);
            },
            itemHeight: 48,
            itemPadding: const EdgeInsets.only(left: 16, right: 8),
            dropdownWidth: 130,
            dropdownPadding: const EdgeInsets.symmetric(vertical: 6),
            dropdownDecoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              color: Color.fromARGB(255, 27, 26, 26),
            ),
            dropdownElevation: 8,
            offset: const Offset(0, 8),
          ),
        ]),
      ));
    }
    content =
        Row(children: tiles //重点在这里，因为用编辑器写Column生成的children后面会跟一个<Widget>[]，
            //此时如果我们直接把生成的tiles放在<Widget>[]中是会报一个类型不匹配的错误，把<Widget>[]删了就可以了
            );
    return content;
  }

  void dd() async {
    var permissionble = await Permission.bluetooth.status;
    var permissionlocat = await Permission.location.status;
    if (!permissionble.isGranted) {
      await Permission.bluetooth.request();
    }
    if (!permissionlocat.isGranted) {
      await Permission.location.request();
    }

    print('dfs');
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    dd();
  }

  @override
  Widget build(BuildContext context) {
    Provider.of<Cou>(context, listen: false).increment();
    final ButtonStyle style =
        ElevatedButton.styleFrom(textStyle: const TextStyle(fontSize: 20));
    return Consumer<Cou>(builder: ((context, cou, child) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        // mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          buildGrid(cou),
          Column(
            children: const <Widget>[
              Text(
                '按右上角 + 号，添加设备',
                style: TextStyle(fontSize: 20),
              ),
              Text(
                '单击设备进入MQTT',
                style: TextStyle(fontSize: 20),
              ),
              Text('长按设备图标 删除 分享 设置 设备', style: TextStyle(fontSize: 20)),
              SizedBox(
                height: 30,
              )
            ],
          )
        ],
      );
    }));
  }
}

class MenuItem {
  final String text;
  final IconData icon;

  const MenuItem({
    required this.text,
    required this.icon,
  });
}

class MenuItems {
  static const List<MenuItem> firstItems = [delete, share, settings];
  //static const List<MenuItem> secondItems = [logout];

  static const delete = MenuItem(text: 'Delete', icon: Icons.delete);
  static const share = MenuItem(text: 'Share', icon: Icons.share);
  static const settings = MenuItem(text: 'Settings', icon: Icons.settings);
  //static const logout = MenuItem(text: 'Log Out', icon: Icons.logout);

  static Widget buildItem(MenuItem item) {
    return Row(
      children: [
        Icon(item.icon, color: Colors.white, size: 22),
        const SizedBox(
          width: 10,
        ),
        Text(
          item.text,
          style: const TextStyle(
            color: Colors.white,
          ),
        ),
      ],
    );
  }

  static onChanged(BuildContext context, MenuItem item, String deviced_id) {
    switch (item) {
      case MenuItems.delete:
        print(deviced_id);
        Provider.of<Cou>(context, listen: false).delete(deviced_id);
        //Do something
        break;
      case MenuItems.settings:
        //Do something
        break;
      case MenuItems.share:
        //Do something
        break;
      // case MenuItems.logout:
      //Do something
      //  break;
    }
  }
}
