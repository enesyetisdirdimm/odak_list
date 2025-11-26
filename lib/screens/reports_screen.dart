import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:odak_list/utils/app_colors.dart';
import 'package:odak_list/utils/app_styles.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:odak_list/theme_provider.dart';
import 'package:odak_list/task_provider.dart';

class ReportsScreen extends StatelessWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final taskProvider = Provider.of<TaskProvider>(context);

    final isDarkMode = themeProvider.themeMode == ThemeMode.dark;
    final textColor = isDarkMode ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final subTextColor = isDarkMode ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;
    final cardColor = Theme.of(context).cardColor;

    // VERİLERİ HESAPLA
    final projects = taskProvider.projects;
    final allTasks = taskProvider.tasks;
    
    int totalTasks = allTasks.length;
    int completedTasks = allTasks.where((t) => t.isDone).length;
    int pendingTasks = totalTasks - completedTasks;
    
    // --- KRİTİK DÜZELTME: SAATLERİ SIFIRLAYARAK HESAPLAMA ---
    List<int> weeklyData = List.filled(7, 0);
    
    // Bugünün gece yarısı (Saat 00:00:00)
    DateTime now = DateTime.now();
    DateTime todayMidnight = DateTime(now.year, now.month, now.day);

    for (var task in allTasks) {
      // Sadece tamamlanmış ve tarihi olan görevleri say
      if (task.isDone && task.dueDate != null) {
        
        // Görevin tarihini de gece yarısına çek
        DateTime taskDate = task.dueDate!;
        DateTime taskMidnight = DateTime(taskDate.year, taskDate.month, taskDate.day);

        // Gün farkını hesapla (Artık saatler 0 olduğu için tam gün farkı çıkar)
        int daysDiff = todayMidnight.difference(taskMidnight).inDays;

        // Eğer görev son 7 gün içindeyse (0 = Bugün, 6 = 6 gün önce)
        if (daysDiff >= 0 && daysDiff < 7) {
          // Grafik soldan sağa (Eskiden Yeniye) olduğu için indexi ters çeviriyoruz
          // daysDiff 0 (Bugün) -> Index 6 (En sağ)
          // daysDiff 6 (Geçen hafta) -> Index 0 (En sol)
          weeklyData[6 - daysDiff]++;
        }
      }
    }

    // Maksimum Y değerini bul (Grafik taşmasın diye)
    double maxY = 0;
    for (var val in weeklyData) {
      if (val > maxY) maxY = val.toDouble();
    }
    maxY = maxY + 2; // Biraz boşluk bırak

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: taskProvider.isLoading 
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

                    // --- 1. PASTA GRAFİK ---
                    Container(
                      height: 260, 
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
                                Expanded(
                                  flex: 3,
                                  child: totalTasks == 0 
                                    ? Center(child: Text("Veri Yok", style: TextStyle(color: subTextColor)))
                                    : PieChart(
                                      PieChartData(
                                        borderData: FlBorderData(show: false),
                                        sectionsSpace: 2,
                                        centerSpaceRadius: 35,
                                        sections: [
                                          PieChartSectionData(
                                            color: themeProvider.secondaryColor,
                                            value: completedTasks.toDouble(),
                                            title: totalTasks > 0 ? '${((completedTasks/totalTasks)*100).toInt()}%' : '0%',
                                            radius: 50,
                                            titleStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
                                          ),
                                          PieChartSectionData(
                                            color: isDarkMode ? Colors.grey.shade800 : Colors.grey.shade200,
                                            value: pendingTasks.toDouble(),
                                            title: '',
                                            radius: 40,
                                          ),
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

                    // --- 2. ÇUBUK GRAFİK (DÜZELTİLDİ) ---
                    Text("Son 7 Günlük Aktivite", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor)),
                    const SizedBox(height: 16),
                    
                    Container(
                      height: 240,
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
                          maxY: maxY,
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
                                reservedSize: 30,
                                getTitlesWidget: (double value, TitleMeta meta) {
                                  // Alt kısımdaki gün isimleri (Pzt, Sal vs.)
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
                                  // Bugünün çubuğu renkli, diğerleri gri
                                  color: e.key == 6 ? themeProvider.secondaryColor : (isDarkMode ? Colors.grey.shade800 : Colors.grey.shade300),
                                  width: 14,
                                  borderRadius: BorderRadius.circular(4),
                                  backDrawRodData: BackgroundBarChartRodData(
                                    show: true,
                                    toY: maxY, // Arka plan yüksekliği
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
                                  Expanded(
                                    child: Text(
                                      project.title, 
                                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: textColor),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
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