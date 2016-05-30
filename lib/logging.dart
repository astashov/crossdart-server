library crossdart_server.logging;

import 'package:intl/intl.dart';
import 'package:logging/logging.dart';

String logFormatter(int index, LogRecord record, {bool shouldConvertToPTZ: false}) {
  var timeString = new DateFormat("H:m:s.S").format(record.time);
  String message = "";
  var name = record.loggerName.replaceAll(new RegExp(r"^crossdart_server\."), "");
  if (index != null) {
    message += "$index - ";
  }
  message += "$timeString [${record.level.name}] ${name}: ${record.message}";
  if (record.error != null) {
    message += "\n${record.error}\n${record.stackTrace}";
  }
  return message;
}

void initialize([int index]) {
  Logger.root.onRecord.listen((record) {
    var message = logFormatter(index, record);
    print(message);
  });

  Logger.root.level = Level.INFO;
}
