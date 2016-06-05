library crossdart_server.global_lock;

import 'dart:async';

import 'package:googleapis_auth/auth_io.dart';
import 'package:logging/logging.dart';
import 'package:googleapis_beta/datastore/v1beta2.dart';
import 'package:crossdart_server/config.dart';
import 'package:crossdart_server/utils/retry.dart';

final Logger _logger = new Logger("crossdart_server.global_lock");

class GlobalLock {
  static const _scopes = const [
    DatastoreApi.DatastoreScope,
    DatastoreApi.UserinfoEmailScope
  ];

  final Config config;
  final String name;

  Future<DatastoreApi> _datastoreApiInst;

  GlobalLock(this.config, this.name);

  Future<DatastoreApi> get _datastoreApi async {
    if (_datastoreApiInst == null) {
      _datastoreApiInst = clientViaServiceAccount(config.credentials, _scopes)
          .then((httpClient) {
        return new DatastoreApi(httpClient);
      });
    }
    return _datastoreApiInst;
  }

  Future<bool> acquire() async {
    return retry(() async {
      try {
        DatastoreApi api = (await _datastoreApi);
        var transaction = (await (api.datasets.beginTransaction(
          new BeginTransactionRequest.fromJson({"isolationLevel": "SERIALIZABLE"}), config.gcProject))).transaction;
        if (await _get(api, transaction)) {
          return false;
        } else {
          await _set(api, transaction);
          return true;
        }
      } on DetailedApiRequestError catch (e, _) {
        if (e.status == 409) {
          return false;
        }
      }
    });
  }

  Future<CommitResponse> release() async {
    DatastoreApi api = (await _datastoreApi);
    return retry(() async {
      var transaction = (await (api.datasets.beginTransaction(
          new BeginTransactionRequest.fromJson({"isolationLevel": "SERIALIZABLE"}), config.gcProject))).transaction;
      return api.datasets.commit(
          new CommitRequest.fromJson({
            "transaction": transaction,
            "mutation": {"delete": [{
              "path": [
                {"kind": "GlobalLock", "name": name}
              ]
            }]}
          }), config.gcProject);
    });
  }

  Future<bool> _get(DatastoreApi api, String transaction) async {
    LookupResponse result = await api.datasets.lookup(
        new LookupRequest.fromJson({
          "keys": [{
            "path": [{"kind": "GlobalLock", "name": name}]
          }],
          "readOptions": {
            "transaction": transaction
          }
        }), config.gcProject);
    return result.found.isNotEmpty;
  }

  Future<CommitResponse> _set(DatastoreApi api, String transaction) async {
    var a = await api.datasets.commit(
      new CommitRequest.fromJson({
        "transaction": transaction,
        "mutation": {"insert": [{
          "key": {
            "path": [
              {"kind": "GlobalLock", "name": name}
            ]
          }
        }]}
      }), config.gcProject);
    return a;
  }
}
