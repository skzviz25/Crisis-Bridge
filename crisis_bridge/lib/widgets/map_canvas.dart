import 'package:crisis_bridge/core/constants.dart';
import 'package:crisis_bridge/models/floor_area_model.dart';
import 'package:flutter/material.dart';

class MapCanvas extends StatelessWidget {
  final List<FloorAreaModel> areas;
  final Set<String> dangerAreaIds;
  final List<FloorAreaModel> route;
  final void Function(double x, double y)? onTap;
  final void Function(FloorAreaModel)? onAreaLongPress;

  const MapCanvas({
    super.key,
    required this.areas,
    required this.dangerAreaIds,
    required this.route,
    required this.onTap,
    required this.onAreaLongPress,
  });

  Color _colorForType(String type, bool isDanger) {
    if (isDanger) return const Color(0xFFFF4444);
    switch (type) {
      case AppConstants.typeRoom:
        return const Color(0xFF00FF88);
      case AppConstants.typeHall:
        return const Color(0xFF0088FF);
      case AppConstants.typeStair:
        return const Color(0xFFFFAA00);
      case AppConstants.typeExit:
        return const Color(0xFF00FFFF);
      case AppConstants.typeDanger:
        return const Color(0xFFFF4444);
      default:
        return const Color(0xFF888888);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapUp: onTap == null
          ? null
          : (details) {
              final box = context.findRenderObject() as RenderBox?;
              if (box == null) return;
              final size = box.size;
              final local = details.localPosition;
              onTap!(local.dx / size.width, local.dy / size.height);
            },
      child: CustomPaint(
        painter: _MapPainter(
          areas: areas,
          dangerAreaIds: dangerAreaIds,
          route: route,
          colorForType: _colorForType,
        ),
        child: Stack(
          children: areas.map((a) {
            return Positioned(
              left: null,
              top: null,
              child: FractionallySizedBox(
                child: GestureDetector(
                  onLongPress: onAreaLongPress == null ? null : () => onAreaLongPress!(a),
                  child: const SizedBox.shrink(),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

class _MapPainter extends CustomPainter {
  final List<FloorAreaModel> areas;
  final Set<String> dangerAreaIds;
  final List<FloorAreaModel> route;
  final Color Function(String type, bool isDanger) colorForType;

  const _MapPainter({
    required this.areas,
    required this.dangerAreaIds,
    required this.route,
    required this.colorForType,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Grid
    final gridPaint = Paint()
      ..color = const Color(0xFF003322)
      ..strokeWidth = 0.5;
    for (double x = 0; x < size.width; x += 40) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (double y = 0; y < size.height; y += 40) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    // Connection edges
    final edgePaint = Paint()
      ..color = const Color(0xFF005533)
      ..strokeWidth = 1;
    final Map<String, FloorAreaModel> areaMap = {for (final a in areas) a.id: a};
    for (final area in areas) {
      final p1 = Offset(area.x * size.width, area.y * size.height);
      for (final neighborId in area.connectedAreaIds) {
        final neighbor = areaMap[neighborId];
        if (neighbor != null) {
          final p2 = Offset(neighbor.x * size.width, neighbor.y * size.height);
          canvas.drawLine(p1, p2, edgePaint);
        }
      }
    }

    // Route highlight
    if (route.length > 1) {
      final routePaint = Paint()
        ..color = const Color(0xFF00FF88)
        ..strokeWidth = 3
        ..style = PaintingStyle.stroke;
      final path = Path();
      for (int i = 0; i < route.length; i++) {
        final pt = Offset(route[i].x * size.width, route[i].y * size.height);
        if (i == 0) {
          path.moveTo(pt.dx, pt.dy);
        } else {
          path.lineTo(pt.dx, pt.dy);
        }
      }
      // Dashed line simulation
      canvas.drawPath(path, routePaint);
    }

    // Area nodes
    for (final area in areas) {
      final isDanger = dangerAreaIds.contains(area.id);
      final color = colorForType(area.type, isDanger);
      final center = Offset(area.x * size.width, area.y * size.height);
      const radius = 12.0;

      // Glow for danger
      if (isDanger) {
        canvas.drawCircle(
          center,
          radius + 6,
          Paint()..color = const Color(0x44FF4444),
        );
      }

      canvas.drawCircle(center, radius, Paint()..color = color);

      // Label
      final tp = TextPainter(
        text: TextSpan(
          text: area.name.length > 8 ? '${area.name.substring(0, 7)}…' : area.name,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 9,
            fontFamily: 'monospace',
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: 80);
      tp.paint(canvas, center.translate(-tp.width / 2, radius + 4));
    }
  }

  @override
  bool shouldRepaint(covariant _MapPainter old) =>
      old.areas != areas || old.dangerAreaIds != dangerAreaIds || old.route != route;
}