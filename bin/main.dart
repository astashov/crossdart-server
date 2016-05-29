library crossdart_server;

import 'package:redstone/redstone.dart' as app;
import 'package:crossdart_server/config.dart';
import 'package:crossdart_server/task.dart';
import 'package:crossdart_server/generator.dart';
import 'package:crossdart_server/logging.dart' as logging;
import 'package:di/di.dart';
import 'dart:async';

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
  logging.initialize();

  var config = new Config.build();
  app.addModule(new Module()..bind(Config, toValue: config));
  app.start(port: config.port);

  _queue.stream.listen((Task task) {
    new Generator(config, task).run();
  });
}
