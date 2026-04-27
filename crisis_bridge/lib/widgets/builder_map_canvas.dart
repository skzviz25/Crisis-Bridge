// lib/widgets/builder_map_canvas.dart
import 'package:crisis_bridge/core/constants.dart';
import 'package:crisis_bridge/models/floor_area_model.dart';
import 'package:flutter/material.dart';
 
class BuilderMapCanvas extends StatelessWidget {
  final List<FloorAreaModel> areas;
  final Set<String> dangerAreaIds;
  final String? selectedAreaId;
  final String? connectingAreaId;
  final bool showCurrentPosition;
  final double? currentPosX;
  final double? currentPosY;
  final void Function(double x, double y)? onCanvasTap;
  final void Function(FloorAreaModel)? onAreaTap;
 
  const BuilderMapCanvas({
    super.key,
    required this.areas,
    required this.dangerAreaIds,
    required this.selectedAreaId,
    required this.connectingAreaId,
    required this.showCurrentPosition,
    required this.currentPosX,
    required this.currentPosY,
    required this.onCanvasTap,
    required this.onAreaTap,
  });
 
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (ctx, constraints) {
      final w = constraints.maxWidth;
      final h = constraints.maxHeight;
      const nodeR = 22.0;
 
      return GestureDetector(
        onTapUp: (d) {
          final dx = d.localPosition.dx;
          final dy = d.localPosition.dy;
 
          // Check node hit first
          for (final area in areas) {
            final nx = area.x * w;
            final ny = area.y * h;
            if ((Offset(dx, dy) - Offset(nx, ny)).distance <= nodeR + 10) {
              onAreaTap?.call(area);
              return;
            }
          }
          // Canvas tap
          onCanvasTap?.call(dx / w, dy / h);
        },
        child: CustomPaint(
          painter: _BuilderPainter(
            areas: areas,
            dangerAreaIds: dangerAreaIds,
            selectedAreaId: selectedAreaId,
            connectingAreaId: connectingAreaId,
            showCurrentPosition: showCurrentPosition,
            currentPosX: currentPosX,
            currentPosY: currentPosY,
          ),
          child: const SizedBox.expand(),
        ),
      );
    });
  }
}
 
class _BuilderPainter extends CustomPainter {
  final List<FloorAreaModel> areas;
  final Set<String> dangerAreaIds;
  final String? selectedAreaId;
  final String? connectingAreaId;
  final bool showCurrentPosition;
  final double? currentPosX;
  final double? currentPosY;
 
  const _BuilderPainter({
    required this.areas,
    required this.dangerAreaIds,
    required this.selectedAreaId,
    required this.connectingAreaId,
    required this.showCurrentPosition,
    required this.currentPosX,
    required this.currentPosY,
  });
 
  Color _colorForType(String type, bool isDanger) {
    if (isDanger) return const Color(0xFFFF4444);
    switch (type) {
      case AppConstants.typeExit:    return const Color(0xFF00FFFF);
      case AppConstants.typeStair:   return const Color(0xFFFFAA00);
      case AppConstants.typeHall:    return const Color(0xFF0088FF);
      case AppConstants.typeDanger:  return const Color(0xFFFF4444);
      default:                       return const Color(0xFF00FF88);
    }
  }
 
  @override
  void paint(Canvas canvas, Size size) {
    _drawGrid(canvas, size);
    _drawGridLabels(canvas, size);
    _drawEdges(canvas, size);
    _drawNodes(canvas, size);
    if (showCurrentPosition &&
        currentPosX != null &&
        currentPosY != null) {
      _drawCurrentPosition(canvas, size);
    }
  }
 
  void _drawGrid(Canvas canvas, Size size) {
    final p = Paint()
      ..color = const Color(0xFF003322)
      ..strokeWidth = 0.5;
    for (double x = 0; x < size.width; x += size.width / 10) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), p);
    }
    for (double y = 0; y < size.height; y += size.height / 10) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), p);
    }
  }
 
  void _drawGridLabels(Canvas canvas, Size size) {
    // X labels across top
    for (int i = 0; i <= 10; i += 2) {
      final x = i / 10.0;
      final tp = TextPainter(
        text: TextSpan(
          text: x.toStringAsFixed(1),
          style: const TextStyle(
              color: Color(0xFF224422), fontSize: 8, fontFamily: 'monospace'),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(x * size.width + 2, 2));
    }
    // Y labels down left
    for (int i = 0; i <= 10; i += 2) {
      final y = i / 10.0;
      final tp = TextPainter(
        text: TextSpan(
          text: y.toStringAsFixed(1),
          style: const TextStyle(
              color: Color(0xFF224422), fontSize: 8, fontFamily: 'monospace'),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(2, y * size.height + 2));
    }
  }
 
  void _drawEdges(Canvas canvas, Size size) {
    final p = Paint()
      ..color = const Color(0xFF226622)
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
 
    final Map<String, FloorAreaModel> areaMap = {
      for (final a in areas) a.id: a
    };
    final drawn = <String>{};
 
    for (final area in areas) {
      for (final nId in area.connectedAreaIds) {
        final key = ([area.id, nId]..sort()).join('-');
        if (drawn.contains(key)) continue;
        drawn.add(key);
        final n = areaMap[nId];
        if (n == null) continue;
        canvas.drawLine(
          Offset(area.x * size.width, area.y * size.height),
          Offset(n.x * size.width, n.y * size.height),
          p,
        );
      }
    }
  }
 
  void _drawNodes(Canvas canvas, Size size) {
    for (final area in areas) {
      final isDanger = dangerAreaIds.contains(area.id);
      final isSelected = area.id == selectedAreaId;
      final isConnecting = area.id == connectingAreaId;
      final center = Offset(area.x * size.width, area.y * size.height);
      const r = 22.0;
      final color = _colorForType(area.type, isDanger);
 
      // Danger glow
      if (isDanger) {
        canvas.drawCircle(
            center, r + 8, Paint()..color = const Color(0x44FF4444));
      }
 
      // Selection ring
      if (isSelected) {
        canvas.drawCircle(
            center,
            r + 7,
            Paint()
              ..color = const Color(0xFF00FF88)
              ..style = PaintingStyle.stroke
              ..strokeWidth = 3);
      }
 
      // Connecting ring (first node picked in connect mode)
      if (isConnecting) {
        canvas.drawCircle(
            center,
            r + 7,
            Paint()
              ..color = const Color(0xFFFFAA00)
              ..style = PaintingStyle.stroke
              ..strokeWidth = 3);
      }
 
      // Fill
      canvas.drawCircle(center, r, Paint()..color = color);
 
      // Border
      canvas.drawCircle(
          center,
          r,
          Paint()
            ..color = Colors.black.withAlpha(80)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.5);
 
      // Coordinate text inside node
      final coordTp = TextPainter(
        text: TextSpan(
          text: '${area.x.toStringAsFixed(2)},${area.y.toStringAsFixed(2)}',
          style: const TextStyle(
              color: Colors.white70,
              fontSize: 7,
              fontFamily: 'monospace'),
        ),
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: 56);
      coordTp.paint(
          canvas,
          center.translate(
              -coordTp.width / 2, -coordTp.height / 2));
 
      // Name label below node
      final display =
          area.name.length > 8 ? '${area.name.substring(0, 7)}…' : area.name;
      final tp = TextPainter(
        text: TextSpan(
          text: display,
          style: TextStyle(
            color: isSelected
                ? const Color(0xFF00FF88)
                : const Color(0xFFDDFFDD),
            fontSize: 10,
            fontFamily: 'monospace',
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: 90);
      tp.paint(canvas, center.translate(-tp.width / 2, r + 5));
    }
  }
 
  void _drawCurrentPosition(Canvas canvas, Size size) {
    final cx = currentPosX! * size.width;
    final cy = currentPosY! * size.height;
    final center = Offset(cx, cy);
 
    // Pulsing outer ring
    canvas.drawCircle(
        center, 24, Paint()..color = const Color(0x330088FF));
    canvas.drawCircle(
        center, 16, Paint()..color = const Color(0x660088FF));
 
    // Inner dot
    canvas.drawCircle(center, 8, Paint()..color = const Color(0xFF0088FF));
    canvas.drawCircle(
        center,
        8,
        Paint()
          ..color = Colors.white
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2);
 
    // "YOU" label
    final tp = TextPainter(
      text: const TextSpan(
        text: 'YOU',
        style: TextStyle(
            color: Color(0xFF0088FF),
            fontSize: 10,
            fontFamily: 'monospace',
            fontWeight: FontWeight.bold),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, center.translate(-tp.width / 2, 12));
  }
 
  @override
  bool shouldRepaint(covariant _BuilderPainter old) =>
      old.areas != areas ||
      old.dangerAreaIds != dangerAreaIds ||
      old.selectedAreaId != selectedAreaId ||
      old.connectingAreaId != connectingAreaId ||
      old.currentPosX != currentPosX ||
      old.currentPosY != currentPosY;
}
 