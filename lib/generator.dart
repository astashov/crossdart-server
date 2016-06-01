library crossdart_server.handler;

import 'package:crossdart_server/task.dart';
import 'package:crossdart_server/config.dart';
import 'dart:async';
import 'package:logging/logging.dart';
import 'package:path/path.dart' as p;
import 'dart:io';
import 'package:crossdart_server/run_command_error.dart';
import 'package:crossdart_server/storage.dart';
import 'package:crossdart_server/logging.dart' as logging;
import 'package:http/http.dart';

var _logger = new Logger("crossdart_server.generator");

class Generator {
  final Config _config;
  final Task _task;
  final Storage _storage;

  Generator(Config config, this._task) : _storage = new Storage(config), _config = config;

  Future<Null> run() async {
    List<LogRecord> logs = [];
    try {
      await updateStatus("installing");
      await _install(logs);
      await updateStatus("crossdartizing");
      await _crossdartize(logs);
      await updateStatus("uploading");
      await _upload();
      await updateStatus("done");
      await _cleanup();
    } catch(_, __) {
      await updateStatus("error");
    } finally {
      await _uploadLogs(logs);
    }
  }

  Future<bool> doesExist() async {
    var response = await head(p.join(_targetUrl, "crossdart.json"));
    return response.statusCode == 200;
  }

  Future<Null> updateStatus(String status) async {
    await _storage.insertContent(p.join(_targetUrl, "status.txt"), status, "text/plain", maxAge: 0);
  }

  Future<Null> _install(List<LogRecord> logs) async {
    await _runCommand(logs, "git", ["clone", _authUrl, _repoDir]);
    await _runCommand(logs, "git", ["checkout", _task.sha], workingDirectory: _repoDir);
    await _runCommand(logs, "pub", ["get"], workingDirectory: _repoDir);
  }

  String get _authUrl {
    if (_task.token != null) {
      return _task.url.replaceAll("https://", "https://${_task.token}@");
    } else {
      return _task.url;
    }
  }

  String get _repoDir => p.join(_config.outputDir, _task.repoName);
  String get _targetUrl => p.join(_config.urlPathPrefix, _task.repoName);

  Future<Null> _crossdartize(List<LogRecord> logs) {
    return _runCommand(logs, "pub", ["global", "run", "crossdart",
        "--input=${_repoDir}",
        "--output=${_repoDir}",
        "--hosted-url=${_config.hostedUrl}",
        "--url-path-prefix=${_config.crossdartUrlPathPrefix}",
        "--output-format=github",
        "--dart-sdk=${_config.dartSdk}"]);
  }

  Future<Null> _upload() async {
    var path = p.join(_targetUrl, "crossdart.json");
    _logger.info("Started uploading crossdart.json to GCS ($path)");
    var file = new File(p.join(_repoDir, "crossdart.json"));
    await _storage.insertFile(path, file, maxAge: 30);
    _logger.info("Finished uploading crossdart.json to GCS");
  }

  Future<Null> _uploadLogs(List<LogRecord> logs) async {
    var path = p.join(_targetUrl, "log.txt");
    _logger.info("Started uploading logs to GCS ($path)");
    var contents = logs.map((logRecord) => logging.logFormatter(null, logRecord)).join("\n");
    await _storage.insertContent(path, contents, "text/plain");
    _logger.info("Finished uploading logs to GCS");
  }

  Future<Null> _cleanup() async {
    var directory = p.join(_config.outputDir, _task.repoName);
    _logger.info("Removing the working directory $directory");
    await new Directory(directory).delete(recursive: true);
    _logger.info("Done removing");
  }

  Future _runCommand(
      List<LogRecord> logs, String command, List<String> arguments,
      {String workingDirectory, Duration duration}) async {
    _addLog(logs, Level.INFO, "Running '$command ${arguments.join(" ")}'");

    ProcessResult result;
    if (duration == null) {
      result = await Process.run(command, arguments,
          workingDirectory: workingDirectory);
    } else {
      result = await _runProcessWithTimeout(command, arguments, duration,
          workingDirectory: workingDirectory);
    }

    if (result.stdout != "") {
      _addLog(logs, Level.INFO, "Stdout: ${result.stdout}");
    }
    if (result.stderr != "") {
      _addLog(logs, Level.INFO, "Stderr: ${result.stderr}");
    }

    if (result.exitCode != 0) {
      throw new RunCommandError(
          command, arguments, result.exitCode, result.stdout, result.stderr);
    }
  }

  void _addLog(List<LogRecord> logs, Level level, String message) {
    logs.add(new LogRecord(level, message, "dartdoc"));
    _logger.log(level, message);
  }

  Future<ProcessResult> _runProcessWithTimeout(String executable, List<String> arguments, Duration timeout,
      {String workingDirectory}) async {
    Process proc = await Process.start(executable, arguments, workingDirectory: workingDirectory);

    var timer = new Timer(timeout, () {
      proc.kill();
    });

    var stdout = await SYSTEM_ENCODING.decodeStream(proc.stdout);
    var stderr = await SYSTEM_ENCODING.decodeStream(proc.stderr);

    var exitCode = await proc.exitCode;

    timer.cancel();

    return new ProcessResult(proc.pid, exitCode, stdout, stderr);
  }
}
