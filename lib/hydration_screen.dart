import 'package:drink/widgets/hydration_bottom_nav_bar.dart';
import 'package:drink/hydration_history_screen.dart';
import 'package:drink/nativead.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:pie_chart/pie_chart.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import 'dart:convert';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:share_plus/share_plus.dart';
import 'package:provider/provider.dart';
import 'package:drink/theme_provider.dart';
import 'package:drink/info.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:confetti/confetti.dart';
import 'widgets/celebration_confetti.dart';

class HydrationScreen extends StatefulWidget {
  const HydrationScreen({super.key});

  @override
  State<HydrationScreen> createState() => _HydrationScreenState();
}

class _HydrationScreenState extends State<HydrationScreen> {
  double totalIntake = 0;
  double goalIntake = 0;
  int weightKg = 0;
  List<Map<String, dynamic>> intakeHistory = [];
  String selectedDate = DateFormat('yyyy-MM-dd').format(DateTime.now());
  double editableCupAmount = 300;
  String intakeUnit = 'ml';

  // Add these fields to your _HydrationScreenState:
  late ConfettiController _confettiController;
  bool goalCelebrated = false;

  @override
  void initState() {
    super.initState();
    _loadFromPreferences();
    _checkAndResetDaily();
    _loadIntakeHistory();
    // Initialize the confetti controller
    _confettiController = ConfettiController(
      duration: const Duration(seconds: 2),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadFromPreferences();
  }

  Future<void> _loadFromPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      weightKg = prefs.getInt('weight') ?? 0;
      goalIntake = prefs.getInt('goalIntake')?.toDouble() ?? 0;
      intakeUnit = prefs.getString('intakeUnit') ?? 'ml';
    });
  }

  Future<void> _checkAndResetDaily() async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final lastReset = prefs.getString('lastResetDate');

    if (lastReset != today) {
      setState(() {
        totalIntake = 0;
        intakeHistory.clear();
      });
      await prefs.setString('lastResetDate', today);
      await prefs.setDouble('totalIntake', 0);
      await prefs.remove('intakeHistory');
    } else {
      setState(() {
        totalIntake = prefs.getDouble('totalIntake') ?? 0;
      });
    }
  }

  Future<void> _loadIntakeHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final historyString = prefs.getString('intakeHistory');
    if (historyString != null) {
      final decoded = jsonDecode(historyString);
      if (decoded is List) {
        setState(() {
          intakeHistory = decoded
              .map<Map<String, dynamic>>(
                (item) => {
                  'date': item['date'],
                  'time': item['time'],
                  'amount': item['amount'].toDouble(),
                },
              )
              .toList();
        });
      }
    }
  }

  Future<void> _saveIntakeHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('intakeHistory', jsonEncode(intakeHistory));
  }

  String _displayVolume(double ml) {
    if (intakeUnit == 'ml') return '${ml.toStringAsFixed(0)} ml';
    return '${(ml * 0.033814).toStringAsFixed(1)} fl oz';
  }

  double _toMl(double value) {
    return intakeUnit == 'ml' ? value : value / 0.033814;
  }

  double _fromMl(double ml) {
    return intakeUnit == 'ml' ? ml : ml * 0.033814;
  }

  void _deductIntake(double valueInUnit) async {
    final now = DateTime.now();
    final date = DateFormat('yyyy-MM-dd').format(now);
    final time = TimeOfDay.fromDateTime(now).format(context);

    double valueInMl = _toMl(valueInUnit);

    setState(() {
      totalIntake = (totalIntake + valueInMl).clamp(0, goalIntake);
      intakeHistory.insert(0, {
        'date': date,
        'time': time,
        'amount': valueInMl,
      });
    });

    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('totalIntake', totalIntake);
    await _saveIntakeHistory();
  }

  Future<void> _clearIntakeHistory() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      intakeHistory.clear();
      totalIntake = 0;
    });
    await prefs.remove('intakeHistory');
    await prefs.setDouble('totalIntake', 0);
  }

  void _exportHistory() async {
    final isMl = intakeUnit == 'ml';
    final csvHeader = 'Date,Time,Amount (${isMl ? 'ml' : 'fl oz'})';
    final csvRows = intakeHistory
        .map((entry) {
          final amount = isMl
              ? entry['amount'].toStringAsFixed(0)
              : (entry['amount'] * 0.033814).toStringAsFixed(1);
          return '${entry['date']},${entry['time']},$amount';
        })
        .join('\n');
    final csv = '$csvHeader\n$csvRows';
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/hydration_history.csv');
      await file.writeAsString(csv);
      if (!mounted) return;
      await Share.shareXFiles(
        [XFile(file.path)],
        text: 'My Hydration History',
        subject: 'Hydration History Export',
      );
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Exported to ${file.path}')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to export: $e')));
    }
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;

    final currentPercentage = goalIntake == 0
        ? 0
        : (totalIntake / goalIntake).clamp(0, 1);
    final percentValue = (currentPercentage * 100).round();

    // 🎉 Play confetti when goal is reached and not yet celebrated
    if (goalIntake > 0 && totalIntake >= goalIntake && !goalCelebrated) {
      _confettiController.play();
      goalCelebrated = true;
    }
    // Reset celebration if user resets or lowers intake
    if (goalCelebrated && totalIntake < goalIntake) {
      goalCelebrated = false;
    }

    final Map<String, double> dataMap = {
      "Consumed": totalIntake,
      "Remaining": (goalIntake - totalIntake).clamp(0, goalIntake),
    };

    final colorList = isDark
        ? [Colors.blueGrey, Colors.blue[900]!]
        : [Colors.lightBlue, Colors.blue[900]!];

    final filteredHistory = intakeHistory
        .where((entry) => entry['date'] == selectedDate)
        .toList();

    return Stack(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Scaffold(
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            appBar: AppBar(
              backgroundColor: Theme.of(context).scaffoldBackgroundColor,
              elevation: 0,
              automaticallyImplyLeading: false,
              actions: [
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const InfoScreen()),
                    ).then((_) {
                      _loadFromPreferences();
                    });
                  },
                  child: const Padding(
                    padding: EdgeInsets.only(right: 16.0),
                    child: Icon(Icons.settings, color: Colors.lightBlue),
                  ),
                ),
              ],
            ),
            body: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: goalIntake == 0
                    ? Center(child: Text('Please set your weight in settings.'))
                    : Column(
                        children: [
                          Expanded(
                            child: SingleChildScrollView(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                children: [
                                  const SizedBox(height: 24),

                                  Text(
                                    'current_hydration'.tr(),
                                    style: GoogleFonts.poppins(
                                      textStyle: Theme.of(
                                        context,
                                      ).textTheme.titleLarge,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),

                                  const SizedBox(height: 87),
                                  PieChart(
                                    dataMap: dataMap,
                                    animationDuration: const Duration(
                                      milliseconds: 800,
                                    ),
                                    chartRadius:
                                        MediaQuery.of(context).size.width / 2,
                                    colorList: colorList,
                                    initialAngleInDegree: 270,
                                    chartType: ChartType.ring,
                                    ringStrokeWidth: 32,
                                    centerWidget: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          '$percentValue%',
                                          style: Theme.of(context)
                                              .textTheme
                                              .headlineSmall
                                              ?.copyWith(
                                                fontWeight: FontWeight.bold,
                                                color: Theme.of(
                                                  context,
                                                ).colorScheme.primary,
                                              ),
                                        ),
                                        Text(_displayVolume(totalIntake)),
                                        Text(
                                          '-${_displayVolume((goalIntake - totalIntake).clamp(0, goalIntake))}',
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodySmall
                                              ?.copyWith(
                                                color: Theme.of(
                                                  context,
                                                ).colorScheme.secondary,
                                              ),
                                        ),
                                      ],
                                    ),
                                    legendOptions: const LegendOptions(
                                      showLegends: false,
                                    ),
                                    chartValuesOptions:
                                        const ChartValuesOptions(
                                          showChartValues: false,
                                        ),
                                  ),
                                  const SizedBox(height: 16),
                                  // 👇 Native Ad inserted here
                                  const NativeAdContainer(),
                                  const SizedBox(height: 16),
                                  Text(
                                    "tap_container".tr(),
                                    textAlign: TextAlign.center,
                                    style: GoogleFonts.poppins(
                                      color: Colors.blue,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 20,
                                    ),
                                  ),
                                  const SizedBox(height: 24),
                                  Wrap(
                                    spacing: 16,
                                    runSpacing: 16,
                                    alignment: WrapAlignment.center,
                                    children: [
                                      _editableCupButton(
                                        _displayVolume(editableCupAmount),
                                        Icons.opacity,
                                        isDark
                                            ? Colors.blueGrey[700]!
                                            : Colors.blue[100]!,
                                        _fromMl(editableCupAmount),
                                      ),
                                      _waterButton(
                                        _displayVolume(500),
                                        Icons.local_drink,
                                        isDark
                                            ? Colors.pink[200]!
                                            : Colors.pink[100]!,
                                        _fromMl(500),
                                      ),
                                      _waterButton(
                                        _displayVolume(180),
                                        Icons.coffee,
                                        isDark
                                            ? Colors.yellow[700]!
                                            : Colors.yellow[100]!,
                                        _fromMl(180),
                                      ),
                                      _waterButton(
                                        _displayVolume(250),
                                        Icons.local_bar,
                                        isDark
                                            ? Colors.purple[700]!
                                            : Colors.purple[100]!,
                                        _fromMl(250),
                                      ),
                                      _customCupButton(),
                                    ],
                                  ),
                                  const SizedBox(height: 30),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    children: [
                                      IconButton(
                                        icon: Icon(
                                          Icons.bar_chart,
                                          color: Colors.lightBlue,
                                          size: 30,
                                        ),
                                        onPressed: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) =>
                                                  HistoryChartScreen(
                                                    historyMap:
                                                        latestIntakeHistoryMap,
                                                    title: 'hydration_history'
                                                        .tr(),
                                                  ),
                                            ),
                                          );
                                        },
                                      ),
                                    ],
                                  ),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'intake_history'.tr(),
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleMedium
                                            ?.copyWith(
                                              fontWeight: FontWeight.bold,
                                            ),
                                      ),
                                      Row(
                                        children: [
                                          TextButton(
                                            onPressed: _exportHistory,
                                            child: Text(
                                              'export'.tr(),
                                              style: TextStyle(
                                                color: Theme.of(
                                                  context,
                                                ).colorScheme.primary,
                                              ),
                                            ),
                                          ),
                                          TextButton(
                                            onPressed: _clearIntakeHistory,
                                            child: Text(
                                              'clear'.tr(),
                                              style: TextStyle(
                                                color: Theme.of(
                                                  context,
                                                ).colorScheme.error,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  Row(
                                    children: [
                                      const Text(
                                        "date",
                                        style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ).tr(),
                                      TextButton(
                                        child: Text(selectedDate),
                                        onPressed: () async {
                                          final picked = await showDatePicker(
                                            context: context,
                                            initialDate: DateTime.parse(
                                              selectedDate,
                                            ),
                                            firstDate: DateTime(2024),
                                            lastDate: DateTime.now(),
                                          );
                                          if (picked != null) {
                                            setState(() {
                                              selectedDate = DateFormat(
                                                'yyyy-MM-dd',
                                              ).format(picked);
                                            });
                                          }
                                        },
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  filteredHistory.isEmpty
                                      ? const Text("no_entry_date").tr()
                                      : SizedBox(
                                          height: 150,
                                          child: ListView.builder(
                                            itemCount: filteredHistory.length,
                                            itemBuilder: (context, index) {
                                              final item =
                                                  filteredHistory[index];
                                              final originalIndex =
                                                  intakeHistory.indexWhere(
                                                    (entry) =>
                                                        entry['date'] ==
                                                            item['date'] &&
                                                        entry['time'] ==
                                                            item['time'] &&
                                                        entry['amount'] ==
                                                            item['amount'],
                                                  );
                                              return ListTile(
                                                leading: Icon(
                                                  Icons.history,
                                                  color: Theme.of(
                                                    context,
                                                  ).iconTheme.color,
                                                ),
                                                title: Text(
                                                  _displayVolume(
                                                    item['amount'],
                                                  ),
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight
                                                        .w600, // <-- Slightly bolder than default
                                                  ),
                                                ),
                                                subtitle: Text(
                                                  '${item['time']}',
                                                ),
                                                trailing: Row(
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  children: [
                                                    IconButton(
                                                      icon: const Icon(
                                                        Icons.edit,
                                                        color: Colors.orange,
                                                      ),
                                                      tooltip: 'Modify',
                                                      onPressed: () {
                                                        if (originalIndex !=
                                                            -1) {
                                                          _modifyHistoryEntry(
                                                            originalIndex,
                                                          );
                                                        }
                                                      },
                                                    ),
                                                    IconButton(
                                                      icon: const Icon(
                                                        Icons.delete,
                                                        color: Colors.red,
                                                      ),
                                                      tooltip: 'delete'.tr(),
                                                      onPressed: () {
                                                        if (originalIndex !=
                                                            -1) {
                                                          _deleteHistoryEntry(
                                                            originalIndex,
                                                          );
                                                        }
                                                      },
                                                    ),
                                                  ],
                                                ),
                                              );
                                            },
                                          ),
                                        ),
                                  const SizedBox(height: 20),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
              ),
            ),
            // Place the navigation bar at the bottom
            bottomNavigationBar: HydrationBottomNavBar(
              currentIndex: 1,
              parentContext: context,
            ),
          ),
        ),

        // 🎉 Confetti overlay
        CelebrationConfetti(controller: _confettiController),
      ],
    );
  }

  Widget _waterButton(
    String label,
    IconData icon,
    Color color,
    double valueInUnit,
  ) {
    return Container(
      width: 120,
      height: 96,
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          IconButton(
            icon: Icon(icon, color: Colors.black54, size: 24),
            onPressed: () => _deductIntake(valueInUnit),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _editableCupButton(
    String label,
    IconData icon,
    Color color,
    double valueInUnit,
  ) {
    return Container(
      width: 120,
      height: 96,
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Stack(
        children: [
          // Edit icon at top right
          Positioned(
            top: 0,
            right: 0,
            child: IconButton(
              icon: const Icon(Icons.edit, color: Colors.orange, size: 18),
              tooltip: 'Edit cup size',
              onPressed: () async {
                final newAmount = await showDialog<double>(
                  context: context,
                  builder: (context) => _EditCupDialog(
                    initialAmount: valueInUnit,
                    intakeUnit: intakeUnit,
                  ),
                );
                if (newAmount != null && newAmount > 0) {
                  setState(() {
                    editableCupAmount = _toMl(newAmount);
                  });
                }
              },
            ),
          ),
          // Icon.opacity in the center
          Align(
            alignment: Alignment.center,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: Icon(icon, color: Colors.black54, size: 24),
                  onPressed: () => _deductIntake(valueInUnit),
                ),
                const SizedBox(height: 4),
                Text(
                  label,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _customCupButton() {
    return Container(
      width: 120,
      height: 96,
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: Colors.teal[100],
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          IconButton(
            icon: const Icon(Icons.edit, color: Colors.black54, size: 24),
            onPressed: () async {
              final amount = await showDialog<double>(
                context: context,
                builder: (context) => _CustomCupDialog(intakeUnit: intakeUnit),
              );
              if (amount != null && amount > 0) {
                _deductIntake(amount);
              }
            },
          ),
          const SizedBox(height: 4),
          Flexible(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                'custom_cup'.tr(),
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
                maxLines: 2, // Allow up to 2 lines
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Map<String, double> get latestIntakeHistoryMap {
    final Map<String, double> map = {};
    for (var entry in intakeHistory) {
      final date = entry['date'];
      final amount = entry['amount'] as double;
      map[date] = (map[date] ?? 0) + amount;
    }
    return map;
  }

  Future<void> _deleteHistoryEntry(int index) async {
    setState(() {
      intakeHistory.removeAt(index);
      totalIntake = intakeHistory
          .where((entry) => entry['date'] == selectedDate)
          .fold(0.0, (sum, entry) => sum + (entry['amount'] as double));
    });
    await _saveIntakeHistory();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('totalIntake', totalIntake);
  }

  Future<void> _modifyHistoryEntry(int index) async {
    final current = intakeHistory[index];
    final controller = TextEditingController(
      text: intakeUnit == 'ml'
          ? current['amount'].toString()
          : (current['amount'] * 0.033814).toStringAsFixed(1),
    );
    final newAmount = await showDialog<double>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Modify Intake Amount (${intakeUnit == 'ml' ? 'ml' : 'fl oz'})',
        ),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            hintText: intakeUnit == 'ml'
                ? 'Enter new amount (ml)'
                : 'Enter new amount (fl oz)',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('cancel'.tr()),
          ),
          ElevatedButton(
            onPressed: () {
              final value = double.tryParse(controller.text);
              if (value != null && value > 0) {
                Navigator.pop(context, value);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (newAmount != null) {
      setState(() {
        intakeHistory[index]['amount'] = _toMl(newAmount);
        totalIntake = intakeHistory
            .where((entry) => entry['date'] == selectedDate)
            .fold(0.0, (sum, entry) => sum + (entry['amount'] as double));
      });
      await _saveIntakeHistory();
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble('totalIntake', totalIntake);
    }
  }
}

// _CustomCupDialog and _EditCupDialog remain unchanged

// Update _CustomCupDialog to use the correct unit
class _CustomCupDialog extends StatefulWidget {
  final String intakeUnit;
  const _CustomCupDialog({this.intakeUnit = 'ml'});

  @override
  State<_CustomCupDialog> createState() => _CustomCupDialogState();
}

class _CustomCupDialogState extends State<_CustomCupDialog> {
  final TextEditingController _controller = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('enter_amount'.tr(namedArgs: {'unit': widget.intakeUnit})),

      content: TextField(
        controller: _controller,
        keyboardType: TextInputType.number,
        decoration: InputDecoration(
          hintText: widget.intakeUnit == 'ml' ? 'e.g. 320' : 'e.g. 10.5',
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('cancel'.tr()),
        ),
        ElevatedButton(
          onPressed: () {
            final value = double.tryParse(_controller.text);
            if (value != null && value > 0) {
              Navigator.pop(context, value);
            }
          },
          child: const Text('add').tr(),
        ),
      ],
    );
  }
}

// Dialog for editing the cup amount
class _EditCupDialog extends StatefulWidget {
  final double initialAmount;
  final String intakeUnit;
  const _EditCupDialog({required this.initialAmount, this.intakeUnit = 'ml'});

  @override
  State<_EditCupDialog> createState() => _EditCupDialogState();
}

class _EditCupDialogState extends State<_EditCupDialog> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: widget.initialAmount.toStringAsFixed(
        widget.intakeUnit == 'ml' ? 0 : 1,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('edit_cup_size'.tr(namedArgs: {'unit': widget.intakeUnit})),

      content: TextField(
        controller: _controller,
        keyboardType: TextInputType.number,
        decoration: InputDecoration(
          hintText: widget.intakeUnit == 'ml' ? 'e.g. 250' : 'e.g. 8.5',
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('cancel'.tr()),
        ),
        ElevatedButton(
          onPressed: () {
            final value = double.tryParse(_controller.text);
            if (value != null && value > 0) {
              Navigator.pop(context, value);
            }
          },
          child: const Text('save').tr(),
        ),
      ],
    );
  }
}
