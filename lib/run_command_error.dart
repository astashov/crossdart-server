library crossdart_server.run_command_error;

import 'dart:io';

class RunCommandError extends ProcessException {
  final String stdout;
  final String stderr;

  RunCommandError(String executable, List<String> arguments, int errorCode, this.stdout, this.stderr)
      : super(executable, arguments, '', errorCode);

  String toString() {
    var buffer = new StringBuffer(super.toString());
    if (stdout != null && stdout.isNotEmpty) {
      buffer.writeln();
      buffer.writeln('stdout:');
      buffer.write(stdout.trim());
    }

    if (stderr != null && stderr.isNotEmpty) {
      buffer.writeln();
      buffer.writeln('stderr:');
      buffer.write(stderr.trim());
    }

    return buffer.toString();
  }
}

