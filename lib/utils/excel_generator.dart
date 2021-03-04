import 'dart:io';

import 'package:flutter/material.dart';
import 'package:nephrogo/extensions/extensions.dart';
import 'package:nephrogo/l10n/localizations.dart';
import 'package:nephrogo/models/contract.dart';
import 'package:nephrogo_api_client/model/daily_health_status.dart';
import 'package:nephrogo_api_client/model/daily_intakes_light_report.dart';
import 'package:nephrogo_api_client/model/dialysate_color_enum.dart';
import 'package:nephrogo_api_client/model/dialysis_solution_enum.dart';
import 'package:nephrogo_api_client/model/manual_peritoneal_dialysis.dart';
import 'package:path_provider/path_provider.dart';
import 'package:syncfusion_flutter_xlsio/xlsio.dart';

class ExcelGeneratorSheet {
  Worksheet sheet;

  int row = 1;
  int column = 1;

  ExcelGeneratorSheet(Workbook workbook, String name) {
    sheet = workbook.worksheets.addWithName(name);
  }

  Range get _currentRange => sheet.getRangeByIndex(row, column);

  void _advanceRow([int advance = 1]) {
    row += advance;
  }

  void _nextCol() {
    column += 1;
    row = 1;
  }

  void _writeHeader(String header, double columnWidth) {
    if (column != 1 || row != 1) {
      _nextCol();
    }

    _currentRange
      ..setText(header)
      ..columnWidth = columnWidth
      ..cellStyle.bold = true;

    _advanceRow();
  }

  void writeMergedColumn<T>({
    @required String header,
    @required double columnWidth,
    @required Iterable<T> items,
    @required int Function(Range range, T item) writer,
  }) {
    _writeHeader(header, columnWidth);

    for (final item in items) {
      final advance = writer(_currentRange, item);

      assert(advance > 0, 'Invalid advance returned');

      sheet.getRangeByIndex(row, column, row + advance - 1).merge();

      _advanceRow(advance);
    }
  }

  void writeColumn<T>({
    @required String header,
    @required double columnWidth,
    @required Iterable<T> items,
    @required void Function(Range range, T item) writer,
  }) {
    return writeMergedColumn<T>(
      header: header,
      columnWidth: columnWidth,
      items: items,
      writer: (range, item) {
        writer(range, item);

        return 1;
      },
    );
  }

  void applyGlobalStyle() {
    sheet.getRangeByIndex(1, 1, row, column).cellStyle
      ..hAlign = HAlignType.center
      ..vAlign = VAlignType.center
      ..wrapText = true;
  }
}

class ExcelReportBuilder {
  final BuildContext context;
  final Workbook _workbook;

  ExcelReportBuilder({@required this.context}) : _workbook = Workbook(0);

  AppLocalizations get _appLocalizations => context.appLocalizations;

  Future<File> buildFile(String fileName) async {
    final directory = await getApplicationDocumentsDirectory();
    final fullPath = '${directory.path}/$fileName';

    final bytes = _workbook.saveAsStream();
    final file = File(fullPath)..writeAsBytes(bytes, flush: true);

    _workbook.dispose();

    return file;
  }

  ExcelGeneratorSheet appendManualDialysisSheet({
    @required Iterable<DailyHealthStatus> dailyHealthStatuses,
    @required Iterable<DailyIntakesLightReport> lightDailyIntakeReports,
  }) {
    final sortedReports = dailyHealthStatuses
        .where((s) => s.manualPeritonealDialysis.isNotEmpty)
        .sortedBy((r) => r.date, reverse: true)
        .toList();

    final sheet = ExcelGeneratorSheet(
      _workbook,
      _appLocalizations.peritonealDialysisPlural,
    );

    final liquidsMap =
        lightDailyIntakeReports.groupBy((r) => r.date.toDate()).map(
              (d, r) => MapEntry(
                d,
                r.first.nutrientNormsAndTotals.liquidsMl.total,
              ),
            );

    sheet.writeMergedColumn<DailyHealthStatus>(
      header: _appLocalizations.date,
      columnWidth: 25,
      items: sortedReports,
      writer: (range, status) {
        range.setText(status.date.toString());

        return status.manualPeritonealDialysis.length;
      },
    );
    sheet.writeMergedColumn<DailyHealthStatus>(
      header: '${_appLocalizations.dailyBalance}, ml',
      columnWidth: 20,
      items: sortedReports,
      writer: (range, status) {
        range.setNumber(
          status.totalManualPeritonealDialysisBalance.roundToDouble(),
        );

        return status.manualPeritonealDialysis.length;
      },
    );

    sheet.writeColumn<ManualPeritonealDialysis>(
      header: _appLocalizations.dialysisStart,
      columnWidth: 20,
      items: sortedReports.expand(
        (r) => r.manualPeritonealDialysisReverseSorted,
      ),
      writer: (range, dialysis) {
        range.setText(
          dialysis.startedAt.timeOfDayLocal.format(context),
        );
      },
    );

    sheet.writeColumn<DialysisSolutionEnum>(
      header: _appLocalizations.dialysisSolution,
      columnWidth: 20,
      items: sortedReports.expand(
        (r) => r.manualPeritonealDialysisReverseSorted
            .map((d) => d.dialysisSolution),
      ),
      writer: (range, solution) {
        range.setText(solution.localizedName(_appLocalizations));

        range.cellStyle
          ..backColor = solution.color.toHexTriplet()
          ..fontColor = solution.textColor.toHexTriplet();
      },
    );

    sheet.writeColumn<ManualPeritonealDialysis>(
      header: _appLocalizations.balance,
      columnWidth: 20,
      items: sortedReports.expand(
        (r) => r.manualPeritonealDialysisReverseSorted,
      ),
      writer: (range, dialysis) {
        range.setNumber(dialysis.balance.roundToDouble());
      },
    );

    sheet.writeColumn<ManualPeritonealDialysis>(
      header: '${_appLocalizations.dialysisSolutionOut}, ml',
      columnWidth: 20,
      items: sortedReports.expand(
        (r) => r.manualPeritonealDialysisReverseSorted,
      ),
      writer: (range, dialysis) {
        if (dialysis.solutionOutMl != null) {
          range.setNumber(dialysis.solutionOutMl.roundToDouble());
        }
      },
    );

    sheet.writeColumn<ManualPeritonealDialysis>(
      header: '${_appLocalizations.dialysisSolutionIn}, ml',
      columnWidth: 20,
      items: sortedReports.expand(
        (r) => r.manualPeritonealDialysisReverseSorted,
      ),
      writer: (range, dialysis) {
        range.setNumber(dialysis.solutionInMl.roundToDouble());
      },
    );

    sheet.writeColumn<DialysateColorEnum>(
      header: _appLocalizations.dialysateColor,
      columnWidth: 20,
      items: sortedReports.expand(
        (r) => r.manualPeritonealDialysisReverseSorted.map(
          (d) => d.dialysateColor,
        ),
      ),
      writer: (range, dialysateColor) {
        if (dialysateColor != DialysateColorEnum.unknown) {
          range.setText(dialysateColor.localizedName(_appLocalizations));

          if (dialysateColor.color != Colors.transparent) {
            range.cellStyle
              ..backColor = dialysateColor.color.toHexTriplet()
              ..fontColor = dialysateColor.textColor.toHexTriplet()
              ..wrapText = true;
          }
        }
      },
    );

    sheet.writeColumn<ManualPeritonealDialysis>(
      header: _appLocalizations.notes,
      columnWidth: 20,
      items: sortedReports.expand(
        (r) => r.manualPeritonealDialysisReverseSorted,
      ),
      writer: (range, dialysis) {
        range
          ..setText(dialysis.notes)
          ..cellStyle.wrapText = true;
      },
    );

    sheet.writeColumn<ManualPeritonealDialysis>(
      header: _appLocalizations.dialysisEnd,
      columnWidth: 20,
      items: sortedReports.expand(
        (r) => r.manualPeritonealDialysisReverseSorted,
      ),
      writer: (range, dialysis) {
        if (dialysis.finishedAt != null) {
          final time = dialysis.finishedAt.timeOfDayLocal.format(context);

          range.setText(time);
        }
      },
    );

    sheet.writeMergedColumn<DailyHealthStatus>(
      header: '${_appLocalizations.liquids}, ml',
      columnWidth: 20,
      items: sortedReports,
      writer: (range, status) {
        final date = status.date.toDate();

        if (liquidsMap.containsKey(date)) {
          range.setNumber(liquidsMap[date].roundToDouble());
        }

        return status.manualPeritonealDialysis.length;
      },
    );
    sheet.writeMergedColumn<DailyHealthStatus>(
      header: '${_appLocalizations.healthStatusCreationUrine}, '
          '${HealthIndicator.urine.dimension(_appLocalizations)}',
      columnWidth: 20,
      items: sortedReports,
      writer: (range, status) {
        if (status.urineMl != null) {
          range.setNumber(status.urineMl.roundToDouble());
        }

        return status.manualPeritonealDialysis.length;
      },
    );

    sheet.writeMergedColumn<DailyHealthStatus>(
      header: '${_appLocalizations.weight}, '
          '${HealthIndicator.weight.dimension(_appLocalizations)}',
      columnWidth: 20,
      items: sortedReports,
      writer: (range, status) {
        if (status.weightKg != null) {
          range.setNumber(status.weightKg);
        }

        return status.manualPeritonealDialysis.length;
      },
    );

    sheet.writeMergedColumn<DailyHealthStatus>(
      header: '${_appLocalizations.healthStatusCreationBloodPressure}, '
          '${HealthIndicator.bloodPressure.dimension(_appLocalizations)}',
      columnWidth: 20,
      items: sortedReports,
      writer: (range, status) {
        final text = status.bloodPressures
            .sortedBy((e) => e.measuredAt, reverse: true)
            .map((d) => d.formatAmountWithoutDimensionWithTime(context))
            .join('\n');

        range
          ..setText(text)
          ..columnWidth = 40;

        return status.manualPeritonealDialysis.length;
      },
    );

    sheet.writeMergedColumn<DailyHealthStatus>(
      header: '${_appLocalizations.pulse}, '
          '${HealthIndicator.pulse.dimension(_appLocalizations)}',
      columnWidth: 20,
      items: sortedReports,
      writer: (range, status) {
        final text = status.pulses
            .sortedBy((e) => e.measuredAt, reverse: true)
            .map((d) => d.formatAmountWithoutDimensionWithTime(context))
            .join('\n');

        range
          ..setText(text)
          ..columnWidth = 40;

        return status.manualPeritonealDialysis.length;
      },
    );

    return sheet..applyGlobalStyle();
  }
}
