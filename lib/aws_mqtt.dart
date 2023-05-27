/*
 * Package : mqtt_client
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 10/07/2021
 * Copyright :  S.Hamblett
 *
 */
import 'dart:convert';
import 'dart:async';
import 'dart:developer';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'tes.dart';

/// An example of connecting to the AWS IoT Core MQTT broker and publishing to a devices topic.
/// This example uses MQTT on port 8883 using certificites
/// More instructions can be found at https://docs.aws.amazon.com/iot/latest/developerguide/mqtt.html and
/// https://docs.aws.amazon.com/iot/latest/developerguide/protocols.html, please read this
/// before setting up and running this example.
Future<void> my_mqtt(String devicedId, LedModel ledmodel) async {
  String mykey = '';
  String mycrt = '';
  String clientId = '';
  String iotName = '';
  String name = '';
  final value = await DBManager().find(devicedId);
  mykey = value![0]['client_key'];
  mycrt = value[0]['client_pem'];
  clientId = value[0]['client_id'];
  iotName = value[0]['iot_name'];
  name = value[0]['name'];
  // Your AWS IoT Core endpoint url
  log(clientId);
  const url = 'a2sv0o8iir5hhy-ats.iot.us-east-1.amazonaws.com';
  // AWS IoT MQTT default port
  const port = 8883;
  // The client id unique to your device
  //const clientId = 'basicPubSub';

  // Create the client
  final client = MqttServerClient.withPort(url, clientId, port);

  // Set secure
  client.secure = true;
  // Set Keep-Alive
  client.keepAlivePeriod = 20;
  // Set the protocol to V3.1.1 for AWS IoT Core, if you fail to do this you will not receive a connect ack with the response code
  client.setProtocolV311();
  // logging if you wish
  client.logging(on: false);

  String ca = "-----BEGIN CERTIFICATE-----\n"
      "MIIDQTCCAimgAwIBAgITBmyfz5m/jAo54vB4ikPmljZbyjANBgkqhkiG9w0BAQsF"
      "ADA5MQswCQYDVQQGEwJVUzEPMA0GA1UEChMGQW1hem9uMRkwFwYDVQQDExBBbWF6"
      "b24gUm9vdCBDQSAxMB4XDTE1MDUyNjAwMDAwMFoXDTM4MDExNzAwMDAwMFowOTEL"
      "MAkGA1UEBhMCVVMxDzANBgNVBAoTBkFtYXpvbjEZMBcGA1UEAxMQQW1hem9uIFJv"
      "b3QgQ0EgMTCCASIwDQYJKoZIhvcNAQEBBQADggEPADCCAQoCggEBALJ4gHHKeNXj"
      "ca9HgFB0fW7Y14h29Jlo91ghYPl0hAEvrAIthtOgQ3pOsqTQNroBvo3bSMgHFzZM"
      "9O6II8c+6zf1tRn4SWiw3te5djgdYZ6k/oI2peVKVuRF4fn9tBb6dNqcmzU5L/qw"
      "IFAGbHrQgLKm+a/sRxmPUDgH3KKHOVj4utWp+UhnMJbulHheb4mjUcAwhmahRWa6"
      "VOujw5H5SNz/0egwLX0tdHA114gk957EWW67c4cX8jJGKLhD+rcdqsq08p8kDi1L"
      "93FcXmn/6pUCyziKrlA4b9v7LWIbxcceVOF34GfID5yHI9Y/QCB/IIDEgEw+OyQm"
      "jgSubJrIqg0CAwEAAaNCMEAwDwYDVR0TAQH/BAUwAwEB/zAOBgNVHQ8BAf8EBAMC"
      "AYYwHQYDVR0OBBYEFIQYzIU07LwMlJQuCFmcx7IQTgoIMA0GCSqGSIb3DQEBCwUA"
      "A4IBAQCY8jdaQZChGsV2USggNiMOruYou6r4lK5IpDB/G/wkjUu0yKGX9rbxenDI"
      "U5PMCCjjmCXPI6T53iHTfIUJrU6adTrCC2qJeHZERxhlbI1Bjjt/msv0tadQ1wUs"
      "N+gDS63pYaACbvXy8MWy7Vu33PqUXHeeE6V/Uq2V8viTO96LXFvKWlJbYK8U90vv"
      "o/ufQJVtMVT8QtPHRh8jrdkPSHCa2XV4cdFyQzR1bldZwgJcJmApzyMZFo6IQ6XU"
      "5MsI+yMRQ+hDKXJioaldXgjUkK642M4UwtBV8ob2xJNDd2ZhwLnoQdeXeGADbkpy"
      "rqXRfboQnoZsG4q5WTP468SQvvG5"
      "\n-----END CERTIFICATE-----";
  List<int> caBytes = ca.codeUnits;
  List<int> crtBytes = mycrt.codeUnits;
  List<int> keyBytes = mykey.codeUnits;
  // Set the security context as you need, note this is the standard Dart SecurityContext class.
  // If this is incorrect the TLS handshake will abort and a Handshake exception will be raised,
  // no connect ack message will be received and the broker will disconnect.
  // For AWS IoT Core, we need to set the AWS Root CA, device cert & device private key
  // Note that for Flutter users the parameters above can be set in byte format rather than file paths
  final context = SecurityContext.defaultContext;
  context.setClientAuthoritiesBytes(caBytes);
  context.useCertificateChainBytes(crtBytes);
  context.usePrivateKeyBytes(keyBytes);
  client.securityContext = context;

  // Setup the connection Message
  final connMess =
      MqttConnectMessage().withClientIdentifier(clientId).startClean();
  client.connectionMessage = connMess;

  // Connect the client
  try {
    print('MQTT client connecting to AWS IoT using certificates....');
    await client.connect();
  } on Exception catch (e) {
    print('MQTT client exception - $e');
    client.disconnect();
    exit(-1);
  }

  if (client.connectionStatus!.state == MqttConnectionState.connected) {
    print('MQTT client connected to AWS IoT');
    // Publish to a topic of your choice
    // int value = 0;
    subtopic(client, ledmodel, devicedId, iotName);

    ledmodel.ledstate[iotName] = {
      'client': client,
      'deviceid': devicedId,
      'name': name,
      'connected': 0,
      'state': 1,
      'led1': 0,
      'led2': 0,
      'led3': 0
    };
    String pubtopic = '\$aws/things/$iotName/shadow/get';
    String publwt = 'lwt/$iotName';
    ledmodel.changestate();
    final builder = MqttClientPayloadBuilder();
    builder.addString('');
    // Important: AWS IoT Core can only handle QOS of 0 or 1. QOS 2 (exactlyOnce) will fail!
    Future.delayed(Duration(milliseconds: 2000), () {
      client.publishMessage(pubtopic, MqttQos.atLeastOnce, builder.payload!);
    });

    //确定设备是否在线
    print('send lwt mess');
    final lwtbuilder = MqttClientPayloadBuilder();
    lwtbuilder.addString('{"query": {"connected":0}}');
    Future.delayed(Duration(milliseconds: 1000), () {
      client.publishMessage(publwt, MqttQos.atLeastOnce, lwtbuilder.payload!);
    });

    Timer? undateTimer;
    var updateSecond = Duration(seconds: 60);
    undateTimer = Timer.periodic(updateSecond, (timer) {
      //回调
      if (ledmodel.ledstate[iotName]!['connected'] == 0) {
        print('send lwt mess');
        final lwtbuilder = MqttClientPayloadBuilder();
        lwtbuilder.addString('{"query": {"connected":0}}');
        client.publishMessage(publwt, MqttQos.atLeastOnce, lwtbuilder.payload!);
      } else {
        print('stop timer');
        undateTimer?.cancel();
      }
    });
  } else {
    print(
        'ERROR MQTT client connection failed - disconnecting, state is ${client.connectionStatus!.state}');
    client.disconnect();
  }

  // print('Sleeping....');
  //await MqttUtilities.asyncSleep(10);

  // print('Disconnecting');
  // client.disconnect();
}

void subtopic(MqttServerClient client, LedModel ledmodel, String devicedId,
    String iotName) {
  log('sub to AWS IoT');
  // Publish to a topic of your choice
  String subtopic1 = '\$aws/things/$iotName/shadow/update/accepted';
  String subtopic2 = '\$aws/things/$iotName/shadow/update/rejected';
  String subtopic3 = '\$aws/things/$iotName/shadow/get/accepted';
  String subtopic4 = '\$aws/things/$iotName/shadow/get/rejected';
  String subtopic5 = 'lwt/$iotName';
  // Subscribe to the same topic
  client.subscribe(subtopic1, MqttQos.atLeastOnce);
  client.subscribe(subtopic2, MqttQos.atLeastOnce);
  client.subscribe(subtopic3, MqttQos.atLeastOnce);
  client.subscribe(subtopic4, MqttQos.atLeastOnce);
  client.subscribe(subtopic5, MqttQos.atLeastOnce);
  // Print incoming messages from another client on this topic
  client.updates!.listen((List<MqttReceivedMessage<MqttMessage>> c) {
    final recMess = c[0].payload as MqttPublishMessage;
    final pt =
        MqttPublishPayload.bytesToStringAsString(recMess.payload.message);

    if (c[0].topic == subtopic1 || c[0].topic == subtopic3) {
      if (c[0].topic == subtopic1) log("from accepted");
      if (c[0].topic == subtopic3) log("from get");
      Map<String, dynamic> topic1 = json.decode(pt);
      print(topic1);
      if (topic1['state']['reported'] != null) {
        String iotname = c[0].topic.split('/')[2];
        ledmodel.ledstate.forEach((key, value) {
          if (key == iotname) {
            if (topic1['state']['reported']['led1'] != null) {
              ledmodel.ledstate[key]!['led1'] =
                  topic1['state']['reported']['led1'];
            }
            if (topic1['state']['reported']['led2'] != null) {
              ledmodel.ledstate[key]!['led2'] =
                  topic1['state']['reported']['led2'];
            }
            if (topic1['state']['reported']['led3'] != null) {
              ledmodel.ledstate[key]!['led3'] =
                  topic1['state']['reported']['led3'];
            }
            ledmodel.changestate();
          }
        });
      }
    }
    if (c[0].topic == subtopic5) {
      Map<String, dynamic> lwtmess = json.decode(pt);
      print(lwtmess);
      if (lwtmess['reported'] != null) {
        String iotname = c[0].topic.split('/')[1];
        ledmodel.ledstate.forEach((key, value) {
          if (key == iotname) {
            if (lwtmess['reported']['connected'] == 1) {
              print('conn');
              ledmodel.ledstate[key]!['connected'] = 1;
              ledmodel.changestate();
            } else {
              if (ledmodel.ledstate[key]!['connected'] == 1) {
                ledmodel.ledstate[key]!['connected'] = 0;
                ledmodel.changestate();
              }
              print('conn not');
            }
          }
        });
      }
    }
  });
}

void unsub(MqttServerClient client, String iotName) {
  log('unsub to AWS IoT');
  // Publish to a topic of your choice
  String subtopic1 = '\$aws/things/$iotName/shadow/update/accepted';
  String subtopic2 = '\$aws/things/$iotName/shadow/update/rejected';
  String subtopic3 = '\$aws/things/$iotName/shadow/get/accepted';
  String subtopic4 = '\$aws/things/$iotName/shadow/get/rejected';
  client.unsubscribe(subtopic1);
  client.unsubscribe(subtopic2);
  client.unsubscribe(subtopic3);
  client.unsubscribe(subtopic4);
}

void mqtt_pub(MqttServerClient client, String topic, String message) {
  print(message);
  final builder = MqttClientPayloadBuilder();
  builder.addString(message);
  client.publishMessage(topic, MqttQos.atLeastOnce, builder.payload!);
}

class LedModel with ChangeNotifier {
  int led1 = 0;
  int led2 = 0;
  int led3 = 0;
  Map<String, Map> ledstate = {}; //{"client_id":{"state","led1","led2","led3"}}
  // void changestate(String led, int state) {
  //   if (led == "led1") led1 = state;
  //   if (led == "led2") led2 = state;
  //   if (led == "led3") led3 = state;
  //   notifyListeners();
  // }
  void changestate() {
    notifyListeners();
  }

  void ledmqttpub(MqttServerClient client, String topic, String message) {
    print(message);
    final builder = MqttClientPayloadBuilder();
    builder.addString(message);
    client.publishMessage(topic, MqttQos.atLeastOnce, builder.payload!);
  }
}
