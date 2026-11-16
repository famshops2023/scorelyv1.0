// ignore: deprecated_member_use
import 'package:drift/web.dart';
import 'package:drift/drift.dart';

DatabaseConnection connect() {
  return DatabaseConnection(
    WebDatabase.withStorage(
      // ignore: experimental_member_use
      DriftWebStorage.indexedDb('scorely_db'),
      logStatements: false,
    ),
  );
}
