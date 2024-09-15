import 'dart:convert';

import 'package:prescore_flutter/main.dart';
import 'package:prescore_flutter/util/struct.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as path;
import 'package:synchronized/synchronized.dart';

const String paperGroupTable = "PaperGroup";
final Lock databaseLock = Lock();

Future<Database> initDataBase() async {
  return await openDatabase(
    path.join(await getDatabasesPath(), 'PaperGroup.db'),
    onCreate: (db, version) async {
      var tableExists = await db.rawQuery(
          "SELECT name FROM sqlite_master WHERE type='table' AND name='$paperGroupTable'");
      if (tableExists.isEmpty) {
        logger.d("tableNotExists, CREATE TABLE $paperGroupTable");
        db.execute(
          'CREATE TABLE $paperGroupTable (examId TEXT, paperGroup TEXT)',
        );
      }
    },
    version: 1,
  );
}

Future<List<List<String>>> readPaperGroups(String examId) async {
  return await databaseLock.synchronized(() async {
    Database database = await initDataBase();
    List<Map<String, Object?>> list = await database.query(
      paperGroupTable,
      where: 'examId = ?',
      whereArgs: [examId],
    );
    List<List<String>> result = [];
    for (Map<String, Object?> element in list) {
      List<dynamic> group = jsonDecode(element["paperGroup"]! as String);
      result.add(group.cast());
    }
    return result;
  });
}

Future<void> deletePapersGroups(String examId) async {
  return await databaseLock.synchronized(() async {
    Database database = await initDataBase();
    await database.delete(
      paperGroupTable,
      where: 'examId = ?',
      whereArgs: [examId],
    );
  });
}

Future<void> savePapersGroups(List<List<Paper>> papersGroup) async {
  return await databaseLock.synchronized(() async {
    Database database = await initDataBase();
    for (List<Paper> papers in papersGroup) {
      await database.insert(
        paperGroupTable,
        {
          "examId": papers[0].examId,
          "paperGroup":
              jsonEncode(papers.map((paper) => paper.paperId).toList()),
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await database.close();
  });
}
