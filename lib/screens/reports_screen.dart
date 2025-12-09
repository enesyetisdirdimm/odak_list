import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:odak_list/models/task.dart';
import 'package:odak_list/utils/app_colors.dart';
import 'package:odak_list/utils/app_styles.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:odak_list/theme_provider.dart';
import 'package:odak_list/task_provider.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  int _touchedIndex = -1;
  int _workloadTouchedIndex = -1;

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final taskProvider = Provider.of<TaskProvider>(context);

    final isDarkMode = themeProvider.themeMode == ThemeMode.dark;
    final textColor =
        isDarkMode ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final subTextColor =
        isDarkMode ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;
    final cardColor = Theme.of(context).cardColor;

    final allTasks = taskProvider.tasks;
    final totalTasks = allTasks.length;
    final completedTasks = allTasks.where((t) => t.isDone).length;
    final pendingTasks = totalTasks - completedTasks;

    final myId = taskProvider.currentMember?.id;
    final myCompletedCount =
        allTasks.where((t) => t.isDone && t.assignedMemberId == myId).length;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Center(
        // WEB İÇİN ORTALAMA
        child: ConstrainedBox(
          // GENİŞLİK SINIRLAMASI (Grafikler çok yayılmasın)
          constraints: const BoxConstraints(maxWidth: 1000),
          child: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Raporlar ve Analiz",
                    style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: textColor),
                  ),
                  Text(
                    "Ekibinin ve senin performans özetin.",
                    style: TextStyle(color: subTextColor, fontSize: 16),
                  ),
                  const SizedBox(height: 24),

                  // 1. ÖZET KARTLARI
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: MediaQuery.of(context).size.width > 600
                        ? 4
                        : 2, // Web'de 4, Mobilde 2 sütun
                    crossAxisSpacing: 15,
                    mainAxisSpacing: 15,
                    childAspectRatio: 1.5,
                    children: [
                      _buildSummaryCard("Toplam İş", "$totalTasks",
                          Icons.folder_open, Colors.blue, isDarkMode),
                      _buildSummaryCard("Tamamlanan", "$completedTasks",
                          Icons.check_circle_outline, Colors.green, isDarkMode),
                      _buildSummaryCard("Bekleyen", "$pendingTasks",
                          Icons.hourglass_empty, Colors.orange, isDarkMode),
                      _buildSummaryCard("Senin Katkın", "$myCompletedCount",
                          Icons.person, Colors.purple, isDarkMode),
                    ],
                  ),
                  const SizedBox(height: 30),

                  // 2. HAFTALIK VERİMLİLİK
                  Text("Son 7 Günlük Aktivite",
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: textColor)),
                  const SizedBox(height: 15),
                  Container(
                    height: 250,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: isDarkMode ? [] : AppStyles.softShadow,
                    ),
                    child:
                        _buildWeeklyChart(allTasks, themeProvider, isDarkMode),
                  ),

                  const SizedBox(height: 30),

                  // 3. İŞ YÜKÜ DAĞILIMI
                  Text("İş Yükü Dağılımı (Bekleyen)",
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: textColor)),
                  const SizedBox(height: 5),
                  Text("Şu an kimin masasında ne kadar dosya var?",
                      style: TextStyle(fontSize: 12, color: subTextColor)),
                  const SizedBox(height: 15),
                  Container(
                    height: 320,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: isDarkMode ? [] : AppStyles.softShadow,
                    ),
                    child: _buildWorkloadChart(
                        allTasks, taskProvider, isDarkMode, textColor),
                  ),

                  const SizedBox(height: 30),

                  // 4. EKİP LİDERLİK TABLOSU
                  Text("Ekip Şampiyonları 🏆",
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: textColor)),
                  const SizedBox(height: 15),
                  _buildTeamLeaderboard(
                      allTasks, taskProvider, isDarkMode, cardColor, textColor),

                  const SizedBox(height: 30),

                  // 5. GENEL DURUM DAĞILIMI
                  Text("Genel Durum",
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: textColor)),
                  const SizedBox(height: 15),
                  Container(
                    height: 300,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: isDarkMode ? [] : AppStyles.softShadow,
                    ),
                    child: _buildPieChart(
                        completedTasks, pendingTasks, themeProvider),
                  ),

                  const SizedBox(height: 50),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // --- YARDIMCI WIDGETLAR (Aynı) ---

  Widget _buildSummaryCard(
      String title, String value, IconData icon, Color color, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? Colors.grey.shade900 : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: isDark
            ? []
            : [
                BoxShadow(
                    color: color.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4))
              ],
        border: Border.all(color: color.withOpacity(0.3), width: 1),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: color),
              Text(value,
                  style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black87)),
            ],
          ),
          Text(title,
              style: TextStyle(
                  color: isDark ? Colors.grey : Colors.grey.shade600,
                  fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildWeeklyChart(List<Task> tasks, ThemeProvider theme, bool isDark) {
    List<FlSpot> spots = [];
    DateTime now = DateTime.now();
    DateTime todayMidnight = DateTime(now.year, now.month, now.day);
    List<int> dailyCounts = List.filled(7, 0);

    for (var task in tasks) {
      if (task.isDone && task.dueDate != null) {
        DateTime taskMidnight = DateTime(
            task.dueDate!.year, task.dueDate!.month, task.dueDate!.day);
        int daysDiff = todayMidnight.difference(taskMidnight).inDays;
        if (daysDiff >= 0 && daysDiff < 7) {
          dailyCounts[6 - daysDiff]++;
        }
      }
    }

    for (int i = 0; i < 7; i++) {
      spots.add(FlSpot(i.toDouble(), dailyCounts[i].toDouble()));
    }

    double maxY = (dailyCounts
        .reduce((curr, next) => curr > next ? curr : next)).toDouble();
    if (maxY == 0)
      maxY = 4;
    else
      maxY += 1;

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (value) => FlLine(
            color: isDark ? Colors.white10 : Colors.grey.shade200,
            strokeWidth: 1,
          ),
        ),
        titlesData: FlTitlesData(
          show: true,
          rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              interval: 1,
              getTitlesWidget: (value, meta) {
                DateTime day =
                    DateTime.now().subtract(Duration(days: 6 - value.toInt()));
                String text = DateFormat('E', 'tr_TR').format(day);
                return SideTitleWidget(
                  axisSide: meta.axisSide,
                  child: Text(text,
                      style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey)),
                );
              },
            ),
          ),
          leftTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        minX: 0,
        maxX: 6,
        minY: 0,
        maxY: maxY,
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            gradient: LinearGradient(
                colors: [theme.primaryColor, theme.secondaryColor]),
            barWidth: 4,
            isStrokeCapRound: true,
            dotData: FlDotData(show: true),
            belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(colors: [
                  theme.primaryColor.withOpacity(0.3),
                  theme.secondaryColor.withOpacity(0.0)
                ], begin: Alignment.topCenter, end: Alignment.bottomCenter)),
          ),
        ],
      ),
    );
  }

  Widget _buildWorkloadChart(
      List<Task> tasks, TaskProvider provider, bool isDark, Color textColor) {
    Map<String, int> workloadMap = {};
    workloadMap["unassigned"] = 0;
    for (var member in provider.teamMembers) {
      workloadMap[member.id] = 0;
    }

    for (var task in tasks) {
      if (!task.isDone) {
        if (task.assignedMemberId == null) {
          workloadMap["unassigned"] = (workloadMap["unassigned"] ?? 0) + 1;
        } else if (workloadMap.containsKey(task.assignedMemberId)) {
          workloadMap[task.assignedMemberId!] =
              (workloadMap[task.assignedMemberId!] ?? 0) + 1;
        }
      }
    }

    var activeLoad = workloadMap.entries.where((e) => e.value > 0).toList();

    if (activeLoad.isEmpty) {
      return const Center(
          child: Text("Şu an bekleyen iş yok! Herkes rahat. 🎉",
              style: TextStyle(color: Colors.grey)));
    }

    List<Color> colors = [
      Colors.blue,
      Colors.red,
      Colors.orange,
      Colors.purple,
      Colors.teal,
      Colors.pink,
      Colors.green
    ];

    return Row(
      children: [
        Expanded(
          flex: 3,
          child: PieChart(
            PieChartData(
              pieTouchData: PieTouchData(
                touchCallback: (FlTouchEvent event, pieTouchResponse) {
                  setState(() {
                    if (!event.isInterestedForInteractions ||
                        pieTouchResponse == null ||
                        pieTouchResponse.touchedSection == null) {
                      _workloadTouchedIndex = -1;
                      return;
                    }
                    _workloadTouchedIndex =
                        pieTouchResponse.touchedSection!.touchedSectionIndex;
                  });
                },
              ),
              borderData: FlBorderData(show: false),
              sectionsSpace: 2,
              centerSpaceRadius: 40,
              sections: activeLoad.asMap().entries.map((entry) {
                int index = entry.key;
                String memberId = entry.value.key;
                int count = entry.value.value;
                final isTouched = index == _workloadTouchedIndex;
                final double radius = isTouched ? 60.0 : 50.0;
                final double fontSize = isTouched ? 18.0 : 14.0;
                Color color = memberId == "unassigned"
                    ? Colors.grey
                    : colors[index % colors.length];
                return PieChartSectionData(
                    color: color,
                    value: count.toDouble(),
                    title: '$count',
                    radius: radius,
                    titleStyle: TextStyle(
                        fontSize: fontSize,
                        fontWeight: FontWeight.bold,
                        color: Colors.white));
              }).toList(),
            ),
          ),
        ),
        const SizedBox(width: 20),
        Expanded(
          flex: 2,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: activeLoad.asMap().entries.map((entry) {
              int index = entry.key;
              String memberId = entry.value.key;
              String name = memberId == "unassigned"
                  ? "Havuz"
                  : (provider.getMemberName(memberId) ?? "Bilinmeyen");
              Color color = memberId == "unassigned"
                  ? Colors.grey
                  : colors[index % colors.length];
              return Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Row(children: [
                  Container(
                      width: 12,
                      height: 12,
                      decoration:
                          BoxDecoration(color: color, shape: BoxShape.circle)),
                  const SizedBox(width: 8),
                  Expanded(
                      child: Text(name,
                          style: TextStyle(
                              fontSize: 12,
                              color: textColor,
                              fontWeight: FontWeight.w500),
                          overflow: TextOverflow.ellipsis))
                ]),
              );
            }).toList(),
          ),
        )
      ],
    );
  }

  Widget _buildTeamLeaderboard(List<Task> tasks, TaskProvider provider,
      bool isDark, Color cardColor, Color textColor) {
    Map<String, int> memberScores = {};
    for (var member in provider.teamMembers) {
      memberScores[member.id] = 0;
    }
    for (var task in tasks) {
      if (task.isDone && task.assignedMemberId != null) {
        if (memberScores.containsKey(task.assignedMemberId)) {
          memberScores[task.assignedMemberId!] =
              memberScores[task.assignedMemberId!]! + 1;
        }
      }
    }
    var sortedEntries = memberScores.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    if (sortedEntries.isEmpty)
      return Center(
          child: Text("Henüz ekip aktivitesi yok.",
              style: TextStyle(color: Colors.grey)));

    return Column(
      children: sortedEntries.asMap().entries.map((entry) {
        int index = entry.key;
        String memberId = entry.value.key;
        int score = entry.value.value;
        String name = provider.getMemberName(memberId) ?? "Bilinmeyen";
        bool isTop3 = index < 3;
        Color rankColor = index == 0
            ? const Color(0xFFFFD700)
            : (index == 1
                ? const Color(0xFFC0C0C0)
                : (index == 2 ? const Color(0xFFCD7F32) : Colors.grey));

        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(15),
              border: isTop3 ? Border.all(color: rankColor, width: 1.5) : null),
          child: Row(
            children: [
              Container(
                  width: 30,
                  height: 30,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isTop3
                          ? rankColor.withOpacity(0.2)
                          : Colors.grey.withOpacity(0.1)),
                  child: Text("${index + 1}",
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: isTop3 ? rankColor : Colors.grey))),
              const SizedBox(width: 15),
              Expanded(
                  child: Text(name,
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: textColor))),
              Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                      color:
                          isDark ? Colors.grey.shade800 : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(20)),
                  child: Row(children: [
                    Icon(Icons.check_circle, size: 14, color: Colors.green),
                    const SizedBox(width: 6),
                    Text("$score",
                        style: TextStyle(
                            fontWeight: FontWeight.bold, color: textColor))
                  ]))
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildPieChart(int done, int pending, ThemeProvider theme) {
    if (done == 0 && pending == 0) return const Center(child: Text("Veri Yok"));
    return Row(
      children: [
        Expanded(
          flex: 3,
          child: PieChart(
            PieChartData(
              pieTouchData: PieTouchData(
                  touchCallback: (FlTouchEvent event, pieTouchResponse) {
                setState(() {
                  if (!event.isInterestedForInteractions ||
                      pieTouchResponse == null ||
                      pieTouchResponse.touchedSection == null) {
                    _touchedIndex = -1;
                    return;
                  }
                  _touchedIndex =
                      pieTouchResponse.touchedSection!.touchedSectionIndex;
                });
              }),
              borderData: FlBorderData(show: false),
              sectionsSpace: 2,
              centerSpaceRadius: 40,
              sections: [
                PieChartSectionData(
                    color: theme.secondaryColor,
                    value: done.toDouble(),
                    title: done > 0 ? '$done' : '',
                    radius: _touchedIndex == 0 ? 60.0 : 50.0,
                    titleStyle: TextStyle(
                        fontSize: _touchedIndex == 0 ? 18.0 : 14.0,
                        fontWeight: FontWeight.bold,
                        color: Colors.white)),
                PieChartSectionData(
                    color: Colors.grey.shade400,
                    value: pending.toDouble(),
                    title: pending > 0 ? '$pending' : '',
                    radius: _touchedIndex == 1 ? 60.0 : 50.0,
                    titleStyle: TextStyle(
                        fontSize: _touchedIndex == 1 ? 18.0 : 14.0,
                        fontWeight: FontWeight.bold,
                        color: Colors.white)),
              ],
            ),
          ),
        ),
        const SizedBox(width: 20),
        Expanded(
            flex: 2,
            child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                            color: theme.secondaryColor,
                            shape: BoxShape.circle)),
                    const SizedBox(width: 8),
                    Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text("Tamamlanan",
                              style:
                                  TextStyle(fontSize: 12, color: Colors.grey)),
                          Text("$done",
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 16))
                        ])
                  ]),
                  const SizedBox(height: 10),
                  Row(children: [
                    Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                            color: Colors.grey.shade400,
                            shape: BoxShape.circle)),
                    const SizedBox(width: 8),
                    Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text("Bekleyen",
                              style:
                                  TextStyle(fontSize: 12, color: Colors.grey)),
                          Text("$pending",
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 16))
                        ])
                  ])
                ]))
      ],
    );
  }
}
