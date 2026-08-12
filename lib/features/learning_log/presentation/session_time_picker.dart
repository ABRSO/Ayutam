import 'package:flutter/material.dart';

/// Date+time picker that cannot choose a calendar day after today.
///
/// Combined datetimes later than now are rejected (snackbar) so completed /
/// manual sessions cannot be dated in the future.
Future<DateTime?> pickCompletedSessionDateTime(
  BuildContext context,
  DateTime initial,
) async {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final firstDate = DateTime(1970);
  var initialDate = DateTime(initial.year, initial.month, initial.day);
  if (initialDate.isAfter(today)) initialDate = today;
  if (initialDate.isBefore(firstDate)) initialDate = firstDate;

  final date = await showDatePicker(
    context: context,
    initialDate: initialDate,
    firstDate: firstDate,
    lastDate: today,
  );
  if (date == null || !context.mounted) return null;
  final time = await showTimePicker(
    context: context,
    initialTime: TimeOfDay.fromDateTime(initial),
  );
  if (time == null || !context.mounted) return null;
  final picked = DateTime(
    date.year,
    date.month,
    date.day,
    time.hour,
    time.minute,
  );
  if (picked.isAfter(DateTime.now())) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Session times cannot be in the future.')),
    );
    return null;
  }
  return picked;
}

bool sessionLocalTimesAreInTheFuture(DateTime startLocal, DateTime endLocal) {
  final now = DateTime.now();
  return startLocal.isAfter(now) || endLocal.isAfter(now);
}
