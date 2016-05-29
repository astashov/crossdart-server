library crossdart_server.handler;

import 'package:crossdart_server/task.dart';
import 'package:crossdart_server/config.dart';
import 'dart:async';
import 'package:logging/logging.dart';
import 'package:path/path.dart' as p;
import 'dart:io';
import 'package:crossdart_server/run_command_error.dart';
import 'package:crossdart_server/storage.dart';

var _logger = new Logger("crossdart_server.handler");

class Generator {
  final Config _config;
  final Task _task;
  final Storage _storage;

  Generator(Config config, this._task) : _storage = new Storage(config), _config = config;

  Future<Null> run() async {
    await _install();
    await _crossdartize();
    await _upload();
    await _cleanup();
  }

  Future<Null> _install() async {
    await _runCommand("git", ["clone", _authUrl, _repoDir]);
    await _runCommand("git", ["checkout", _task.sha], workingDirectory: _repoDir);
    await _runCommand("pub", ["get"], workingDirectory: _repoDir);
  }

  String get _authUrl {
    if (_task.token != null) {
      return _task.url.replaceAll("https://", "https://${_task.token}@");
    } else {
      return _task.url;
    }
  }

  String get _repoDir => p.join(_config.outputDir, _task.repoName);

  Future<Null> _crossdartize() {
    return _runCommand("pub", ["global", "run", "crossdart",
        "--input=${_repoDir}",
        "--output=${_repoDir}",
        "--hosted-url=${_config.hostedUrl}",
        "--url-path-prefix=${_config.crossdartUrlPathPrefix}",
        "--output-format=github",
        "--dart-sdk=${_config.dartSdk}"]);
  }

  Future<Null> _upload() async {
    var path = p.join(_config.urlPathPrefix, _task.repoName, _task.sha, "crossdart.json");
    _logger.info("Started uploading crossdart.json to GCS ($path)");
    var file = new File(p.join(_repoDir, "crossdart.json"));
    await _storage.insertFile(path, file);
    _logger.info("Finished uploading crossdart.json to GCS");
  }

  Future<Null> _cleanup() async {
    var directory = p.join(_config.outputDir, _task.repoName.split("/").first);
    _logger.info("Removing the working directory $directory");
    await new Directory(directory).delete(recursive: true);
    _logger.info("Done removing");
  }

  Future<Null> _runCommand(String command, List<String> arguments, {String workingDirectory, Duration duration}) async {
    _logger.info("Running '$command ${arguments.join(" ")}'");

    ProcessResult result;
    if (duration == null) {
      result = await Process.run(command, arguments, workingDirectory: workingDirectory);
    } else {
      result = await _runProcessWithTimeout(command, arguments, duration, workingDirectory: workingDirectory);
    }

    if (result.stdout != "") {
      _logger.info("Stdout: ${result.stdout}");
    }
    if (result.stderr != "") {
      _logger.info("Stderr: ${result.stderr}");
    }

    if (result.exitCode != 0) {
      throw new RunCommandError(command, arguments, result.exitCode, result.stdout, result.stderr); }
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
