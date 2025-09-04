import 'package:easy_localization/easy_localization.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:provider/provider.dart';
import 'package:drink/theme_provider.dart';

enum HistoryFilter { daily, monthly, annual }

class HistoryChartScreen extends StatefulWidget {
  final String title;
  final Map<String, double> historyMap;

  const HistoryChartScreen({
    required this.title,
    required this.historyMap,
    super.key,
  });

  @override
  State<HistoryChartScreen> createState() => _HistoryChartScreenState();
}

class _HistoryChartScreenState extends State<HistoryChartScreen> {
  HistoryFilter _selectedFilter = HistoryFilter.daily;
  List<Map<String, dynamic>> intakeHistory = [];
  String intakeUnit = 'ml';
  double goalIntake = 2000;

  @override
  void initState() {
    super.initState();
    _loadIntakeHistory();
    _loadIntakeUnitAndGoal();
  }

  Future<void> _loadIntakeUnitAndGoal() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      intakeUnit = prefs.getString('intakeUnit') ?? 'ml';
      goalIntake = (prefs.getInt('goalIntake') ?? 2000).toDouble();
    });
  }

  double _toDisplayUnit(double ml) {
    return intakeUnit == 'ml' ? ml : ml * 0.033814;
  }

  String _unitLabel() => intakeUnit == 'ml' ? 'ml' : 'fl oz';

  Future<void> _loadIntakeHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final historyString = prefs.getString('intakeHistory');
    if (historyString != null) {
      setState(() {
        intakeHistory = List<Map<String, dynamic>>.from(
          jsonDecode(historyString),
        );
      });
    }
  }

  Map<String, double> get dataMapFromHistory {
    final Map<String, double> result = {};
    for (var entry in intakeHistory) {
      final date = entry['date'];
      final amountMl = entry['amount'].toDouble();
      final amount = _toDisplayUnit(amountMl);
      if (result.containsKey(date)) {
        result[date] = result[date]! + amount;
      } else {
        result[date] = amount;
      }
    }
    return result;
  }

  Map<String, double> get filteredData {
    final fullMap = dataMapFromHistory;
    final now = DateTime.now();
    final locale = context.locale.languageCode;

    if (_selectedFilter == HistoryFilter.daily) {
      final today = DateFormat('yyyy-MM-dd', locale).format(now);
      return Map.fromEntries(fullMap.entries.where((e) => e.key == today));
    } else if (_selectedFilter == HistoryFilter.monthly) {
      final month = DateFormat('yyyy-MM', locale).format(now);
      return Map.fromEntries(
        fullMap.entries.where((e) => e.key.startsWith(month)),
      );
    } else {
      final year = DateFormat('yyyy', locale).format(now);
      return Map.fromEntries(
        fullMap.entries.where((e) => e.key.startsWith(year)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;
    final locale = context.locale.languageCode;

    final dataMap = filteredData;
    final goalForDisplay = _toDisplayUnit(goalIntake);
    final goalUnitLabel = _unitLabel();

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        title: Text(
          "hydration_history".tr(),
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
      ),
      body: Stack(
        children: [
          // Background watermark
          Positioned.fill(
            child: Opacity(
              opacity: 0.07,
              child: Image.asset('assets/drink_icon.png', fit: BoxFit.cover),
            ),
          ),
          // Foreground content fills the screen and is scrollable
          LayoutBuilder(
            builder: (context, constraints) => SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        weeklyCompletionMenu(dataMap, goalForDisplay),
                        drinkWaterReport(
                          dataMap,
                          goalForDisplay,
                          goalUnitLabel,
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            ChoiceChip(
                              label: Text(
                                tr('daily'),
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ), // <-- Bold
                              ),
                              selected: _selectedFilter == HistoryFilter.daily,
                              onSelected: (_) => setState(
                                () => _selectedFilter = HistoryFilter.daily,
                              ),
                              selectedColor: Theme.of(
                                context,
                              ).colorScheme.primary.withOpacity(0.2),
                            ),
                            const SizedBox(width: 8),
                            ChoiceChip(
                              label: Text(
                                tr('monthly'),
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ), // <-- Bold
                              ),
                              selected:
                                  _selectedFilter == HistoryFilter.monthly,
                              onSelected: (_) => setState(
                                () => _selectedFilter = HistoryFilter.monthly,
                              ),
                              selectedColor: Theme.of(
                                context,
                              ).colorScheme.primary.withOpacity(0.2),
                            ),
                            const SizedBox(width: 8),
                            ChoiceChip(
                              label: Text(
                                tr('annual'),
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ), // <-- Bold
                              ),
                              selected: _selectedFilter == HistoryFilter.annual,
                              onSelected: (_) => setState(
                                () => _selectedFilter = HistoryFilter.annual,
                              ),
                              selectedColor: Theme.of(
                                context,
                              ).colorScheme.primary.withOpacity(0.2),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        // Remove Expanded here!
                        dataMap.isEmpty
                            ? Center(
                                child: Text('no_data_for_selected_period'.tr()),
                              )
                            : SizedBox(
                                height:
                                    240, // or any height that fits your chart
                                child: BarChart(
                                  BarChartData(
                                    alignment: BarChartAlignment.spaceBetween,
                                    maxY: dataMap.values.isNotEmpty
                                        ? dataMap.values.reduce(
                                                (a, b) => a > b ? a : b,
                                              ) +
                                              100
                                        : 100,
                                    titlesData: FlTitlesData(
                                      leftTitles: AxisTitles(
                                        sideTitles: SideTitles(
                                          showTitles: true,
                                          reservedSize: 36,
                                          getTitlesWidget: (value, meta) =>
                                              Text(
                                                value.toInt().toString(),
                                                style: TextStyle(
                                                  color: Theme.of(
                                                    context,
                                                  ).colorScheme.onSurface,
                                                ),
                                              ),
                                        ),
                                      ),
                                      bottomTitles: AxisTitles(
                                        sideTitles: SideTitles(
                                          showTitles: true,
                                          reservedSize: 32,
                                          getTitlesWidget: (value, meta) {
                                            final dateKeys = dataMap.keys
                                                .toList();
                                            if (value < 0 ||
                                                value >= dateKeys.length) {
                                              return const SizedBox.shrink();
                                            }
                                            final rawDate =
                                                dateKeys[value.toInt()];
                                            final parsedDate =
                                                DateTime.tryParse(rawDate);
                                            if (parsedDate == null) {
                                              return const SizedBox.shrink();
                                            }
                                            String formatted;
                                            if (_selectedFilter ==
                                                HistoryFilter.annual) {
                                              formatted = DateFormat(
                                                'yyyy',
                                                locale,
                                              ).format(parsedDate);
                                            } else if (_selectedFilter ==
                                                HistoryFilter.monthly) {
                                              formatted = DateFormat(
                                                'MM',
                                                locale,
                                              ).format(parsedDate);
                                            } else {
                                              formatted = DateFormat(
                                                'dd/MM',
                                                locale,
                                              ).format(parsedDate);
                                            }
                                            return Padding(
                                              padding: const EdgeInsets.only(
                                                top: 8.0,
                                              ),
                                              child: Text(
                                                formatted,
                                                style: TextStyle(
                                                  fontSize: 10,
                                                  color: Theme.of(
                                                    context,
                                                  ).colorScheme.onSurface,
                                                ),
                                              ),
                                            );
                                          },
                                        ),
                                      ),
                                      topTitles: AxisTitles(
                                        sideTitles: SideTitles(
                                          showTitles: false,
                                        ),
                                      ),
                                      rightTitles: AxisTitles(
                                        sideTitles: SideTitles(
                                          showTitles: false,
                                        ),
                                      ),
                                    ),
                                    borderData: FlBorderData(show: false),
                                    barGroups: dataMap.entries
                                        .toList()
                                        .asMap()
                                        .entries
                                        .map((entry) {
                                          final index = entry.key;
                                          final item = entry.value;
                                          return BarChartGroupData(
                                            x: index,
                                            barRods: [
                                              BarChartRodData(
                                                toY: item.value,
                                                width: 14,
                                                color: isDark
                                                    ? Colors.lightBlueAccent
                                                    : Colors.blueAccent,
                                              ),
                                            ],
                                          );
                                        })
                                        .toList(),
                                    gridData: FlGridData(show: true),
                                  ),
                                ),
                              ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget weeklyCompletionMenu(
    Map<String, double> dataMap,
    double goalForDisplay,
  ) {
    final now = DateTime.now();
    final locale = context.locale.languageCode;
    List<Widget> days = [];
    for (int i = 6; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      final dateStr = DateFormat('yyyy-MM-dd', locale).format(date);
      final metGoal = (dataMap[dateStr]?.toDouble() ?? 0.0) >= goalForDisplay;
      days.add(
        Column(
          children: [
            Text(
              DateFormat('E', locale).format(date),
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            Icon(
              metGoal ? Icons.check_circle : Icons.radio_button_unchecked,
              color: metGoal ? Colors.green : Colors.grey,
            ),
          ],
        ),
      );
    }
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: days,
    );
  }

  Widget drinkWaterReport(
    Map<String, double> dataMap,
    double goalForDisplay,
    String goalUnitLabel,
  ) {
    final now = DateTime.now();
    final locale = context.locale.languageCode;
    final weekStart = now.subtract(const Duration(days: 6));
    final weekDates = List.generate(
      7,
      (i) => DateFormat(
        'yyyy-MM-dd',
        locale,
      ).format(weekStart.add(Duration(days: i))),
    );
    final weekIntakes = weekDates.map((d) => (dataMap[d] ?? 0.0)).toList();
    final weeklyAvg = weekIntakes.isNotEmpty
        ? weekIntakes.reduce((a, b) => a + b) / 7
        : 0;
    final weekCompletion =
        weekIntakes.where((v) => v >= goalForDisplay).length / 7 * 100;

    final monthStr = DateFormat('yyyy-MM', locale).format(now);
    final monthIntakes = dataMap.entries
        .where((e) => e.key.startsWith(monthStr))
        .map((e) => e.value)
        .toList();
    final monthlyAvg = monthIntakes.isNotEmpty
        ? monthIntakes.reduce((a, b) => a + b) / monthIntakes.length
        : 0;

    final drinkFrequency = dataMap.values.where((v) => v > 0.0).length;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 16),
      color: Theme.of(context).cardColor,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'drink_water_report'.tr(),
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'weekly_average'.tr(
                namedArgs: {
                  'avg': weeklyAvg.toStringAsFixed(
                    goalUnitLabel == 'ml' ? 0 : 1,
                  ),
                  'unit': goalUnitLabel,
                },
              ),
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            Text(
              'monthly_average'.tr(
                namedArgs: {
                  'avg': monthlyAvg.toStringAsFixed(
                    goalUnitLabel == 'ml' ? 0 : 1,
                  ),
                  'unit': goalUnitLabel,
                },
              ),
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            Text(
              'weekly_completion'.tr(
                namedArgs: {'percent': weekCompletion.toStringAsFixed(0)},
              ),
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            Text(
              'drink_frequency'.tr(namedArgs: {'days': '$drinkFrequency'}),
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}
