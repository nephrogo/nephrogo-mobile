import 'package:flutter/material.dart';
import 'package:nephrolog/models/contract.dart';
import 'package:nephrolog/services/api_service.dart';
import 'package:nephrolog/ui/charts/health_indicator_bar_chart.dart';
import 'package:nephrolog/ui/general/app_future_builder.dart';
import 'package:nephrolog/ui/general/weekly_pager.dart';
import 'package:nephrolog/extensions/contract_extensions.dart';
import 'package:flutter/cupertino.dart';
import 'package:intl/intl.dart';
import 'package:nephrolog/ui/general/components.dart';
import 'package:nephrolog/extensions/string_extensions.dart';

class WeeklyHealthIndicatorsScreenArguments {
  final HealthIndicator initialHealthIndicator;

  const WeeklyHealthIndicatorsScreenArguments(this.initialHealthIndicator);
}

class WeeklyHealthIndicatorsScreen extends StatefulWidget {
  final HealthIndicator initialHealthIndicator;

  const WeeklyHealthIndicatorsScreen({Key key, this.initialHealthIndicator})
      : super(key: key);

  @override
  _WeeklyHealthIndicatorsScreenState createState() =>
      _WeeklyHealthIndicatorsScreenState();
}

class _WeeklyHealthIndicatorsScreenState
    extends State<WeeklyHealthIndicatorsScreen> {
  ValueNotifier<HealthIndicator> healthIndicatorChangeNotifier;
  HealthIndicator selectedHealthIndicator;

  final ApiService _apiService = ApiService();

  @override
  void initState() {
    super.initState();

    healthIndicatorChangeNotifier =
        ValueNotifier(widget.initialHealthIndicator);
    selectedHealthIndicator = widget.initialHealthIndicator;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(selectedHealthIndicator.name),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showIndicatorSelectionPopupMenu(),
        label: Text("RODIKLIS"),
        icon: Icon(Icons.swap_horizontal_circle),
      ),
      body: WeeklyPager<HealthIndicator>(
        valueChangeNotifier: healthIndicatorChangeNotifier,
        bodyBuilder: (from, to, indicator) {
          return AppFutureBuilder<UserHealthStatusResponse>(
            future: _apiService.getUserHealthStatus(from, to),
            builder: (context, data) {
              return HealthIndicatorsListWithChart(
                dailyHealthStatuses: data.dailyHealthStatuses,
                healthIndicator: selectedHealthIndicator,
              );
            },
          );
        },
      ),
    );
  }

  _changeHealthIndicator(HealthIndicator healthIndicator) {
    setState(() {
      selectedHealthIndicator = healthIndicator;
      healthIndicatorChangeNotifier.value = healthIndicator;
    });
  }

  Future _showIndicatorSelectionPopupMenu() async {
    final options = HealthIndicator.values.map((hi) {
      return SimpleDialogOption(
        child: Text(hi.name),
        onPressed: () => Navigator.pop(context, hi),
        padding: EdgeInsets.symmetric(vertical: 16, horizontal: 24),
      );
    }).toList();

    final selectedHealthIndicator = await showDialog<HealthIndicator>(
      context: context,
      builder: (BuildContext context) {
        return SimpleDialog(
          title: const Text('Pasirinkite sveikatos indikatorių'),
          children: options,
        );
      },
    );

    if (selectedHealthIndicator != null) {
      _changeHealthIndicator(selectedHealthIndicator);
    }
  }
}

class HealthIndicatorsListWithChart extends StatelessWidget {
  final HealthIndicator healthIndicator;
  final List<DailyHealthStatus> dailyHealthStatuses;

  const HealthIndicatorsListWithChart({
    Key key,
    @required this.dailyHealthStatuses,
    @required this.healthIndicator,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.only(bottom: 64),
      children: [
        BasicSection(
          children: [
            HealthIndicatorBarChart(
              dailyHealthStatuses: dailyHealthStatuses,
              indicator: healthIndicator,
            ),
          ],
        ),
        BasicSection(children: _buildIndicatorTiles()),
      ],
    );
  }

  List<Widget> _buildIndicatorTiles() {
    return dailyHealthStatuses
        .where((dhs) => dhs.getHealthIndicatorValue(healthIndicator) != null)
        .map((dhs) => DailyHealthStatusIndicatorTile(
              dailyHealthStatus: dhs,
              indicator: healthIndicator,
            ))
        .toList();
  }
}

class DailyHealthStatusIndicatorTile extends StatelessWidget {
  static final _dateFormat = DateFormat("EEEE, MMMM d");

  final DailyHealthStatus dailyHealthStatus;
  final HealthIndicator indicator;

  const DailyHealthStatusIndicatorTile({
    Key key,
    @required this.dailyHealthStatus,
    @required this.indicator,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final dateTitle =
        _dateFormat.format(dailyHealthStatus.date).capitalizeFirst();

    return AppListTile(
      title: Text(dateTitle),
      trailing: Text(dailyHealthStatus.getHealthIndicatorFormatted(indicator)),
    );
  }
}