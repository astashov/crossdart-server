library crossdart_server.pubsub;

import 'package:crossdart_server/config.dart';
import 'package:googleapis/pubsub/v1.dart' as ps;
import 'package:googleapis_auth/auth_io.dart';
import 'dart:async';
import 'dart:convert';

class Pubsub {
  static const _scopes = const [ps.PubsubApi.PubsubScope];

  final String _topicPrefix;
  final String _subscriptionPrefix;

  final Config config;
  Future<ps.PubsubApi> _pubsubApiInst;

  Pubsub(Config config) :
      config = config,
      _topicPrefix = "projects/${config.gcProject}/topics/",
      _subscriptionPrefix = "projects/${config.gcProject}/subscriptions/";

  Future<ps.PubsubApi> get _pubsubApi {
    if (_pubsubApiInst == null) {
      _pubsubApiInst = clientViaServiceAccount(config.credentials, _scopes).then((httpClient) {
        return new ps.PubsubApi(httpClient);
      });
    }
    return _pubsubApiInst;
  }

  Future<Iterable<String>> publish(String topic, Map map) async {
    var message = new ps.PubsubMessage();
    message.data = BASE64.encode(JSON.encode(map).codeUnits);

    var publishRequest = new ps.PublishRequest();
    publishRequest.messages = [message];

    var response = await (await _pubsubApi).projects.topics.publish(publishRequest, "${_topicPrefix}${topic}");
    return response.messageIds;
  }

  Future<Iterable<Map>> pull(String subscription) async {
    var pullRequest = new ps.PullRequest();
    pullRequest.returnImmediately = false;
    pullRequest.maxMessages = 1;
    var subscriptionName = "${_subscriptionPrefix}${subscription}";

    var messages;
    while (messages == null) {
      var pullResponse = await (await _pubsubApi).projects.subscriptions.pull(pullRequest, subscriptionName);
      if (pullResponse.receivedMessages != null) {
        messages = pullResponse.receivedMessages;
      }
    }

    var ackRequest = new ps.AcknowledgeRequest();
    ackRequest.ackIds = messages.map((rm) => rm.ackId).toList();

    await (await _pubsubApi).projects.subscriptions.acknowledge(ackRequest, subscriptionName);

    return messages.map((rm) {
      return JSON.decode(new String.fromCharCodes(BASE64.decode(rm.message.data)));
    }).first;
  }

}