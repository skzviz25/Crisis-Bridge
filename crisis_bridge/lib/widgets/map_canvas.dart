import 'package:crisis_bridge/core/constants.dart';
import 'package:crisis_bridge/models/floor_area_model.dart';
import 'package:crisis_bridge/screens/staff/map_update_screen.dart';
import 'package:flutter/material.dart';

// ── Original read-only canvas (used in RouteScreen / UserHomeScreen) ──────────
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

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapUp: onTap == null
          ? null
          : (d) {
              final box = context.findRenderObject() as RenderBox?;
              if (box == null) return;
              final size = box.size;
              onTap!(
                d.localPosition.dx / size.width,
                d.localPosition.dy / size.height,
              );
            },
      child: CustomPaint(
        painter: MapPainter(
          areas: areas,
          dangerAreaIds: dangerAreaIds,
          route: route,
        ),
        child: const SizedBox.expand(),
      ),
    );
  }
}

// ── Interactive canvas for map builder ───────────────────────────────────────
class MapCanvasInteractive extends StatelessWidget {
  final List<FloorAreaModel> areas;
  final Set<String> dangerAreaIds;
  final String? selectedAreaId;
  final String? connectingAreaId;
  final MapEditMode mode;
  final void Function(double x, double y) onCanvasTap;
  final void Function(FloorAreaModel) onAreaTap;

  const MapCanvasInteractive({
    super.key,
    required this.areas,
    required this.dangerAreaIds,
    required this.selectedAreaId,
    required this.connectingAreaId,
    required this.mode,
    required this.onCanvasTap,
    required this.onAreaTap,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final w = constraints.maxWidth;
      final h = constraints.maxHeight;
      const nodeRadius = 22.0;

      return GestureDetector(
        onTapUp: (d) {
          final dx = d.localPosition.dx;
          final dy = d.localPosition.dy;

          // Check if any node was tapped
          for (final area in areas) {
            final nx = area.x * w;
            final ny = area.y * h;
            final dist = (Offset(dx, dy) - Offset(nx, ny)).distance;
            if (dist <= nodeRadius + 8) {
              onAreaTap(area);
              return;
            }
          }

          // Otherwise it's a canvas tap (add mode)
          if (mode == MapEditMode.addNode) {
            onCanvasTap(dx / w, dy / h);
          }
        },
        child: CustomPaint(
          painter: MapPainterInteractive(
            areas: areas,
            dangerAreaIds: dangerAreaIds,
            selectedAreaId: selectedAreaId,
            connectingAreaId: connectingAreaId,
            mode: mode,
          ),
          child: const SizedBox.expand(),
        ),
      );
    });
  }
}

// ── Shared painter for read-only canvas ──────────────────────────────────────
class MapPainter extends CustomPainter {
  final List<FloorAreaModel> areas;
  final Set<String> dangerAreaIds;
  final List<FloorAreaModel> route;

  const MapPainter({
    required this.areas,
    required this.dangerAreaIds,
    required this.route,
  });

  @override
  void paint(Canvas canvas, Size size) {
    _drawGrid(canvas, size);
    _drawEdges(canvas, size);
    if (route.length > 1) _drawRoute(canvas, size, route);
    _drawNodes(canvas, size, dangerAreaIds, null, null);
  }

  void _drawGrid(Canvas canvas, Size size) {
    final p = Paint()
      ..color = const Color(0xFF003322)
      ..strokeWidth = 0.5;
    for (double x = 0; x < size.width; x += 40) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), p);
    }
    for (double y = 0; y < size.height; y += 40) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), p);
    }
  }

  void _drawEdges(Canvas canvas, Size size) {
    final p = Paint()
      ..color = const Color(0xFF005533)
      ..strokeWidth = 1.5;
    final Map<String, FloorAreaModel> map = {for (final a in areas) a.id: a};
    final drawn = <String>{};
    for (final area in areas) {
      for (final nId in area.connectedAreaIds) {
        final key =
            ([area.id, nId]..sort()).join('-');
        if (drawn.contains(key)) continue;
        drawn.add(key);
        final n = map[nId];
        if (n == null) continue;
        canvas.drawLine(
          Offset(area.x * size.width, area.y * size.height),
          Offset(n.x * size.width, n.y * size.height),
          p,
        );
      }
    }
  }

  void _drawRoute(Canvas canvas, Size size, List<FloorAreaModel> route) {
    final p = Paint()
      ..color = const Color(0xFF00FF88)
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    for (int i = 0; i < route.length - 1; i++) {
      canvas.drawLine(
        Offset(route[i].x * size.width, route[i].y * size.height),
        Offset(route[i + 1].x * size.width, route[i + 1].y * size.height),
        p,
      );
    }
  }

  void _drawNodes(Canvas canvas, Size size, Set<String> dangerAreaIds,
      String? selectedId, String? connectingId) {
    for (final area in areas) {
      final isDanger = dangerAreaIds.contains(area.id);
      final center = Offset(area.x * size.width, area.y * size.height);
      const r = 22.0;
      final color = _colorForType(area.type, isDanger);

      if (isDanger) {
        canvas.drawCircle(
            center, r + 6, Paint()..color = const Color(0x44FF4444));
      }
      canvas.drawCircle(center, r, Paint()..color = color);
      canvas.drawCircle(
          center,
          r,
          Paint()
            ..color = Colors.black.withAlpha(60)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.5);

      _drawLabel(canvas, area.name, center, r);
    }
  }

  void _drawLabel(Canvas canvas, String name, Offset center, double r) {
    final display = name.length > 7 ? '${name.substring(0, 6)}…' : name;
    final tp = TextPainter(
      text: TextSpan(
        text: display,
        style: const TextStyle(
            color: Colors.white,
            fontSize: 9,
            fontFamily: 'monospace',
            fontWeight: FontWeight.bold),
      ),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: 80);
    tp.paint(canvas, center.translate(-tp.width / 2, r + 4));
  }

  Color _colorForType(String type, bool isDanger) {
    if (isDanger) return const Color(0xFFFF4444);
    switch (type) {
      case AppConstants.typeExit:   return const Color(0xFF00FFFF);
      case AppConstants.typeStair:  return const Color(0xFFFFAA00);
      case AppConstants.typeHall:   return const Color(0xFF0088FF);
      case AppConstants.typeDanger: return const Color(0xFFFF4444);
      default:                      return const Color(0xFF00FF88);
    }
  }

  @override
  bool shouldRepaint(covariant MapPainter old) =>
      old.areas != areas ||
      old.dangerAreaIds != dangerAreaIds ||
      old.route != route;
}

// ── Interactive painter (map builder) ────────────────────────────────────────
class MapPainterInteractive extends CustomPainter {
  final List<FloorAreaModel> areas;
  final Set<String> dangerAreaIds;
  final String? selectedAreaId;
  final String? connectingAreaId;
  final MapEditMode mode;

  const MapPainterInteractive({
    required this.areas,
    required this.dangerAreaIds,
    required this.selectedAreaId,
    required this.connectingAreaId,
    required this.mode,
  });

  Color _colorForType(String type, bool isDanger) {
    if (isDanger) return const Color(0xFFFF4444);
    switch (type) {
      case AppConstants.typeExit:   return const Color(0xFF00FFFF);
      case AppConstants.typeStair:  return const Color(0xFFFFAA00);
      case AppConstants.typeHall:   return const Color(0xFF0088FF);
      case AppConstants.typeDanger: return const Color(0xFFFF4444);
      default:                      return const Color(0xFF00FF88);
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    // Grid
    final gridP = Paint()
      ..color = const Color(0xFF003322)
      ..strokeWidth = 0.5;
    for (double x = 0; x < size.width; x += 40) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridP);
    }
    for (double y = 0; y < size.height; y += 40) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridP);
    }

    // Grid coordinate labels (every 4 cells = 0.2 units)
    for (int xi = 0; xi <= 5; xi++) {
      for (int yi = 0; yi <= 5; yi++) {
        final xv = xi * 0.2;
        final yv = yi * 0.2;
        final tp = TextPainter(
          text: TextSpan(
            text: '${xv.toStringAsFixed(1)},${yv.toStringAsFixed(1)}',
            style: const TextStyle(
                color: Color(0xFF224422), fontSize: 8, fontFamily: 'monospace'),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        tp.paint(canvas,
            Offset(xv * size.width + 2, yv * size.height + 2));
      }
    }

    // Edges
    final edgeP = Paint()
      ..color = const Color(0xFF226622)
      ..strokeWidth = 2;
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
          edgeP,
        );
      }
    }

    // Nodes
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
            r + 6,
            Paint()
              ..color = const Color(0xFF00FF88)
              ..style = PaintingStyle.stroke
              ..strokeWidth = 2.5);
      }

      // Connecting ring (first node in connect mode)
      if (isConnecting) {
        canvas.drawCircle(
            center,
            r + 6,
            Paint()
              ..color = const Color(0xFFFFAA00)
              ..style = PaintingStyle.stroke
              ..strokeWidth = 2.5);
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

      // Node label below
      final display =
          area.name.length > 7 ? '${area.name.substring(0, 6)}…' : area.name;
      final tp = TextPainter(
        text: TextSpan(
          text: display,
          style: TextStyle(
            color: isSelected
                ? const Color(0xFF00FF88)
                : const Color(0xFFCCFFCC),
            fontSize: 9,
            fontFamily: 'monospace',
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: 80);
      tp.paint(canvas, center.translate(-tp.width / 2, r + 4));

      // Coordinate label inside node
      final coordTp = TextPainter(
        text: TextSpan(
          text:
              '${area.x.toStringAsFixed(2)},${area.y.toStringAsFixed(2)}',
          style: const TextStyle(
              color: Colors.white54, fontSize: 7, fontFamily: 'monospace'),
        ),
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: 60);
      coordTp.paint(
          canvas, center.translate(-coordTp.width / 2, -coordTp.height / 2));
    }
  }

  @override
  bool shouldRepaint(covariant MapPainterInteractive old) =>
      old.areas != areas ||
      old.dangerAreaIds != dangerAreaIds ||
      old.selectedAreaId != selectedAreaId ||
      old.connectingAreaId != connectingAreaId;
}