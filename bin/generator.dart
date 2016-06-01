library crossdart_server.bin.generator;

import 'package:crossdart_server/config.dart';
import 'package:crossdart_server/task.dart';
import 'package:crossdart_server/generator.dart';
import 'package:crossdart_server/logging.dart' as logging;
import 'dart:async';
import 'package:args/args.dart';
import 'package:crossdart_server/pubsub.dart';
import 'packages/tasks/utils.dart';
import 'package:logging/logging.dart';

var _logger = new Logger("crossdart_server.bin.generator");

Future<Null> main(List<String> args) async {
  var parser = new ArgParser();
  parser.addOption('dirroot', help: "Specify the application directory, if not current");
  parser.addFlag('help', negatable: false, help: "Show help");
  var argsResults = parser.parse(args);
  if (argsResults["help"]) {
    print("Starts a server, which generats JSON metadata and uploads it to GCS.\n");
    print(parser.usage);
    return;
  }

  logging.initialize();

  var config = new Config.build(argsResults["dirroot"]);
  var pubsub = new Pubsub(config);

  while(true) {
    await pmap(new List.filled(50, "crossdart-server"), (subscription) async {
      var json = await pubsub.pull(subscription);
      _logger.info("Processing ${json["url"]}/${json["sha"]}");
      var generator = new Generator(config, new Task(json["token"], json["url"], json["sha"]));
      if (!(await generator.doesExist())) {
        await generator.run();
      }
    }, concurrencyCount: 2);
  }
}
