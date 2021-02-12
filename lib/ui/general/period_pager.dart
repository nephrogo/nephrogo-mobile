import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:nephrogo/extensions/extensions.dart';
import 'package:nephrogo/models/date.dart';
import 'package:nephrogo/utils/date_utils.dart';

typedef PagerBodyBuilder = Widget Function(
  BuildContext context,
  Widget header,
  Date from,
  Date to,
);

typedef OnPageChanged = void Function(
  Date from,
  Date to,
);

class DailyPager extends StatelessWidget {
  final _dayFormatter = DateFormat('EEEE, MMMM d');

  final OnPageChanged onPageChanged;

  final Date earliestDate;
  final Date initialDate;

  final PagerBodyBuilder bodyBuilder;

  DailyPager({
    Key key,
    @required this.earliestDate,
    @required this.initialDate,
    @required this.bodyBuilder,
    this.onPageChanged,
  })  : assert(earliestDate != null),
        assert(initialDate != null),
        assert(bodyBuilder != null),
        super(key: key);

  @override
  Widget build(BuildContext context) {
    final today = Date.today();
    final dates = DateUtils.generateDates(earliestDate, today).toList();

    final initialFromDateIndex = dates.indexOf(initialDate);
    assert(initialFromDateIndex != -1);

    return _PeriodPager(
      bodyBuilder: bodyBuilder,
      headerTextBuilder: _buildHeaderText,
      allFromDates: dates,
      initialFromDate: dates[initialFromDateIndex],
      dateFromToDateTo: _dateFromToDateTo,
      onPageChanged: onPageChanged,
    );
  }

  Date _dateFromToDateTo(Date from) => from;

  Widget _buildHeaderText(BuildContext context, Date from, Date to) {
    return Text(_dayFormatter.format(from).capitalizeFirst());
  }
}

class WeeklyPager extends StatelessWidget {
  final dateFormatter = DateFormat.MMMMd();
  final _monthFormatter = DateFormat("MMMM ");

  final Date earliestDate;
  final Date initialDate;

  final PagerBodyBuilder bodyBuilder;

  WeeklyPager({
    Key key,
    @required this.earliestDate,
    @required this.initialDate,
    @required this.bodyBuilder,
  })  : assert(earliestDate != null),
        assert(initialDate != null),
        assert(bodyBuilder != null),
        super(key: key);

  @override
  Widget build(BuildContext context) {
    final today = Date.today();
    final dates = DateUtils.generateWeekDates(earliestDate, today).toList();

    final initialFromDateIndex = dates.indexOf(initialDate.firstDayOfWeek());
    assert(initialFromDateIndex != -1);

    return _PeriodPager(
      bodyBuilder: bodyBuilder,
      headerTextBuilder: _buildHeaderText,
      allFromDates: dates,
      initialFromDate: dates[initialFromDateIndex],
      dateFromToDateTo: _dateFromToDateTo,
    );
  }

  Date _dateFromToDateTo(Date from) {
    return from.lastDayOfWeek();
  }

  Widget _buildHeaderText(BuildContext context, Date from, Date to) {
    if (from.month == to.month) {
      final formattedFrom = _monthFormatter.format(from).capitalizeFirst();
      return Text("$formattedFrom ${from.day} – ${to.day}");
    }

    return Text('${dateFormatter.format(from).capitalizeFirst()} – '
        '${dateFormatter.format(to).capitalizeFirst()}');
  }
}

class MonthlyPager extends StatelessWidget {
  static final monthFormatter = DateFormat.yMMMM();

  final Date earliestDate;
  final Date initialDate;

  final PagerBodyBuilder bodyBuilder;

  const MonthlyPager({
    Key key,
    @required this.earliestDate,
    @required this.initialDate,
    @required this.bodyBuilder,
  })  : assert(earliestDate != null),
        assert(initialDate != null),
        assert(bodyBuilder != null),
        super(key: key);

  @override
  Widget build(BuildContext context) {
    final today = Date.today();
    final dates = DateUtils.generateMonthDates(earliestDate, today).toList();

    final initialFromDateIndex =
        dates.indexOf(Date(initialDate.year, initialDate.month, 1));

    assert(initialFromDateIndex != -1);

    return _PeriodPager(
      bodyBuilder: bodyBuilder,
      headerTextBuilder: _buildHeaderText,
      allFromDates: dates,
      initialFromDate: dates[initialFromDateIndex],
      dateFromToDateTo: _dateFromToDateTo,
    );
  }

  Date _dateFromToDateTo(Date from) {
    return DateUtils.getLastDayOfCurrentMonth(from);
  }

  Widget _buildHeaderText(BuildContext context, Date from, Date to) {
    return Text(monthFormatter.format(from).capitalizeFirst());
  }
}

class _PeriodPager extends StatefulWidget {
  final List<Date> allFromDates;
  final Date initialFromDate;

  final Date Function(Date from) dateFromToDateTo;

  final OnPageChanged onPageChanged;
  final PagerBodyBuilder bodyBuilder;
  final Widget Function(
    BuildContext context,
    Date from,
    Date to,
  ) headerTextBuilder;

  const _PeriodPager({
    Key key,
    @required this.allFromDates,
    @required this.initialFromDate,
    @required this.bodyBuilder,
    @required this.headerTextBuilder,
    @required this.dateFromToDateTo,
    this.onPageChanged,
  })  : assert(initialFromDate != null),
        assert(allFromDates != null),
        assert(bodyBuilder != null),
        assert(headerTextBuilder != null),
        assert(dateFromToDateTo != null),
        super(key: key);

  @override
  _PeriodPagerState createState() => _PeriodPagerState();
}

class _PeriodPagerState extends State<_PeriodPager> {
  static const _animationDuration = Duration(milliseconds: 400);

  List<Date> _dates;

  PageController _pageController;

  @override
  void initState() {
    super.initState();

    _dates = widget.allFromDates.sortedBy((e) => e, reverse: true).toList();

    final initialIndex = _dates.indexOf(widget.initialFromDate);
    assert(initialIndex != -1);

    _pageController = PageController(
      initialPage: initialIndex,
      viewportFraction: 0.99999,
    );
  }

  @override
  Widget build(BuildContext context) {
    return PageView.builder(
      controller: _pageController,
      reverse: true,
      itemCount: _dates.length,
      onPageChanged: widget.onPageChanged != null
          ? (index) {
              final from = _dates[index];
              final to = widget.dateFromToDateTo(from);

              widget.onPageChanged(from, to);
            }
          : null,
      itemBuilder: (context, index) {
        final from = _dates[index];
        final to = widget.dateFromToDateTo(from);

        final header = _buildDateSelectionSection(index, from, to);

        return widget.bodyBuilder(context, header, from, to);
      },
    );
  }

  bool hasNextDateRange(int index) => index > 0;

  bool hasPreviousDateRange(int index) => index + 1 < _dates.length;

  Future<void> advanceToNextDateRange() {
    return _pageController.previousPage(
        duration: _animationDuration, curve: Curves.ease);
  }

  Future<void> advanceToPreviousDateRange() {
    return _pageController.nextPage(
        duration: _animationDuration, curve: Curves.ease);
  }

  Widget _buildDateSelectionSection(int index, Date from, Date to) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          iconSize: 32,
          icon: const Icon(
            Icons.navigate_before,
          ),
          onPressed:
              hasPreviousDateRange(index) ? advanceToPreviousDateRange : null,
        ),
        Expanded(
          child: DefaultTextStyle(
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyText1,
            child: widget.headerTextBuilder(context, from, to),
          ),
        ),
        IconButton(
          iconSize: 32,
          icon: const Icon(Icons.navigate_next),
          onPressed: hasNextDateRange(index) ? advanceToNextDateRange : null,
        ),
      ],
    );
  }

  @override
  void dispose() {
    _pageController.dispose();

    super.dispose();
  }
}