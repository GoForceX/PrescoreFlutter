//from https://pub.dev/packages/flutter_log_local/

import 'dart:io';

import 'package:archive/archive_io.dart';
import 'package:flutter/foundation.dart';
import './extensions/iterable_extension.dart';
import 'package:mutex/mutex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

final m = Mutex();

/// A LocalLogger.
class LocalLogger {
  static void write(String text,
      {bool isError = false,
      String sufix = 'log',
      bool writeOnlyAppend = true,
      int logMBToRotate = 100}) async {
    if (kReleaseMode) {
      return;
    }
    // pass the message to your favourite logging package here
    // please note that even if enableLog: false log messages will be pushed in this callback
    // you get check the flag if you want through GetConfig.isLogEnable
    debugPrint('LocalLogger $text');
    await m.protect(() async {
      // critical section
      var directory = Directory('${Directory.current.path}/logs');
      if (Platform.isAndroid || Platform.isIOS) {
        Directory? extDir = await getExternalStorageDirectory();
        if(extDir != null) {
          directory = extDir;
        }
      }
      if (!directory.existsSync()) {
        directory.createSync(recursive: true);
      }
      var fileName = '${DateTime.now().toString().substring(0, 10)}-$sufix';
      //var file = File('${directory.path}/$fileName.txt');
      var file = File(path.join(directory.path, "$fileName.txt"));
      //debugPrint('LocalLogger ${file.path}');
      writeOnlyAppend =
          logRotate(file, directory, fileName, writeOnlyAppend, logMBToRotate);
      if(!await file.exists()) {
        await file.create();
      }
      await file.writeAsString(
        '${isError ? '[ERROR]' : '[INFO]'} - ${DateTime.now()} - $text\n',
        mode:
            writeOnlyAppend ? FileMode.writeOnlyAppend : FileMode.writeOnly);
      
    });
  }

  static bool logRotate(File file, Directory directory, String fileName,
      bool writeOnlyAppend, int logMBToRotate) {
    try {
      int sizeInBytes = file.existsSync() ? file.lengthSync() : 0;
      double sizeInMb = sizeInBytes / (1024 * 1024);

      if (sizeInMb < logMBToRotate) return writeOnlyAppend;

      // This file is Longer the
      debugPrint('LocalLogger ZIP ZIP ${sizeInMb}MB');
      var encoder = ZipFileEncoder();
      var zipFilesAmount = directory
          .listSync()
          .where((f) => f.path.contains(fileName) && f.path.endsWith('.zip'))
          .length;
      encoder.create('${directory.path}/$fileName.$zipFilesAmount.zip');
      encoder.addFile(file);
      encoder.close();
      debugPrint(
          'LocalLogger ZIP ZIPED ${File('${directory.path}/$fileName.$zipFilesAmount.zip').lengthSync() / (1024 * 1024)}MB');

      return false;
    } on Exception catch (_) {
      // only executed if error is of type Exception
    } catch (error) {
      // executed for errors of all types other than Exception
    }
    return writeOnlyAppend;
  }

  static void cleanOldLogs(String sufix, {int keepLogDays = 7}) async {
    write('INIT [CLEAN-OLD-LOGS]');
    await m.protect<void>(() async {
      // critical section
      final dir = Directory('${Directory.current.path}/logs');
      if (!dir.existsSync()) return;
      write('[CLEAN-OLD-LOGS] Log Path ${dir.path}');
      final List<FileSystemEntity> entities = await dir.list().toList();
      var logs =
          entities.where((element) => element.path.endsWith('-$sufix.txt'));
      write('[CLEAN-OLD-LOGS] Log files ${logs.length}');
      try {
        for (final e in logs
            .groupBy(
              (p0) => DateTime.parse(
                  p0.path.split('/').last.split('-$sufix').first),
            )
            .entries
            .where((e) => DateTime.now().difference(e.key).inDays > keepLogDays)
            .expand((t) => t.value)) {
          // localLogWriter('File path ${e.path}');
          try {
            File(e.path).deleteSync();
            write('[CLEAN-OLD-LOGS] ${e.path} DELETED');
          } on Exception catch (_) {
            // only executed if error is of type Exception
            write('[CLEAN-OLD-LOGS] File path cannot deleted ${e.path}',
                isError: true);
          } catch (_) {
            // executed for errors of all types other than Exception
            write('[CLEAN-OLD-LOGS] File path cannot deleted ${e.path}',
                isError: true);
          }
        }
      } catch (_) {}
    });
    write('END [CLEAN-OLD-LOGS]');
  }
}
