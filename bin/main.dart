library crossdart_server;

import 'package:redstone/redstone.dart' as app;
import 'package:crossdart_server/config.dart';
import 'package:crossdart_server/task.dart';
import 'package:crossdart_server/generator.dart';
import 'package:crossdart_server/logging.dart' as logging;
import 'package:di/di.dart';
import 'dart:async';
import 'package:args/args.dart';

var _queue = new StreamController<Task>.broadcast();

@app.Route("/analyze", methods: const [app.POST])
analyze(@app.Body(app.JSON) Map<String, String> jsonMap, @app.Inject() Config config) {
  var token = jsonMap["token"];
  var url = jsonMap["url"];
  var sha = jsonMap["sha"];
  _queue.add(new Task(token, url, sha));
  return "ok";
}

main(List<String> args) {
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
  app.addModule(new Module()..bind(Config, toValue: config));
  app.start(port: config.port);

  _queue.stream.listen((Task task) {
    new Generator(config, task).run();
  });
}
