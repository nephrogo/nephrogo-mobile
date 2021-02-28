import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:nephrogo/api/api_service.dart';
import 'package:nephrogo/constants.dart';
import 'package:nephrogo/extensions/extensions.dart';
import 'package:nephrogo/models/date.dart';
import 'package:nephrogo/routes.dart';
import 'package:nephrogo/ui/charts/manual_peritoneal_dialysis_day_balance_chart.dart';
import 'package:nephrogo/ui/charts/manual_peritoneal_dialysis_total_balance_chart.dart';
import 'package:nephrogo/ui/general/app_steam_builder.dart';
import 'package:nephrogo/ui/general/components.dart';
import 'package:nephrogo/ui/general/dialogs.dart';
import 'package:nephrogo/ui/general/period_pager.dart';
import 'package:nephrogo/ui/general/progress_dialog.dart';
import 'package:nephrogo/ui/tabs/manual_peritoneal_dialysis/manual_peritoneal_dialysis_creation_screen.dart';
import 'package:nephrogo/ui/tabs/nutrition/summary/nutrition_summary_components.dart';
import 'package:nephrogo_api_client/model/daily_manual_peritoneal_dialysis_report.dart';
import 'package:nephrogo_api_client/model/daily_manual_peritoneal_dialysis_report_response.dart';
import 'package:nephrogo_api_client/model/manual_peritoneal_dialysis.dart';

import 'excel/manual_peritoneal_dialysis_excel_generator.dart';

class ManualPeritonealDialysisBalanceScreen extends StatelessWidget {
  final _apiService = ApiService();

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      initialIndex: 1,
      child: Scaffold(
        appBar: AppBar(
          title: Text(context.appLocalizations.balance),
          bottom: TabBar(
            tabs: [
              Tab(text: context.appLocalizations.daily.toUpperCase()),
              Tab(text: context.appLocalizations.weekly.toUpperCase()),
              Tab(text: context.appLocalizations.monthly.toUpperCase()),
            ],
          ),
        ),
        floatingActionButton: SpeedDialFloatingActionButton(
          onPress: () => _downloadAndExportDialysis(context),
          label: context.appLocalizations.summary.toUpperCase(),
          icon: Icons.download_rounded,
        ),
        body: TabBarView(
          physics: const NeverScrollableScrollPhysics(),
          children: [
            _ManualPeritonealDialysisDialysisBalanceList(
              pagerType: PeriodPagerType.daily,
            ),
            _ManualPeritonealDialysisDialysisBalanceList(
              pagerType: PeriodPagerType.weekly,
            ),
            _ManualPeritonealDialysisDialysisBalanceList(
              pagerType: PeriodPagerType.monthly,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _downloadAndExportDialysisInternal(BuildContext context) async {
    final response =
        await _apiService.getManualPeritonealDialysisReportsPaginated();

    return ManualPeritonealDialysisExcelGenerator.generateAndOpenExcel(
      context,
      context.appLocalizations,
      response.results,
    );
  }

  Future<void> _downloadAndExportDialysis(BuildContext context) {
    final future = _downloadAndExportDialysisInternal(context).catchError(
      (e, stackTrace) async {
        FirebaseCrashlytics.instance.recordError(e, stackTrace as StackTrace);

        await showAppDialog(
          context: context,
          title: context.appLocalizations.error,
          message: context.appLocalizations.serverErrorDescription,
        );
      },
    );

    return ProgressDialog(context).showForFuture(future);
  }
}

class _ManualPeritonealDialysisDialysisBalanceList extends StatelessWidget {
  final ApiService _apiService = ApiService();
  final PeriodPagerType pagerType;

  _ManualPeritonealDialysisDialysisBalanceList(
      {Key key, @required this.pagerType})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return PeriodPager(
      pagerType: pagerType,
      initialDate: Date.today(),
      earliestDate: Constants.earliestDate,
      bodyBuilder: _bodyBuilder,
    );
  }

  Widget _bodyBuilder(BuildContext context, Widget header, Date from, Date to) {
    return AppStreamBuilder<DailyManualPeritonealDialysisReportResponse>(
      stream: _apiService.getManualPeritonealDialysisReportsStream(from, to),
      builder: (context, data) {
        final reports = data.manualPeritonealDialysisReports;

        final sortedReports =
            reports.sortedBy((e) => e.date, reverse: true).toList();

        if (sortedReports.isEmpty) {
          return DateSwitcherHeaderSection(
            header: header,
            children: [
              EmptyStateContainer(
                text: context
                    .appLocalizations.manualPeritonealDialysisPeriodEmpty,
              )
            ],
          );
        }

        return ListView.builder(
          itemBuilder: (context, index) {
            if (index == 0) {
              return DateSwitcherHeaderSection(
                header: header,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: _getGraph(sortedReports, from, to),
                  ),
                ],
              );
            } else {
              return ManualPeritonealDialysisReportSection(
                report: sortedReports[index - 1],
              );
            }
          },
          itemCount: sortedReports.length + 1,
        );
      },
    );
  }

  Widget _getGraph(
    Iterable<DailyManualPeritonealDialysisReport> reports,
    Date from,
    Date to,
  ) {
    if (pagerType == PeriodPagerType.daily) {
      final dialysis = reports
          .expand((e) => e.manualPeritonealDialysis)
          .sortedBy((e) => e.startedAt, reverse: true)
          .toList();

      return ManualPeritonealDialysisDayBalanceChart(
        manualPeritonealDialysis: dialysis,
        date: from,
      );
    }

    return ManualPeritonealDialysisTotalBalanceChart(
      reports: reports.toList(),
      minimumDate: from,
      maximumDate: to,
    );
  }
}

class ManualPeritonealDialysisReportSection extends StatelessWidget {
  final _dateFormat = DateFormat.MMMMd();

  final DailyManualPeritonealDialysisReport report;

  ManualPeritonealDialysisReportSection({
    Key key,
    @required this.report,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final sortedDialysis = report.manualPeritonealDialysis
        .sortedBy((d) => d.startedAt, reverse: true);

    return LargeSection(
      title: Text(_dateFormat.format(report.date).capitalizeFirst()),
      subtitle: Text(
        '${context.appLocalizations.dailyBalance}: ${report.formattedTotalBalance}',
      ),
      showDividers: true,
      children: [
        for (final dialysis in sortedDialysis)
          ManualPeritonealDialysisTile(dialysis)
      ],
    );
  }
}

class ManualPeritonealDialysisTile extends StatelessWidget {
  final ManualPeritonealDialysis dialysis;
  final _dateFormat = DateFormat.MMMMd().add_Hm();

  ManualPeritonealDialysisTile(this.dialysis)
      : assert(dialysis != null),
        super(key: ObjectKey(dialysis));

  @override
  Widget build(BuildContext context) {
    return AppListTile(
      leading: CircleAvatar(backgroundColor: dialysis.dialysisSolution.color),
      title: Text(
          _dateFormat.format(dialysis.startedAt.toLocal()).capitalizeFirst()),
      subtitle: Row(
        children: [
          if (dialysis.solutionOutMl != null)
            const Padding(
              padding: EdgeInsets.only(right: 4),
              child: Icon(Icons.outbond_outlined, size: 14),
            ),
          if (dialysis.solutionOutMl != null)
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: Text(dialysis.formattedSolutionOut),
            ),
          const Padding(
            padding: EdgeInsets.only(right: 4),
            child: Icon(Icons.next_plan_outlined, size: 14),
          ),
          Text(dialysis.formattedSolutionIn),
        ],
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4.0),
            child: Text(dialysis.formattedBalance),
          ),
          const Icon(Icons.chevron_right),
        ],
      ),
      onTap: () => Navigator.of(context).pushNamed(
        Routes.routeManualPeritonealDialysisCreation,
        arguments: ManualPeritonealDialysisCreationScreenArguments(dialysis),
      ),
    );
  }
}
