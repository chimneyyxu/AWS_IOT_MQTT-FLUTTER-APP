import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'aws_mqtt.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'myicon.dart';

// A Widget that extracts the necessary arguments from
// the ModalRoute.
class mqttControl extends StatelessWidget {
  mqttControl({super.key});
  @override
  Widget build(BuildContext context) {
    // Extract the arguments from the current ModalRoute
    // settings and cast them as ScreenArguments.
    final argumentsData = ModalRoute.of(context)!.settings.arguments as Map;
    return Scaffold(
      appBar: AppBar(
        title: Text('MQTT'),
      ),
      body: Center(
        child: DeviceInteractionTab(
          deviceid: argumentsData['deviceid'],
          iot_name: argumentsData['iot_name'],
          name: argumentsData['name'],
        ),
      ),
    );
  }
}

class DeviceInteractionTab extends StatelessWidget {
  final String deviceid;
  final String iot_name;
  final String name;
  DeviceInteractionTab({
    required this.deviceid,
    required this.iot_name,
    required this.name,
    Key? key,
  }) : super(key: key);
  int sub_s = 0;
  //MqttServerClient? client;

  List<Widget> buildlist(LedModel ledmodel) {
    List<Widget> list = [];
    List<String> b = ['led1', 'led2', 'led3'];
    if (ledmodel.ledstate[iot_name] == null) {
      my_mqtt(deviceid, ledmodel);
      list.add(Container(
        padding: const EdgeInsets.all(5),
        decoration: BoxDecoration(border: Border.all(color: Colors.blueAccent)),
        height: 150,
        child: Center(
          child: Text(
            '$name mqtt conect.....',
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      ));
    }
    ledmodel.ledstate.forEach((key, value) {
      list.add(Container(
        padding: const EdgeInsets.all(5),
        margin: const EdgeInsets.all(10),
        decoration: BoxDecoration(border: Border.all(color: Colors.blueAccent)),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Column(
              children: [
                Icon(
                  Charingicon.charing,
                  size: 20,
                  color: value['connected'] == 1 ? Colors.blue : Colors.red,
                ),
                Text('${value['name']}'),
              ],
            ),
            Column(
              children: b
                  .map((e) => Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          ElevatedButton(
                              onPressed: (() {
                                ledmodel.ledmqttpub(
                                    value['client'],
                                    '\$aws/things/$key/shadow/update',
                                    '{"state": {"desired": {"$e":${value[e] == 1 ? '0' : '1'}}}}');
                              }),
                              child: Text("$e:${value[e] == 1 ? '关' : '开'}")),
                          SizedBox(width: 50),
                          Text(value[e].toString(),
                              style: const TextStyle(
                                  color: Colors.blue, fontSize: 30)),
                        ],
                      ))
                  .toList(),
            )
          ],
        ),
      ));
    });
    return list;
  }

  @override
  Widget build(BuildContext context) {
    return Column(children: <Widget>[
      Consumer<LedModel>(builder: ((context, ledmodel, child) {
        // if (ledmodel.ledstate[iot_name] == null) {
        //   print('mqtt null');
        //   my_mqtt(deviceid, ledmodel);
        //   return Text('mqtt not con');
        // } else {
        return Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: buildlist(ledmodel)
            //[
            // Row(
            //   mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            //   children: [
            //     ElevatedButton(
            //         onPressed: (() {
            //           ledmodel.ledmqttpub(
            //               ledmodel.ledstate[iot_name]!['client'],
            //               '\$aws/things/$iot_name/shadow/update',
            //               '{"state": {"desired": {"led1":${ledmodel.ledstate[iot_name]!['led1'] == 1 ? '0' : '1'}}}}');
            //         }),
            //         child: Text(
            //             "LED1:${ledmodel.ledstate[iot_name]!['led1'] == 1 ? '关' : '开'}")),
            //     Text(ledmodel.ledstate[iot_name]!['led1'].toString(),
            //         style: const TextStyle(color: Colors.blue, fontSize: 30))
            //   ],
            // ),
            // Row(
            //   mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            //   children: [
            //     ElevatedButton(
            //         onPressed: (() {
            //           ledmodel.ledmqttpub(
            //               ledmodel.ledstate[iot_name]!['client'],
            //               '\$aws/things/$iot_name/shadow/update',
            //               '{"state": {"desired": {"led2":${ledmodel.ledstate[iot_name]!['led2'] == 1 ? '0' : '1'}}}}');
            //         }),
            //         child: Text(
            //             "LED2:${ledmodel.ledstate[iot_name]!['led2'] == 1 ? '关' : '开'}")),
            //     Text(ledmodel.ledstate[iot_name]!['led2'].toString(),
            //         style: const TextStyle(color: Colors.blue, fontSize: 30))
            //   ],
            // ),
            // Row(
            //   mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            //   children: [
            //     ElevatedButton(
            //         onPressed: (() {
            //           ledmodel.ledmqttpub(
            //               ledmodel.ledstate[iot_name]!['client'],
            //               '\$aws/things/$iot_name/shadow/update',
            //               '{"state": {"desired": {"led3":${ledmodel.ledstate[iot_name]!['led3'] == 1 ? '0' : '1'}}}}');
            //         }),
            //         child: Text(
            //             "LED3:${ledmodel.ledstate[iot_name]!['led3'] == 1 ? '关' : '开'}")),
            //     Text(ledmodel.ledstate[iot_name]!['led3'].toString(),
            //         style: const TextStyle(color: Colors.blue, fontSize: 30))
            //   ],
            // ),
            //]
            );
      }
          //}
          ))
    ]);
  }
}
