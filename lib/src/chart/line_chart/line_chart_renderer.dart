import 'package:fl_chart/fl_chart.dart';
import 'package:fl_chart/src/chart/base/base_chart/base_chart_painter.dart';
import 'package:fl_chart/src/chart/base/base_chart/render_base_chart.dart';
import 'package:fl_chart/src/chart/line_chart/line_chart_painter.dart';
import 'package:fl_chart/src/utils/canvas_wrapper.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

// coverage:ignore-start

/// Low level LineChart Widget.
class LineChartLeaf extends LeafRenderObjectWidget {
  const LineChartLeaf({
    super.key,
    required this.data,
    required this.targetData,
    this.useCustomTooltip = false,
  });

  final LineChartData data;
  final LineChartData targetData;
  final bool useCustomTooltip;

  @override
  RenderLineChart createRenderObject(BuildContext context) => RenderLineChart(
        context,
        data,
        targetData,
        MediaQuery.of(context).textScaleFactor,
        useCustomTooltip,
      );

  @override
  void updateRenderObject(BuildContext context, RenderLineChart renderObject) {
    renderObject
      ..data = data
      ..targetData = targetData
      ..textScale = MediaQuery.of(context).textScaleFactor
      ..buildContext = context
      ..useCustomTooltip = useCustomTooltip;
  }
}
// coverage:ignore-end

/// Renders our LineChart, also handles hitTest.
class RenderLineChart extends RenderBaseChart<LineTouchResponse> {
  RenderLineChart(
    BuildContext context,
    LineChartData data,
    LineChartData targetData,
    double textScale,
    bool useCustomTooltip,
  )   : _data = data,
        _targetData = targetData,
        _textScale = textScale,
        _useCustomTooltip = useCustomTooltip,
        super(
          targetData.lineTouchData,
          context,
        );

  bool _useCustomTooltip;
  bool get useCustomTooltip => _useCustomTooltip;
  set useCustomTooltip(bool value) {
    if (_useCustomTooltip == value) return;
    _useCustomTooltip = value;
    markNeedsPaint();
  }

  LineChartData get data => _data;
  LineChartData _data;
  set data(LineChartData value) {
    if (_data == value) return;
    _data = value;
    markNeedsPaint();
  }

  LineChartData get targetData => _targetData;
  LineChartData _targetData;
  set targetData(LineChartData value) {
    if (_targetData == value) return;
    _targetData = value;
    super.updateBaseTouchData(_targetData.lineTouchData);
    markNeedsPaint();
  }

  double get textScale => _textScale;
  double _textScale;
  set textScale(double value) {
    if (_textScale == value) return;
    _textScale = value;
    markNeedsPaint();
  }

  // We couldn't mock [size] property of this class, that's why we have this
  @visibleForTesting
  Size? mockTestSize;

  @visibleForTesting
  late LineChartPainter painter;

  PaintHolder<LineChartData> get paintHolder {
    return PaintHolder(data, targetData, textScale);
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    final canvas = context.canvas
      ..save()
      ..translate(offset.dx, offset.dy);
    painter = LineChartPainter(useCustomTooltip: useCustomTooltip);
    painter.paint(
      buildContext,
      CanvasWrapper(canvas, mockTestSize ?? size),
      paintHolder,
    );
    canvas.restore();
  }

  @override
  LineTouchResponse getResponseAtLocation(Offset localPosition) {
    final touchedSpots = painter.handleTouch(
      localPosition,
      mockTestSize ?? size,
      paintHolder,
    );
    return LineTouchResponse(touchedSpots);
  }
}
