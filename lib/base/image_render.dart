import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:gui/base/parsers.dart';

// 3th party
import 'package:flutter_svg/flutter_svg.dart';
import 'package:gui/base/ui_render.dart';
import 'package:gui/main.dart';
import 'package:http/http.dart' as http;

// ---------------------------------------------------------------
// RemoteImage Widget
// ---------------------------------------------------------------
class RemoteImage extends StatelessWidget {
  final String hash;

  const RemoteImage({
    super.key,
    required this.hash,
  });

  @override
  Widget build(BuildContext context) {
    final node = nodeStore.get(hash);
    if (node == null) return const SizedBox.shrink();

    return ListenableBuilder(
      listenable: node,
      builder: (context, _) {
        final props = node.props;

        final bool isVisible =
            props['visible'] != false && props['visible'] != 'false';

        if (!isVisible) {
          return const SizedBox.shrink();
        }

        final String? imageUrl = _nullableString(props['image']);

        if (imageUrl == null || imageUrl.isEmpty) {
          return const SizedBox.shrink();
        }

        final EdgeInsets padding =
            parseEdgeInsets(props['padding']?.toString() ?? '0') ??
                EdgeInsets.zero;

        final BoxFit? fit = parseFit(
          _nullableString(props['fit']),
        );

        final String? width = _nullableString(props['width']);
        final String? height = _nullableString(props['height']);

        final double? widthValue = _parsePixelValue(width);
        final double? heightValue = _parsePixelValue(height);

        final double? widthFactor = _parsePercent(width);
        final double? heightFactor = _parsePercent(height);

        Widget image = _RemoteImageContent(
          url: imageUrl,
          fit: fit,
          width: widthValue,
          height: heightValue,
        );

        if (widthFactor != null || heightFactor != null) {
          image = FractionallySizedBox(
            widthFactor: widthFactor,
            heightFactor: heightFactor,
            child: image,
          );
        }

        image = Padding(
          padding: padding,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {
              selectMe(hash);
            },
            child: image,
          ),
        );



        final String? align = _nullableString(props['align']);

        switch (align) {
          case 'left':
            return Align(
              alignment: Alignment.centerLeft,
              child: image,
            );

          case 'right':
            return Align(
              alignment: Alignment.centerRight,
              child: image,
            );

          case 'center':
          case null:
            return Align(
              alignment: Alignment.center,
              child: image,
            );

          default:
            return image;
        }
      },
    );
  }

  static String? _nullableString(dynamic value) {
    if (value == null || value.toString() == 'null') {
      return null;
    }

    return value.toString();
  }

  static double? _parsePixelValue(String? value) {
    if (value == null || value.endsWith('%')) {
      return null;
    }

    return double.tryParse(value);
  }

  static double? _parsePercent(String? value) {
    if (value == null || !value.endsWith('%')) {
      return null;
    }

    final double? number = double.tryParse(
      value.substring(0, value.length - 1),
    );

    if (number == null) {
      return null;
    }

    return number / 100;
  }
}

// ---------------------------------------------------------------
// Remote Image Content
// ---------------------------------------------------------------
class _RemoteImageContent extends StatefulWidget {
  final String url;
  final BoxFit? fit;
  final double? width;
  final double? height;

  const _RemoteImageContent({
    required this.url,
    required this.fit,
    required this.width,
    required this.height,
  });

  @override
  State<_RemoteImageContent> createState() => _RemoteImageContentState();
}

class _RemoteImageContentState extends State<_RemoteImageContent> {
  late Future<_RemoteImageData> _imageFuture;

  @override
  void initState() {
    super.initState();
    _imageFuture = _loadImage();
  }

  @override
  void didUpdateWidget(covariant _RemoteImageContent oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.url != widget.url) {
      _imageFuture = _loadImage();
    }
  }

  Future<_RemoteImageData> _loadImage() async {
    final response = await http.get(Uri.parse(widget.url));

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        'Failed to load image: HTTP ${response.statusCode}',
      );
    }

    final contentType =
        response.headers['content-type']?.toLowerCase() ?? '';

    return _RemoteImageData(
      bytes: response.bodyBytes,
      contentType: contentType,
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_RemoteImageData>(
      future: _imageFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return SizedBox(
            width: widget.width,
            height: widget.height,
          );
        }

        if (snapshot.hasError || !snapshot.hasData) {
          return SizedBox(
            width: widget.width,
            height: widget.height,
          );
        }

        final data = snapshot.data!;

        if (data.contentType.contains('svg')) {
          return SvgPicture.memory(
            data.bytes,
            width: widget.width,
            height: widget.height,
            fit: widget.fit ?? BoxFit.contain,
          );
        }

        return Image.memory(
          data.bytes,
          width: widget.width,
          height: widget.height,
          fit: widget.fit,
        );
      },
    );
  }
}

// ---------------------------------------------------------------
// Remote Image Data
// ---------------------------------------------------------------
class _RemoteImageData {
  final Uint8List bytes;
  final String contentType;

  const _RemoteImageData({
    required this.bytes,
    required this.contentType,
  });
}