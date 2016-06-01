library crossdart_server.bin.server;

import 'package:redstone/redstone.dart' as app;
import 'package:crossdart_server/config.dart';
import 'package:crossdart_server/task.dart';
import 'package:crossdart_server/logging.dart' as logging;
import 'package:di/di.dart';
import 'dart:async';
import 'package:args/args.dart';
import 'package:crossdart_server/pubsub.dart';
import 'package:crossdart_server/generator.dart';
import 'package:logging/logging.dart';

var _queue = new StreamController<Task>.broadcast();
var _logger = new Logger("crossdart_server.server");

@app.Interceptor(r'/.*')
handleCORS() async {
  if (app.request.method != "OPTIONS") {
    await app.chain.next();
  }
  return app.response.change(headers: {
    "Access-Control-Allow-Origin": "*",
    "Access-Control-Allow-Headers": "Origin, X-Requested-With, Content-Type, Accept, X-Csrf-Token",
    "Access-Control-Allow-Methods": "OPTIONS, POST"
  });
}

@app.Route("/analyze", methods: const [app.POST])
analyze(@app.Body(app.JSON) Map<String, String> jsonMap, @app.Inject() Config config, @app.Inject() Pubsub pubsub) async {
  _logger.info("POST /analyze ${jsonMap}");
  await pubsub.publish("crossdart-server", {"token": jsonMap["token"], "url": jsonMap["url"], "sha": jsonMap["sha"]});
  var generator = new Generator(config, new Task(jsonMap["token"], jsonMap["url"], jsonMap["sha"]));
  await generator.updateStatus("queued");
  return "ok";
}

@app.Route("/check", methods: const [app.GET])
check() {
  return "ok";
}

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

  app.addModule(new Module()..bind(Config, toValue: config)..bind(Pubsub, toValue: pubsub));
  app.start(port: config.port);
}
