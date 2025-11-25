import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:odak_list/models/project.dart';
import 'package:odak_list/services/database_service.dart';
import 'package:odak_list/utils/app_colors.dart';
import 'package:intl/intl.dart';
import 'package:odak_list/utils/app_styles.dart';
import 'package:provider/provider.dart';
import 'package:odak_list/theme_provider.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  final DatabaseService _dbService = DatabaseService();
  
  int totalTasks = 0;
  int completedTasks = 0;
  int pendingTasks = 0;
  
  List<Project> projects = [];
  List<int> weeklyData = List.filled(7, 0);
  
  bool isLoading = true;
  int touchedIndex = -1;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    final allProjects = await _dbService.getProjectsWithStats();
    final allTasks = await _dbService.getTasks();
    
    int completed = 0;
    int pending = 0;
    
    List<int> weekCounts = List.filled(7, 0);
    DateTime now = DateTime.now();

    for (var task in allTasks) {
      if (task.isDone) completed++;
      else pending++;

      if (task.dueDate != null) {
        final difference = now.difference(task.dueDate!).inDays;
        if (difference >= 0 && difference < 7) {
          weekCounts[6 - difference]++;
        }
      }
    }

    if (mounted) {
      setState(() {
        projects = allProjects;
        totalTasks = allTasks.length;
        completedTasks = completed;
        pendingTasks = pending;
        weeklyData = weekCounts;
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.themeMode == ThemeMode.dark;
    final textColor = isDarkMode ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final subTextColor = isDarkMode ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;
    final cardColor = Theme.of(context).cardColor;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: isLoading 
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Performans Analizi",
                      style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: textColor),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      "Bu haftaki verimlilik durumun.",
                      style: TextStyle(color: subTextColor, fontSize: 15),
                    ),
                    const SizedBox(height: 30),

                    // --- 1. PASTA GRAFİK KARTI ---
                    Container(
                      height: 260, // Biraz yükselttik
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: cardColor,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: isDarkMode ? [] : AppStyles.softShadow,
                        border: isDarkMode ? Border.all(color: Colors.white10) : null,
                      ),
                      child: Column(
                        children: [
                          Expanded(
                            child: Row(
                              children: [
                                // Grafik Kısmı
                                Expanded(
                                  flex: 3,
                                  child: totalTasks == 0 
                                    ? Center(child: Text("Veri Yok", style: TextStyle(color: subTextColor)))
                                    : PieChart(
                                      PieChartData(
                                        pieTouchData: PieTouchData(
                                          touchCallback: (FlTouchEvent event, pieTouchResponse) {
                                            setState(() {
                                              if (!event.isInterestedForInteractions || pieTouchResponse == null || pieTouchResponse.touchedSection == null) {
                                                touchedIndex = -1;
                                                return;
                                              }
                                              touchedIndex = pieTouchResponse.touchedSection!.touchedSectionIndex;
                                            });
                                          },
                                        ),
                                        borderData: FlBorderData(show: false),
                                        sectionsSpace: 2, // Dilimler arası boşluk
                                        centerSpaceRadius: 35, // Ortadaki boşluk küçültüldü
                                        sections: [
                                          PieChartSectionData(
                                            color: themeProvider.secondaryColor,
                                            value: completedTasks.toDouble(),
                                            title: '${((completedTasks/totalTasks)*100).toInt()}%',
                                            radius: touchedIndex == 0 ? 55 : 45,
                                            titleStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
                                          ),
                                          PieChartSectionData(
                                            color: isDarkMode ? Colors.grey.shade800 : Colors.grey.shade200,
                                            value: pendingTasks.toDouble(),
                                            title: '', // Boş kısma yazı yazmıyoruz, karışmasın
                                            radius: touchedIndex == 1 ? 45 : 35,
                                          ),
                                        ],
                                      ),
                                    ),
                                ),
                                const SizedBox(width: 20),
                                // Lejant (Açıklama) Kısmı
                                Expanded(
                                  flex: 2,
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      _buildLegendItem("Tamamlanan", themeProvider.secondaryColor, completedTasks.toString(), textColor),
                                      const SizedBox(height: 20),
                                      _buildLegendItem("Bekleyen", isDarkMode ? Colors.grey.shade600 : Colors.grey.shade400, pendingTasks.toString(), textColor),
                                    ],
                                  ),
                                )
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 30),

                    // --- 2. ÇUBUK GRAFİK KARTI ---
                    Text("Son 7 Günlük Aktivite", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor)),
                    const SizedBox(height: 16),
                    
                    Container(
                      height: 240, // Yükseklik artırıldı, ferah olsun
                      padding: const EdgeInsets.fromLTRB(12, 24, 12, 10),
                      decoration: BoxDecoration(
                        color: cardColor,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: isDarkMode ? [] : AppStyles.softShadow,
                        border: isDarkMode ? Border.all(color: Colors.white10) : null,
                      ),
                      child: BarChart(
                        BarChartData(
                          alignment: BarChartAlignment.spaceAround,
                          maxY: (weeklyData.reduce((curr, next) => curr > next ? curr : next) + 2).toDouble(),
                          barTouchData: BarTouchData(
                            touchTooltipData: BarTouchTooltipData(
                              tooltipBgColor: themeProvider.primaryColor,
                              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                                return BarTooltipItem(
                                  rod.toY.round().toString(),
                                  const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                );
                              },
                            ),
                          ),
                          titlesData: FlTitlesData(
                            show: true,
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                reservedSize: 30, // Alt yazılar için yer açtık
                                getTitlesWidget: (double value, TitleMeta meta) {
                                  DateTime day = DateTime.now().subtract(Duration(days: 6 - value.toInt()));
                                  String text = DateFormat('E', 'tr_TR').format(day);
                                  return SideTitleWidget(
                                    axisSide: meta.axisSide,
                                    child: Text(text, style: TextStyle(color: subTextColor, fontSize: 11, fontWeight: FontWeight.bold)),
                                  );
                                },
                              ),
                            ),
                            leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          ),
                          borderData: FlBorderData(show: false),
                          gridData: const FlGridData(show: false),
                          barGroups: weeklyData.asMap().entries.map((e) {
                            return BarChartGroupData(
                              x: e.key,
                              barRods: [
                                BarChartRodData(
                                  toY: e.value.toDouble(),
                                  color: e.key == 6 ? themeProvider.secondaryColor : (isDarkMode ? Colors.grey.shade800 : Colors.grey.shade300),
                                  width: 14, // Çubuklar biraz inceltildi
                                  borderRadius: BorderRadius.circular(4),
                                  backDrawRodData: BackgroundBarChartRodData(
                                    show: true,
                                    toY: (weeklyData.reduce((curr, next) => curr > next ? curr : next) + 2).toDouble(),
                                    color: isDarkMode ? Colors.grey.shade900 : Colors.grey.shade50,
                                  )
                                ),
                              ],
                            );
                          }).toList(),
                        ),
                      ),
                    ),

                    const SizedBox(height: 30),

                    // --- 3. PROJE LİSTESİ ---
                    if (projects.isNotEmpty) ...[
                      Text("Proje Bazlı İlerleme", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor)),
                      const SizedBox(height: 16),
                      
                      ...projects.map((project) => Padding(
                        padding: const EdgeInsets.only(bottom: 12.0),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: cardColor,
                            borderRadius: BorderRadius.circular(16),
                            border: isDarkMode ? Border.all(color: Colors.white10) : null,
                            boxShadow: isDarkMode ? [] : [
                              BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 5, offset: const Offset(0, 2))
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  // DÜZELTME: Proje ismi uzunsa taşmasın (Expanded)
                                  Expanded(
                                    child: Text(
                                      project.title, 
                                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: textColor),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis, // ... koy
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Text("${(project.progress * 100).toInt()}%", style: TextStyle(fontWeight: FontWeight.bold, color: themeProvider.secondaryColor)),
                                ],
                              ),
                              const SizedBox(height: 8),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: LinearProgressIndicator(
                                  value: project.progress,
                                  minHeight: 6,
                                  backgroundColor: isDarkMode ? Colors.grey.shade800 : Colors.grey.shade200,
                                  valueColor: AlwaysStoppedAnimation<Color>(Color(project.colorValue)),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                "${project.completedTaskCount} / ${project.taskCount} Görev Tamamlandı",
                                style: TextStyle(fontSize: 12, color: subTextColor),
                              ),
                            ],
                          ),
                        ),
                      )),
                    ] else ...[
                      Center(child: Text("Henüz proje verisi yok.", style: TextStyle(color: subTextColor)))
                    ],
                    
                    const SizedBox(height: 50),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildLegendItem(String title, Color color, String value, Color textColor) {
    return Row(
      children: [
        Container(
          width: 12, height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontSize: 12, color: Colors.grey)),
            Text(value, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: textColor)),
          ],
        ),
      ],
    );
  }
}