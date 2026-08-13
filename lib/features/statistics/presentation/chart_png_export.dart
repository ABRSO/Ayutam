import 'dart:io';
import 'dart:ui' as ui;

import 'package:file_selector/file_selector.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Renders the widget under [boundaryKey] to a PNG and saves it.
///
/// Desktop shows a native save dialog (`file_selector`); Android has no save
/// dialog support, so the file lands in the app documents folder and the
/// returned path is surfaced to the user. Returns null when cancelled.
Future<String?> exportChartPng(
  GlobalKey boundaryKey, {
  required String suggestedName,
}) async {
  final boundary =
      boundaryKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
  if (boundary == null) {
    return null;
  }
  final image = await boundary.toImage(pixelRatio: 3);
  final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
  image.dispose();
  if (byteData == null) {
    return null;
  }
  final bytes = byteData.buffer.asUint8List();

  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    final location = await getSaveLocation(
      suggestedName: suggestedName,
      acceptedTypeGroups: const [
        XTypeGroup(label: 'PNG image', extensions: ['png']),
      ],
    );
    if (location == null) {
      return null;
    }
    await File(location.path).writeAsBytes(bytes, flush: true);
    return location.path;
  }

  final dir = await getApplicationDocumentsDirectory();
  final path = p.join(dir.path, suggestedName);
  await File(path).writeAsBytes(bytes, flush: true);
  return path;
}
