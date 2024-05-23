import 'dart:math';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:prescore_flutter/model/paper_model.dart';
import 'package:prescore_flutter/util/struct.dart';
import 'package:provider/provider.dart';

class PaperDistribution extends StatefulWidget {
  final String examId;
  final String paperId;
  const PaperDistribution(
      {Key? key, required this.paperId, required this.examId})
      : super(key: key);

  @override
  State<PaperDistribution> createState() => _PaperDistributionState();
}

class _PaperDistributionState extends State<PaperDistribution>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  Future? future;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    future ??= Provider.of<PaperModel>(context, listen: false)
        .user
        .fetchPaperDistribution(paperId: widget.paperId);
    return FutureBuilder(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          List<FlSpot> prefixSpots = [];
          List<FlSpot> suffixSpots = [];
          DistributionData distributionData = snapshot.data.result;
          for (var element in distributionData.prefix.removeFrontZero()) {
            prefixSpots.add(FlSpot(element.score, element.sum / distributionData.prefix.getMaxSum()));
          }
          for (var element in distributionData.suffix.removeEndMax()) {
            suffixSpots.add(FlSpot(element.score, element.sum / distributionData.prefix.getMaxSum()));
          }
          return ListView(children: [
            Center(child: Text("(双击反转趋势，竖滑变更分段，长按查看标签)", style: Theme.of(context).textTheme.labelSmall?.copyWith(color: Colors.grey))),
            Card.filled(
                margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                child: Container(
                    padding: const EdgeInsets.all(12.0),
                    child: TrendChart(prefixSpots: prefixSpots, suffixSpots: suffixSpots))),
            Card.filled(
                margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                child: Container(
                    padding: const EdgeInsets.all(12.0),
                    child: Histogram(distribute: distributionData.distribute.removeFrontZero(), step: 5))),
          ]);
        } else {
          return Center(
              child: Container(
                  margin: const EdgeInsets.all(10),
                  child: const CircularProgressIndicator()));
        }
      },
    );
  }
}

class TrendChart extends StatefulWidget {
  final List<FlSpot> prefixSpots;
  final List<FlSpot> suffixSpots;

  const TrendChart({super.key, required this.prefixSpots, required this.suffixSpots});

  @override
  State<TrendChart> createState() => _TrendChartState();
}

class _TrendChartState extends State<TrendChart> {
  bool showPrefix = true;

  Widget getHorizontalTitles(value, TitleMeta meta) {
    value as double;
    if (value % 10 != 0 || value == 0) {
      return Container();
    }
    return Padding(
      padding: const EdgeInsets.all(4.0),
      child: Transform.rotate(
      angle: -pi / 4,
      child: Text(meta.formattedValue,
            style: const TextStyle(
              fontSize: 8,
            ))),
    );
  }

  Widget getVerticalTitles(value, TitleMeta meta) {
    value as double;
    return Padding(
      padding: const EdgeInsets.all(4.0),
      child: Transform.rotate(
        angle: -pi / 4,
        child: Text(meta.formattedValue,
            style: const TextStyle(
              fontSize: 8,
            )),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onDoubleTap: () => setState(() {
        showPrefix =!showPrefix;
        HapticFeedback.mediumImpact();
      }),
      child: AspectRatio(
        aspectRatio: 1.5,
        child: Container(
          margin: const EdgeInsets.only(right: 5),
          child: LineChart(
            LineChartData(
              lineBarsData: [
                LineChartBarData(
                  spots: showPrefix ? widget.prefixSpots : widget.suffixSpots,
                  isCurved: false,
                  dotData: const FlDotData(
                    show: false,
                  ),
                  color: Theme.of(context).colorScheme.primary,
                  belowBarData: BarAreaData(show: true,color: Theme.of(context).colorScheme.primary.withOpacity(0.1))
                ),
              ],
              titlesData: FlTitlesData(
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: getHorizontalTitles,
                      reservedSize: 22,
                      interval: 10
                      ),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: getVerticalTitles,
                    reservedSize: 26,
                  ),
                ),
                topTitles: AxisTitles(
                  axisNameWidget: Text("   预测分布趋势图", style: Theme.of(context).textTheme.labelSmall),
                  sideTitles: const SideTitles(showTitles: false),
                ),
                rightTitles: const AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: false,
                  ),
                ),
              ),
              lineTouchData: LineTouchData(
                touchTooltipData: LineTouchTooltipData(
                  tooltipMargin: 0,
                  tooltipBgColor: Colors.transparent,
                  getTooltipItems: (touchedSpots) => touchedSpots.map((spot) {
                    return LineTooltipItem("${spot.x.toInt()} 分\n${(spot.y * 100).toStringAsFixed(2)}%", const TextStyle(fontWeight: FontWeight.bold));
                  }).toList()
                ),
                getTouchedSpotIndicator: (LineChartBarData barData, List<int> spotIndexes) {
                  return spotIndexes.map((spotIndex) {
                    return TouchedSpotIndicatorData(
                      FlLine(
                        color: Theme.of(context).colorScheme.primary,
                        strokeWidth: 2,
                      ),
                      FlDotData(
                        show: true,
                        getDotPainter: (spot, percent, barData, index) {
                          return FlDotCirclePainter(
                            color: Theme.of(context).colorScheme.primary,
                            strokeWidth: 0,
                            radius: 5,
                          );
                        },
                      ),
                    );
                  }).toList();
                }
              )
            ),
            duration: const Duration(milliseconds: 200),
          ),
        ),
      ),
    );
  }
}

class Histogram extends StatefulWidget {
  final List<DistributionScoreItem> distribute;
  final int step;
  const Histogram({super.key, required this.distribute, required this.step});

  @override
  State<StatefulWidget> createState() => HistogramState();
}

class HistogramState extends State<Histogram> {
  late double step;

  @override
  void initState() {
    step = widget.step.toDouble();
    super.initState();
  }

  Widget bottomTitles(double value, TitleMeta meta) {
    const style = TextStyle(fontSize: 8);
    //String text = "[${value.toInt()}, ${value.toInt() + widget.step})";
    
    return SideTitleWidget(
      angle: -pi / 4,
      axisSide: meta.axisSide,
      child: Text(value.toInt().toString(), style: style),
    );
  }

  Widget leftTitles(double value, TitleMeta meta) {
    const style = TextStyle(
      fontSize: 8,
    );
    return SideTitleWidget(
      axisSide: meta.axisSide,
      angle: -pi / 4,
      child: Text(
        "${(value * 100).toStringAsFixed(0)}%",
        style: style,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onVerticalDragUpdate: (DragUpdateDetails details) {
        setState(() {
          double oldStep = step;
          step += details.delta.dy / 20;
          step = min(20, step);
          step = max(3, step);
          if (oldStep.toInt() != step.toInt()) {
            HapticFeedback.mediumImpact();
          }
        });
      },
      child: AspectRatio(
          aspectRatio: 1.5,
          child: Container(
            margin: const EdgeInsets.only(right: 5),
            child: LayoutBuilder(
              builder: (context, constraints) {
                const double barsSpace = 1;
                final barsWidth =  constraints.maxWidth / widget.distribute.withStep(step.toInt()).length * 0.8;
                return BarChart(
                  swapAnimationDuration: const Duration(milliseconds: 150),
                  swapAnimationCurve: Curves.easeOutCirc,
                  BarChartData(
                    alignment: BarChartAlignment.center,
                    barTouchData: BarTouchData(
                      enabled: true,
                      touchTooltipData: BarTouchTooltipData(
                    tooltipMargin: 0,
                    tooltipBgColor: Colors.transparent,
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      return BarTooltipItem(
                        "[${group.x}, ${group.x + step.toInt()})\n${(rod.toY * 100).toStringAsFixed(2)}%",
                        const TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      );
                    },
                  )
                    ),
                    titlesData: FlTitlesData(
                      show: true,
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 24,
                          getTitlesWidget: bottomTitles,
                        ),
                      ),
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 26,
                          getTitlesWidget: leftTitles,
                        ),
                      ),
                      topTitles: AxisTitles(
                        axisNameWidget: Text("   预测分布直方图 (${step.toInt()}分一段)", style: Theme.of(context).textTheme.labelSmall),
                        sideTitles: const SideTitles(showTitles: false),
                      ),
                      rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                    ),
                    gridData: const FlGridData(
                      show: true,
                      //checkToShowHorizontalLine: (value) => value % 10 == 0,
                      drawVerticalLine: false,
                    ),
                    groupsSpace: barsSpace,
                    barGroups: getData(barsWidth, barsSpace),
                  ),
                );
              },
            ),
          ),
        ),
    );
  }

  List<BarChartGroupData> getData(double barsWidth, double barsSpace) {
    return widget.distribute.withStep(step.toInt()).map((e) => BarChartGroupData(
        x: e.score.toInt(),
        barsSpace: barsSpace,
        barRods: [
          BarChartRodData(
            color: Theme.of(context).colorScheme.primary,
            toY: e.sum.toDouble() / widget.distribute.withStep(step.toInt()).getTotalSum(),
            borderRadius: BorderRadius.zero,
            width: barsWidth,
          ),
        ],
      )).toList();
  }
}