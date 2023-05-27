import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'tes.dart';

class Cou extends ChangeNotifier {
  List ab = [];
  List<String> devid = [];
  int state = 0;
  void increment() {
    ab.clear();
    DBManager().findAll().then((value) {
      value?.forEach((element) {
        ab.add(element);
      });
      // print(ab);
      notifyListeners();
    });
  }

  List get() {
    print(ab.length);
    return ab;
  }

  void clear() {
    DBManager().deleteAll().then((value) {
      // print(value);
      ab.clear();
      notifyListeners();
    });
  }

  void delete(String deviced_id) {
    DBManager().delete(deviced_id).then((value) => increment());
  }

  void add(String name, String id) {
    BleData a =
        studentFromJson('{"name":"$name","deviced_id":"$id","ble_type":0}');
    DBManager().saveData(a);
    notifyListeners();
  }

  void setState(int s) {
    state = s;
    notifyListeners();
  }
}
