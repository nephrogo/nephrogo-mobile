import 'package:flutter/material.dart';

extension DateTimeExtension on DateTime {
  // https://stackoverflow.com/questions/50198891/how-to-convert-flutter-timeofday-to-datetime
  DateTime applied(TimeOfDay time) {
    return DateTime(year, month, day, time.hour, time.minute);
  }

  // https://stackoverflow.com/questions/52627973/dart-how-to-set-the-hour-and-minute-of-datetime-object
  DateTime copyWith(
      {int year,
      int month,
      int day,
      int hour,
      int minute,
      int second,
      int millisecond,
      int microsecond}) {
    return DateTime(
      year ?? this.year,
      month ?? this.month,
      day ?? this.day,
      hour ?? this.hour,
      minute ?? this.minute,
      second ?? this.second,
      millisecond ?? this.millisecond,
      microsecond ?? this.microsecond,
    );
  }
}