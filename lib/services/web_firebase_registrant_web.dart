// Explicit Firebase Web plugin registration to ensure FirebasePlatform.instance
// is set to FirebaseCoreWeb instead of falling back to Pigeon MethodChannel (which is native only).
import 'package:cloud_firestore_web/cloud_firestore_web.dart';
import 'package:firebase_auth_web/firebase_auth_web.dart';
import 'package:firebase_core_web/firebase_core_web.dart';
import 'package:firebase_storage_web/firebase_storage_web.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_web_plugins/flutter_web_plugins.dart';

void registerWebFirebasePlugins() {
  try {
    FirebaseCoreWeb.registerWith(webPluginRegistrar);
  } catch (e) {
    debugPrint('FirebaseCoreWeb.registerWith notice: $e');
  }
  try {
    FirebaseAuthWeb.registerWith(webPluginRegistrar);
  } catch (e) {
    debugPrint('FirebaseAuthWeb.registerWith notice: $e');
  }
  try {
    FirebaseFirestoreWeb.registerWith(webPluginRegistrar);
  } catch (e) {
    debugPrint('FirebaseFirestoreWeb.registerWith notice: $e');
  }
  try {
    FirebaseStorageWeb.registerWith(webPluginRegistrar);
  } catch (e) {
    debugPrint('FirebaseStorageWeb.registerWith notice: $e');
  }
}
