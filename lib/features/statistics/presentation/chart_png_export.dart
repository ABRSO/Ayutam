import 'dart:io';
import 'dart:ui' as ui;

import 'package:file_picker/file_picker.dart';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;

/// Public Documents subfolder used as the default chart-export location
/// (`Documents/Ayutam/export-png`).
const chartExportRelativeDir = 'Ayutam/export-png';

const _androidChannel = MethodChannel('com.ayutam.ayutam/chart_export');

/// Renders the widget under [boundaryKey] to a PNG and saves it.
///
/// Encodes the chart first so Android's location sheet cannot cover it.
/// Desktop then opens a native save dialog (`file_selector`) starting in
/// `Documents/Ayutam/export-png`. Android asks whether to save to that same
/// Documents folder (MediaStore) or pick another location. Returns null when
/// cancelled.
Future<String?> exportChartPng(
  GlobalKey boundaryKey, {
  required String suggestedName,
  BuildContext? context,
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

  if (Platform.isAndroid) {
    _AndroidExportChoice? choice;
    if (context == null || !context.mounted) {
      choice = _AndroidExportChoice.chooseLocation;
    } else {
      choice = await showModalBottomSheet<_AndroidExportChoice>(
        context: context,
        showDragHandle: true,
        builder: (_) => const _AndroidExportSheet(),
      );
    }
    return switch (choice) {
      _AndroidExportChoice.documentsDefault => _saveAndroidDocumentsDefault(
        bytes,
        suggestedName,
      ),
      _AndroidExportChoice.chooseLocation => _saveAndroidChooseLocation(
        bytes,
        suggestedName,
      ),
      null => null,
    };
  }

  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    return _exportDesktop(bytes, suggestedName);
  }

  return null;
}

class _AndroidExportSheet extends StatelessWidget {
  const _AndroidExportSheet();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 8),
            child: Text(
              'Export chart PNG',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          ListTile(
            leading: const Icon(Icons.folder_special_outlined),
            title: const Text('Documents/Ayutam/export-png'),
            subtitle: const Text('Default location'),
            onTap: () =>
                Navigator.pop(context, _AndroidExportChoice.documentsDefault),
          ),
          ListTile(
            leading: const Icon(Icons.folder_open),
            title: const Text('Choose location…'),
            onTap: () =>
                Navigator.pop(context, _AndroidExportChoice.chooseLocation),
          ),
          ListTile(
            leading: const Icon(Icons.close),
            title: const Text('Cancel'),
            onTap: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }
}

Future<String?> _exportDesktop(Uint8List bytes, String suggestedName) async {
  final initialDir = await _ensureUserDocumentsExportDir();
  final location = await getSaveLocation(
    suggestedName: suggestedName,
    initialDirectory: initialDir,
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

Future<String?> _saveAndroidDocumentsDefault(
  Uint8List bytes,
  String suggestedName,
) async {
  try {
    return await _androidChannel.invokeMethod<String>(
      'savePngToDocuments',
      <String, dynamic>{
        'fileName': suggestedName,
        'relativeDir': chartExportRelativeDir,
        'bytes': bytes,
      },
    );
  } on PlatformException {
    // Channel missing / MediaStore failure → fall through to the system sheet.
    return _saveAndroidChooseLocation(bytes, suggestedName);
  } on MissingPluginException {
    return _saveAndroidChooseLocation(bytes, suggestedName);
  }
}

Future<String?> _saveAndroidChooseLocation(
  Uint8List bytes,
  String suggestedName,
) async {
  final uri = await FilePicker.saveFile(
    dialogTitle: 'Export chart PNG',
    fileName: suggestedName,
    bytes: bytes,
    mimeType: 'image/png',
    type: FileType.custom,
    allowedExtensions: const ['png'],
  );
  return uri?.toString();
}

/// `~/Documents/Ayutam/export-png` (Windows/Linux/macOS), created if missing.
Future<String?> _ensureUserDocumentsExportDir() async {
  final home =
      Platform.environment['USERPROFILE'] ?? Platform.environment['HOME'];
  if (home == null || home.isEmpty) {
    return null;
  }
  final dir = Directory(p.join(home, 'Documents', 'Ayutam', 'export-png'));
  await dir.create(recursive: true);
  return dir.path;
}

enum _AndroidExportChoice { documentsDefault, chooseLocation }
