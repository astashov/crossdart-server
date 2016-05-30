library crossdart_server.task;

import 'package:path/path.dart' as p;

class Task {
  final String token;
  final String url;
  final sha;

  Task(this.token, this.url, this.sha);

  String get repoName {
    return p.joinAll(url.split("/").reversed.take(2).toList().reversed.toList()..add(sha));
  }
}
