// ignore_for_file: camel_case_types

import 'dart:io';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

final _version = 1; //数据库版本号
final _databaseName = "my.db"; //数据库名称
final _tableName = "ble_data"; //表名称
final _tableId = "id"; //主键
final _ble_name = "name"; //ble_name
final _ble_deviced_id = "deviced_id"; //ble_id
final _ble_type = "ble_type"; //0:充电桩

class SqfLiteQueueData {
  SqfLiteQueueData.internal();

  //数据库句柄
  late Database _database;
  Future<Database> get database async {
    var databasesPath = await getDatabasesPath();
    print(databasesPath);
    String path = join(databasesPath, 'my_db.db');
    // Delete the database
    await deleteDatabase(path);
// open the database
    Database _database = await openDatabase(path, version: 1,
        onCreate: (Database db, int version) async {
      // When creating the db, create the table
      await db.execute(
          'CREATE TABLE $_tableName (id INTEGER PRIMARY KEY, $_ble_name TEXT, $_ble_deviced_id TEXT, $_ble_type INTEGER)');
    });
    return _database;
  }

//   static start() async {
//     var databasesPath = await getDatabasesPath();
//     print(databasesPath);
//     String path = join(databasesPath, 'my_db.db');
//     // Delete the database
//     await deleteDatabase(path);
// // open the database
//     Database _database = await openDatabase(path, version: 1,
//         onCreate: (Database db, int version) async {
//       // When creating the db, create the table
//       await db.execute(
//           'CREATE TABLE $_tableName (id INTEGER PRIMARY KEY, $_ble_name TEXT, $_ble_deviced_id TEXT, $_ble_type INTEGER)');
//     });
//   }

  // /// 创建表
  // Future<void> _createTable(Database db, String sql) async {
  //   var batch = db.batch();
  //   batch.execute(sql);
  //   await batch.commit();
  // }

  /// 添加数据
  static Future insertData(String name, String deviced_id, int type) async {
    Database db = await SqfLiteQueueData.internal().open();
    //1、普通添加
    //await db.rawDelete("insert or replace into $_tableName ($_tableId,$_tableTitle,$_tableNum) values (null,?,?)",[title, num]);
    //2、事务添加
    db.transaction((txn) async {
      await txn.rawInsert(
          "insert or replace into $_tableName ($_tableId,$_ble_name,$_ble_deviced_id,$_ble_type) values (null,?,?,?)",
          [name, deviced_id, type]);
    });
    await db.batch().commit();
    await SqfLiteQueueData.internal().close();
    db = await SqfLiteQueueData.internal().open();
    List<Map> maps = await db.rawQuery("select * from $_tableName");

    print(maps);

    await SqfLiteQueueData.internal().close();
  }

  /// 根据id删除该条记录
  static Future deleteData(String deviced_id) async {
    Database db = await SqfLiteQueueData.internal().open();
    //1、普通删除
    //await db.rawDelete("delete from _tableName where _tableId = ?",[id]);
    //2、事务删除
    db.transaction((txn) async {
      txn.rawDelete(
          "delete from $_tableName where $_ble_deviced_id = ?", [deviced_id]);
    });
    await db.batch().commit();

    await SqfLiteQueueData.internal().close();
  }

  /// 根据id更新该条记录
  static Future updateData(String deviced_id, String name) async {
    Database db = await SqfLiteQueueData.internal().open();
    //1、普通更新
    // await db.rawUpdate("update $_tableName set $_tableTitle =  ?,$_tableNum =  ? where $_tableId = ?",[title,num,id]);
    //2、事务更新
    db.transaction((txn) async {
      txn.rawUpdate(
          "update $_tableName set $_tableName =  ? where $_ble_deviced_id = ?",
          [name, deviced_id]);
    });
    await db.batch().commit();

    await SqfLiteQueueData.internal().close();
  }

  /// 查询所有数据
  static Future<List<Map>> searchDates() async {
    Database db = await SqfLiteQueueData.internal().open();
    List<Map> maps = await db.rawQuery("select * from $_tableName");

    print(maps);

    // await SqfLiteQueueData.internal().close();
    return maps;
  }

  //打开
  Future<Database> open() async {
    return await database;
  }

  ///关闭
  Future<void> close() async {
    var db = await database;
    return db.close();
  }

  ///删除数据库表
  static Future<void> deleteDataTable() async {
    Database db = await SqfLiteQueueData.internal().open();
    //1、普通删除
    //await db.rawDelete("drop table $_tableName");
    //2、事务删除
    db.transaction((txn) async {
      txn.rawDelete("drop table $_tableName");
    });
    await db.batch().commit();

    await SqfLiteQueueData.internal().close();
  }

  ///删除数据库文件
  static Future<void> deleteDataBaseFile() async {
    await SqfLiteQueueData.internal().close();
    String path = await getDatabasesPath() + "/$_databaseName";
    File file = new File(path);
    if (await file.exists()) {
      file.delete();
    }
  }
}
