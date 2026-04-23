import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

/// Renders a Flutter widget to a PNG off-screen — no need to mount it in
/// your UI first. Pair with [NotificationMessage.fromPluginTemplate]'s
/// `heroImage` field to put live-generated content in a toast.
///
/// Usage:
///
/// ```dart
/// final path = await WidgetToImage.toPngFile(
///   widget: MyRichToastCard(user: user),
///   size: const Size(364, 180),
/// );
/// await notifier.showNotificationPluginTemplate(
///   NotificationMessage.fromPluginTemplate(
///     'rich', 'Title', 'Body',
///     heroImage: path,
///   ),
/// );
/// ```
///
/// Windows toast hero images are sized 364 x 180 DIPs (≈ 3:1.47). Anything
/// taller/wider gets scaled. For crisp output on high-DPI displays pass a
/// higher [pixelRatio] (the PNG itself becomes larger, but Windows scales
/// down cleanly).
class WidgetToImage {
  WidgetToImage._();

  /// Render [widget] at [size] logical pixels and return the raw PNG bytes.
  ///
  /// [pixelRatio] scales the output bitmap — 2.0 gives a 2× PNG.
  /// [waitBeforeCapture] is useful when the widget kicks off an image load or
  /// other async work; Flutter can't otherwise tell us "the paint is stable".
  /// [theme] optionally wraps the widget in `Theme` for Material styling.
  static Future<Uint8List> toPng({
    required Widget widget,
    required Size size,
    double pixelRatio = 2.0,
    Duration waitBeforeCapture = Duration.zero,
    ThemeData? theme,
  }) async {
    WidgetsFlutterBinding.ensureInitialized();

    final repaintBoundary = RenderRepaintBoundary();
    final flutterView =
        WidgetsBinding.instance.platformDispatcher.views.first;
    final renderView = RenderView(
      view: flutterView,
      configuration: ViewConfiguration(
        physicalConstraints: BoxConstraints.tight(size * pixelRatio),
        logicalConstraints: BoxConstraints.tight(size),
        devicePixelRatio: pixelRatio,
      ),
      child: RenderPositionedBox(
        alignment: Alignment.center,
        child: repaintBoundary,
      ),
    );

    final pipelineOwner = PipelineOwner();
    final buildOwner = BuildOwner(focusManager: FocusManager());

    pipelineOwner.rootNode = renderView;
    renderView.prepareInitialFrame();

    Widget tree = MediaQuery(
      data: MediaQueryData(size: size, devicePixelRatio: pixelRatio),
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: SizedBox.fromSize(size: size, child: widget),
      ),
    );
    if (theme != null) {
      tree = Theme(data: theme, child: tree);
    }

    // ignore: deprecated_member_use
    final rootElement = RenderObjectToWidgetAdapter<RenderBox>(
      container: repaintBoundary,
      child: tree,
    ).attachToRenderTree(buildOwner);

    buildOwner
      ..buildScope(rootElement)
      ..finalizeTree();

    pipelineOwner
      ..flushLayout()
      ..flushCompositingBits()
      ..flushPaint();

    if (waitBeforeCapture > Duration.zero) {
      await Future<void>.delayed(waitBeforeCapture);
      pipelineOwner
        ..flushLayout()
        ..flushCompositingBits()
        ..flushPaint();
    }

    final ui.Image image =
        await repaintBoundary.toImage(pixelRatio: pixelRatio);
    try {
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) {
        throw StateError('toByteData returned null for rendered widget');
      }
      return byteData.buffer.asUint8List();
    } finally {
      image.dispose();
    }
  }

  /// Render [widget] and write it to disk. Returns the file path.
  ///
  /// [filePath] is where the PNG lands. If null, writes to a plugin-owned
  /// temp directory under the OS temp root and returns that path — callers
  /// are responsible for cleanup (stale files accumulate across runs).
  static Future<String> toPngFile({
    required Widget widget,
    required Size size,
    double pixelRatio = 2.0,
    Duration waitBeforeCapture = Duration.zero,
    ThemeData? theme,
    String? filePath,
  }) async {
    final bytes = await toPng(
      widget: widget,
      size: size,
      pixelRatio: pixelRatio,
      waitBeforeCapture: waitBeforeCapture,
      theme: theme,
    );
    final path = filePath ?? _defaultPngPath();
    final file = File(path);
    await file.parent.create(recursive: true);
    await file.writeAsBytes(bytes, flush: true);
    return file.path;
  }

  static String _defaultPngPath() {
    final dir = Directory('${Directory.systemTemp.path}/windows_notification');
    final name = 'hero_${DateTime.now().microsecondsSinceEpoch}.png';
    return '${dir.path}/$name';
  }
}
