import 'package:fl_chart/fl_chart.dart';
import 'package:fl_chart/src/chart/bar_chart/bar_chart_helper.dart';
import 'package:fl_chart/src/chart/bar_chart/bar_chart_painter.dart';
import 'package:fl_chart/src/chart/bar_chart/bar_chart_renderer.dart';
import 'package:fl_chart/src/chart/base/axis_chart/axis_chart_scaffold_widget.dart';
import 'package:flutter/cupertino.dart';

/// Renders a bar chart as a widget, using provided [BarChartData].
class BarChart extends ImplicitlyAnimatedWidget {
  /// [data] determines how the [BarChart] should be look like,
  /// when you make any change in the [BarChartData], it updates
  /// new values with animation, and duration is [swapAnimationDuration].
  /// also you can change the [swapAnimationCurve]
  /// which default is [Curves.linear].
  const BarChart(
    this.data, {
    this.chartRendererKey,
    super.key,
    Duration swapAnimationDuration = const Duration(milliseconds: 150),
    Curve swapAnimationCurve = Curves.linear,
    this.customTooltip,
  }) : super(
          duration: swapAnimationDuration,
          curve: swapAnimationCurve,
        );

  /// Determines how the [BarChart] should be look like.
  final BarChartData data;

  /// We pass this key to our renderers which are supposed to
  /// render the chart itself (without anything around the chart).
  final Key? chartRendererKey;

  // The final variable customTooltips is a nullable function that defines custom tooltips for BarChart widgets based on provided BarChartGroupData data.
  // It accepts a List of BarChartGroupData objects (or null) as input and returns a Widget.
  final Widget Function(BarTooltip? barTooltip)? customTooltip;

  /// Creates a [_BarChartState]
  @override
  _BarChartState createState() => _BarChartState();
}

class _BarChartState extends AnimatedWidgetBaseState<BarChart> {
  /// we handle under the hood animations (implicit animations) via this tween,
  /// it lerps between the old [BarChartData] to the new one.
  BarChartDataTween? _barChartDataTween;

  /// If [BarTouchData.handleBuiltInTouches] is true, we override the callback to handle touches internally,
  /// but we need to keep the provided callback to notify it too.
  BaseTouchCallback<BarTouchResponse>? _providedTouchCallback;

  final Map<int, List<int>> _showingTouchedTooltips = {};

  final _barChartHelper = BarChartHelper();
  BarTooltip? _barTooltip;

  @override
  Widget build(BuildContext context) {
    final showingData = _getData();

    return AxisChartScaffoldWidget(
      chart: BarChartLeaf(
        data: _withTouchedIndicators(_barChartDataTween!.evaluate(animation)),
        targetData: _withTouchedIndicators(showingData),
        key: widget.chartRendererKey,
        useCustomTooltip: widget.customTooltip != null,
        barTooltip: (barTooltip) {
          _barTooltip = barTooltip;
        },
      ),
      data: showingData,
      barChartData: _withTouchedIndicators(showingData),
      barChartCustomTooltip: widget.customTooltip,
      barTooltip: _barTooltip,
    );
  }

  BarChartData _withTouchedIndicators(BarChartData barChartData) {
    if (!barChartData.barTouchData.enabled ||
        !barChartData.barTouchData.handleBuiltInTouches) {
      return widget.data;
    }

    final newGroups = <BarChartGroupData>[];
    for (var i = 0; i < barChartData.barGroups.length; i++) {
      final group = barChartData.barGroups[i];

      newGroups.add(
        group.copyWith(
          showingTooltipIndicators: _showingTouchedTooltips[i],
        ),
      );
    }

    return barChartData.copyWith(
      barGroups: newGroups,
      lineBarChartData: widget.data.lineBarChartData,
    );
  }

  BarChartData _getData() {
    var newData = widget.data;
    if (newData.minY.isNaN || newData.maxY.isNaN) {
      final values = BarChartHelper.calculateMaxAxisValues(newData.barGroups);
      newData = newData.copyWith(
        minY: newData.minY.isNaN ? values.minY : newData.minY,
        maxY: newData.maxY.isNaN ? values.maxY : newData.maxY,
      );
    }

    final barTouchData = newData.barTouchData;
    if (barTouchData.enabled && barTouchData.handleBuiltInTouches) {
      _providedTouchCallback = barTouchData.touchCallback;
      return newData.copyWith(
        barTouchData:
            newData.barTouchData.copyWith(touchCallback: _handleBuiltInTouch),
        lineBarChartData: widget.data.lineBarChartData,
      );
    }
    return newData;
  }

  void _handleBuiltInTouch(
    FlTouchEvent event,
    BarTouchResponse? touchResponse,
  ) {
    if (!mounted) {
      return;
    }
    _providedTouchCallback?.call(event, touchResponse);

    if (!event.isInterestedForInteractions ||
        touchResponse == null ||
        touchResponse.spot == null) {
      setState(_showingTouchedTooltips.clear);
      return;
    }
    setState(() {
      final spot = touchResponse.spot!;
      final groupIndex = spot.touchedBarGroupIndex;
      final rodIndex = spot.touchedRodDataIndex;

      _showingTouchedTooltips.clear();
      _showingTouchedTooltips[groupIndex] = [rodIndex];
    });
  }

  @override
  void forEachTween(TweenVisitor<dynamic> visitor) {
    _barChartDataTween = visitor(
      _barChartDataTween,
      _getData(),
      (dynamic value) =>
          BarChartDataTween(begin: value as BarChartData, end: widget.data),
    ) as BarChartDataTween?;
  }
}
