import 'package:cloud_firestore/cloud_firestore.dart';

DateTime readFirestoreDate(Object? value) {
  if (value is Timestamp) {
    return value.toDate();
  }
  if (value is DateTime) {
    return value;
  }
  if (value is String) {
    return DateTime.parse(value);
  }
  throw ArgumentError('Unsupported date value: $value');
}
