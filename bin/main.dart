library crossdart_server;

import 'package:redstone/redstone.dart' as app;
import 'package:crossdart_server/config.dart';
import 'package:crossdart_server/task.dart';
import 'package:crossdart_server/generator.dart';
import 'package:crossdart_server/logging.dart' as logging;
import 'package:di/di.dart';
import 'dart:async';
import 'package:args/args.dart';
import 'dart:io';

var _queue = new StreamController<Task>.broadcast();

@app.Route("/analyze", methods: const [app.POST])
analyze(@app.Body(app.JSON) Map<String, String> jsonMap, @app.Inject() Config config) {
  var token = jsonMap["token"];
  var url = jsonMap["url"];
  var sha = jsonMap["sha"];
  _queue.add(new Task(token, url, sha));
  return "ok";
}

@app.Route("/check", methods: const [app.GET])
check() {
  return "ok";
}

@app.Route("/664B9659BC5EA761A6DE1B31C6C0C603.txt", methods: const [app.GET])
sslCheck() {
  return new File("/crossdart-server/664B9659BC5EA761A6DE1B31C6C0C603.txt").readAsStringSync();
}

@app.Route("/", methods: const [app.GET])
root() {
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
