import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

BleData studentFromJson(String str) => BleData.fromJson(json.decode(str));

String studentToJson(BleData data) => json.encode(data.toJson());

class BleData {
  BleData(
      {this.id,
      this.name,
      this.deviced_id,
      this.ble_type,
      this.client_key,
      this.client_pem,
      this.client_id});

  BleData.fromJson(dynamic json) {
    //id = json['id'];
    name = json['name'];
    deviced_id = json['deviced_id'];
    ble_type = json['ble_type'];
    client_key = json['client_key'];
    client_pem = json['client_pem'];
    client_id = json['client_id'];
    iot_name = json['iot_name'];
  }
  BleData.fromMap(Map<String, dynamic> m) {
    //id = m['id'];
    name = m['name'];
    deviced_id = m['deviced_id'];
    ble_type = m['ble_type'];
    client_key = m['client_key'];
    client_pem = m['client_pem'];
    client_id = m['client_id'];
    iot_name = m['iot_name'];
  }

  int? id;
  String? name;
  String? deviced_id;
  int? ble_type;
  String? client_pem;
  String? client_key;
  String? client_id;
  String? iot_name;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['id'] = id;
    map['name'] = name;
    map['deviced_id'] = deviced_id;
    map['ble_type'] = ble_type;
    map['client_key'] = client_key;
    map['client_pem'] = client_pem;
    map['client_id'] = client_id;
    map['iot_name'] = iot_name;
    return map;
  }
}

class DBManager {
  /// 数据库名
  final String _dbName = "ble_db";

  /// 数据库版本
  final int _version = 1;

  static final DBManager _instance = DBManager._();

  factory DBManager() {
    return _instance;
  }

  DBManager._();

  static Database? _db;

  Future<Database> get db async {
    // if (_db != null) {
    //   return _db;
    // }
    // _db = await _initDB();
    // return _db;
    return _db ??= await _initDB();
  }

  /// 初始化数据库
  Future<Database> _initDB() async {
    var databasesPath = await getDatabasesPath();
    String path = join(databasesPath, _dbName);
    return await openDatabase(
      path,
      version: _version,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  /// 创建表
  Future _onCreate(Database db, int version) async {
    const String sql = """
    CREATE TABLE BleData(
      id INTEGER primary key AUTOINCREMENT,
      name TEXT,
      deviced_id TEXT,
      ble_type INTEGER,
      client_key TEXT,
      client_pem TEXT,
      client_id  TEXT,
      iot_name  TEXT
    )
    """;
    return await db.execute(sql);
  }

  /// 更新表
  Future _onUpgrade(Database db, int oldVersion, int newVersion) async {}

  /// 保存数据
  Future saveData(BleData data) async {
    Database database = await db;
    return await database.insert("BleData", data.toJson());
  }

  /// 使用SQL保存数据
  Future saveDataBySQL(BleData data) async {
    const String sql = """
    INSERT INTO BleData(name,deviced_id,ble_type) values(?,?,?)
    """;
    Database database = await db;
    return await database
        .rawInsert(sql, [data.name, data.deviced_id, data.ble_type]);
  }

  /// 查询全部数据
  Future<List<Map>?> findAll() async {
    Database? database = await db;
    List<Map<String, Object?>> result = await database.query("BleData");
    if (result.isNotEmpty) {
      //return result.map((e) => BleData.fromJson(e)).toList();
      // print(result[0]['client_pem']);
      // log(result[0]['client_pem'].toString());
      return result;
    } else {
      return [];
    }
  }

  ///条件查询
  Future<List<Map>?> find(String deviced_id) async {
    Database database = await db;
    List<Map<String, Object?>> result = await database
        .query("BleData", where: "deviced_id=?", whereArgs: [deviced_id]);
    if (result.isNotEmpty) {
      //return result.map((e) => BleData.fromJson(e)).toList();
      return result;
    } else {
      return [];
    }
  }

  /// 修改
  // Future<int> update(BleData data) async {
  //   Database database = await db;
  //   data.ble_type = 99;
  //   int count = await database.update("BleData", data.toJson(),
  //       where: "deviced_id=?", whereArgs: [data.deviced_id]);
  //   return count;
  // }

  Future<int> update(Map<String, Object?> upd, String devcid) async {
    Database database = await db;
    int count = await database
        .update("BleData", upd, where: "deviced_id=?", whereArgs: [devcid]);
    return count;
  }

  /// 删除
  Future<int> delete(String deviced_id) async {
    Database database = await db;
    int count = await database
        .delete("BleData", where: "deviced_id=?", whereArgs: [deviced_id]);
    return count;
  }

  /// 删除全部
  Future<int> deleteAll() async {
    Database database = await db;
    int count = await database.delete("BleData");
    return count;
  }
}
