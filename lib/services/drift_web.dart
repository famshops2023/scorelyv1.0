// ignore: deprecated_member_use
import 'package:drift/web.dart';
import 'package:drift/drift.dart';

DatabaseConnection connect() {
  return DatabaseConnection(
    WebDatabase('scorely_db', logStatements: false),
  );
}
