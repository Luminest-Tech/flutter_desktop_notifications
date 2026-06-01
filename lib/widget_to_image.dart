import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

/// Renders a Flutter widget to a PNG off-screen. Pair with a
/// `NotificationMessage.fromPluginTemplate`'s `heroImage` to put
/// live-generated content in a toast.
///
/// ```dart
/// final path = await WidgetToImage.toPngFile(
///   widget: MyRichToastCard(user: user),
///   size: const Size(364, 180),
/// );
/// ```
///
/// Toast hero images are sized 364 x 180 DIPs. For crisp output on high-DPI
/// displays, pass a higher [pixelRatio].
class WidgetToImage {
  WidgetToImage._();

  /// [waitBeforeCapture] gives async work in the widget (network images,
  /// etc.) a chance to land before capture.
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

  /// [filePath] is where to write the PNG. If null, writes under the OS
  /// temp root; stale files accumulate until cleaned up by the caller.
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
    final dir =
        Directory('${Directory.systemTemp.path}/flutter_windows_notification');
    final name = 'hero_${DateTime.now().microsecondsSinceEpoch}.png';
    return '${dir.path}/$name';
  }
}
