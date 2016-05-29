library crossdart_analyzer.config;

import 'package:googleapis_auth/auth.dart';
import 'package:yaml/yaml.dart' as yaml;
import 'package:path/path.dart' as p;
import 'dart:io';
import 'dart:convert';

class Config {
  final int port;
  final String hostedUrl;
  final String urlPathPrefix;
  final String crossdartUrlPathPrefix;
  final String workingDir;
  final String outputDir;
  final String dartSdk;
  final String bucket;
  final ServiceAccountCredentials credentials;

  factory Config.build(String dirroot) {
    dirroot ??= Directory.current.path;
    var configValues = yaml.loadYaml(new File(p.join(dirroot, "config.yaml")).readAsStringSync());
    var credentialsValues = yaml.loadYaml(new File(p.join(dirroot, "credentials.yaml")).readAsStringSync());
    var serviceAccountCredentials = new ServiceAccountCredentials.fromJson(JSON.encode(credentialsValues));
    return new Config._(
        hostedUrl: configValues["hosted_url"],
        urlPathPrefix: configValues["url_path_prefix"],
        crossdartUrlPathPrefix: configValues["crossdart_url_path_prefix"],
        workingDir: configValues["working_dir"],
        outputDir: configValues["output_dir"],
        bucket: configValues["bucket"],
        dartSdk: configValues["dart_sdk"],
        credentials: serviceAccountCredentials);
  }

  Config._({
      this.port: 5001,
      this.hostedUrl,
      this.urlPathPrefix,
      this.workingDir,
      this.outputDir,
      this.dartSdk,
      this.bucket,
      this.crossdartUrlPathPrefix,
      this.credentials});
}