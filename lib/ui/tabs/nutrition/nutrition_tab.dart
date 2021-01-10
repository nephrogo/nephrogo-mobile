import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:nephrolog/extensions/extensions.dart';
import 'package:nephrolog/l10n/localizations.dart';
import 'package:nephrolog/models/contract.dart';
import 'package:nephrolog/routes.dart';
import 'package:nephrolog/services/api_service.dart';
import 'package:nephrolog/ui/charts/nutrient_weekly_bar_chart.dart';
import 'package:nephrolog/ui/charts/today_nutrients_consumption_bar_chart.dart';
import 'package:nephrolog/ui/general/app_future_builder.dart';
import 'package:nephrolog/ui/general/components.dart';
import 'package:nephrolog_api_client/model/daily_intake_report.dart';
import 'package:nephrolog_api_client/model/intake.dart';
import 'package:nephrolog_api_client/model/nutrient_screen_response.dart';

import 'creation/product_search.dart';
import 'weekly_nutrients_screen.dart';

class NutritionTab extends StatefulWidget {
  @override
  _NutritionTabState createState() => _NutritionTabState();
}

class _NutritionTabState extends State<NutritionTab> {
  final now = DateTime.now();

  final apiService = ApiService();
  AppLocalizations appLocalizations;

  @override
  Widget build(BuildContext context) {
    appLocalizations = AppLocalizations.of(context);

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async => await _createProduct(context),
        label: Text(appLocalizations.createMeal.toUpperCase()),
        icon: Icon(Icons.add),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      body: _buildBody(context),
    );
  }

  Future _createProduct(BuildContext context) async {
    final product = await showProductSearch(context, ProductSearchType.choose);

    if (product != null) {
      setState(() {});
    }
  }

  Widget _buildBody(BuildContext context) {
    final appLocalizations = AppLocalizations.of(context);

    return AppFutureBuilder<NutrientScreenResponse>(
      future: apiService.getNutritionScreen(),
      builder: (context, data) {
        final latestIntakes = data.latestIntakes.toList();
        final dailyIntakesReports = data.dailyIntakesReports.toList();
        final todayIntakesReport = data.todayIntakesReport;

        return Visibility(
          visible: latestIntakes.isNotEmpty,
          replacement: EmptyStateContainer(
            text: appLocalizations.nutritionEmpty,
          ),
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 64),
              child: Column(
                children: [
                  // if (intakes.isEmpty) _buildNoMealsBanner(),
                  DailyNormsSection(dailyIntakeReport: todayIntakesReport),
                  // if (intakes.isNotEmpty)
                  DailyIntakesCard(
                    title: appLocalizations.lastMealsSectionTitle,
                    intakes: latestIntakes,
                  ),
                  for (final nutrient in Nutrient.values)
                    buildIndicatorChartSection(
                      context,
                      todayIntakesReport,
                      dailyIntakesReports,
                      nutrient,
                    )
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  openIntakesScreen(BuildContext context, Nutrient indicator) {
    Navigator.pushNamed(
      context,
      Routes.ROUTE_DAILY_WEEKLY_NUTRIENTS_SCREEN,
      arguments: WeeklyNutrientsScreenArguments(indicator),
    );
  }

  LargeSection buildIndicatorChartSection(
    BuildContext context,
    DailyIntakeReport todayIntakesReport,
    List<DailyIntakeReport> dailyIntakesReports,
    Nutrient nutrient,
  ) {
    final localizations = AppLocalizations.of(context);

    final dailyNormFormatted =
        todayIntakesReport.getNutrientNormFormatted(nutrient);
    final todayConsumption =
        todayIntakesReport.getNutrientTotalAmountFormatted(nutrient);

    final showGraph = dailyIntakesReports.expand((e) => e.intakes).isNotEmpty;

    String subtitle;
    if (dailyNormFormatted != null) {
      subtitle = localizations.todayConsumptionWithNorm(
        todayConsumption,
        dailyNormFormatted,
      );
    } else {
      subtitle = localizations.todayConsumptionWithoutNorm(
        todayConsumption,
      );
    }

    return LargeSection(
      title: nutrient.name(localizations),
      subTitle: subtitle,
      children: [
        if (showGraph)
          NutrientWeeklyBarChart(
            dailyIntakeReports: dailyIntakesReports,
            nutrient: nutrient,
            maximumDate: todayIntakesReport.date,
            fitInsideVertically: false,
          )
      ],
      leading: OutlineButton(
        child: Text(localizations.more.toUpperCase()),
        onPressed: () => openIntakesScreen(context, nutrient),
      ),
    );
  }
}

class DailyNormsSection extends StatelessWidget {
  final DailyIntakeReport dailyIntakeReport;

  const DailyNormsSection({
    Key key,
    this.dailyIntakeReport,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return LargeSection(
      title: AppLocalizations.of(context).dailyNormsSectionTitle,
      subTitle: AppLocalizations.of(context).dailyNormsSectionSubtitle,
      leading: IconButton(
        icon: Icon(
          Icons.help_outline,
        ),
        onPressed: () => showInformationScreen(context),
      ),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TodayNutrientsConsumptionBarChart(
              dailyIntakeReport: dailyIntakeReport,
            ),
          ],
        ),
      ],
    );
  }

  Future showInformationScreen(BuildContext context) {
    return Navigator.pushNamed(
      context,
      Routes.ROUTE_FAQ,
    );
  }
}

class DailyIntakesCard extends StatelessWidget {
  final String title;
  final String subTitle;
  final Widget leading;
  final List<Intake> intakes;

  const DailyIntakesCard({
    Key key,
    this.title,
    this.subTitle,
    this.leading,
    @required this.intakes,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final intakeTiles =
        intakes.map((intake) => IntakeTile(intake: intake)).toList();

    return LargeSection(
      title: title,
      subTitle: subTitle,
      leading: leading,
      children: intakeTiles,
    );
  }
}

class IntakeTile extends StatelessWidget {
  static final dateFormat = DateFormat("E, d MMM HH:mm");

  final Intake intake;

  const IntakeTile({Key key, @required this.intake}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListTile(
      key: ObjectKey(intake),
      title: Text(intake.product.name),
      contentPadding: EdgeInsets.zero,
      subtitle: Text(
        dateFormat.format(intake.consumedAt.toLocal()).capitalizeFirst(),
      ),
      leading: ProductKindIcon(productKind: intake.product.kind),
      trailing: Text(intake.getAmountFormatted()),
    );
  }
}
