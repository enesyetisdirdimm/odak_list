// lib/screens/reports_screen.dart

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:odak_list/models/task.dart';
import 'package:odak_list/models/team_member.dart';
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
  int _touchedIndex = -1; // Pasta grafik animasyonu için (Genel Durum)
  int _workloadTouchedIndex = -1; // İş Yükü Grafiği animasyonu için

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final taskProvider = Provider.of<TaskProvider>(context);

    final isDarkMode = themeProvider.themeMode == ThemeMode.dark;
    final textColor = isDarkMode ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final subTextColor = isDarkMode ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;
    final cardColor = Theme.of(context).cardColor;

    // --- VERİ HESAPLAMALARI ---
    final allTasks = taskProvider.tasks;
    final totalTasks = allTasks.length;
    final completedTasks = allTasks.where((t) => t.isDone).length;
    final pendingTasks = totalTasks - completedTasks;
    
    // Benim Tamamladıklarım
    final myId = taskProvider.currentMember?.id;
    final myCompletedCount = allTasks.where((t) => t.isDone && t.assignedMemberId == myId).length;
    
    // Verimlilik Oranı
    final double successRate = totalTasks > 0 ? (completedTasks / totalTasks) : 0.0;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // BAŞLIK
              Text(
                "Raporlar ve Analiz",
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: textColor),
              ),
              Text(
                "Ekibinin ve senin performans özetin.",
                style: TextStyle(color: subTextColor, fontSize: 16),
              ),
              const SizedBox(height: 24),

              // 1. ÖZET KARTLARI (Grid)
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                crossAxisSpacing: 15,
                mainAxisSpacing: 15,
                childAspectRatio: 1.5,
                children: [
                  _buildSummaryCard("Toplam İş", "$totalTasks", Icons.folder_open, Colors.blue, isDarkMode),
                  _buildSummaryCard("Tamamlanan", "$completedTasks", Icons.check_circle_outline, Colors.green, isDarkMode),
                  _buildSummaryCard("Bekleyen", "$pendingTasks", Icons.hourglass_empty, Colors.orange, isDarkMode),
                  _buildSummaryCard("Senin Katkın", "$myCompletedCount", Icons.person, Colors.purple, isDarkMode),
                ],
              ),
              const SizedBox(height: 30),

              // 2. HAFTALIK VERİMLİLİK (Line Chart)
              Text("Son 7 Günlük Aktivite", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor)),
              const SizedBox(height: 15),
              Container(
                height: 250,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: isDarkMode ? [] : AppStyles.softShadow,
                ),
                child: _buildWeeklyChart(allTasks, themeProvider, isDarkMode),
              ),
              
              const SizedBox(height: 30),

              // 3. YENİ: İŞ YÜKÜ DAĞILIMI (Kimin üstünde ne kadar iş var?)
              Text("İş Yükü Dağılımı (Bekleyen)", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor)),
              const SizedBox(height: 5),
              Text("Şu an kimin masasında ne kadar dosya var?", style: TextStyle(fontSize: 12, color: subTextColor)),
              const SizedBox(height: 15),
              Container(
                height: 320,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: isDarkMode ? [] : AppStyles.softShadow,
                ),
                child: _buildWorkloadChart(allTasks, taskProvider, isDarkMode, textColor),
              ),

              const SizedBox(height: 30),

              // 4. EKİP LİDERLİK TABLOSU (Sadece Admin veya Herkes görebilir, şu an herkes)
              Text("Ekip Şampiyonları 🏆", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor)),
              const SizedBox(height: 15),
              _buildTeamLeaderboard(allTasks, taskProvider, isDarkMode, cardColor, textColor),

              const SizedBox(height: 30),

              // 5. GENEL DURUM DAĞILIMI (Pie Chart)
              Text("Genel Durum", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor)),
              const SizedBox(height: 15),
              Container(
                height: 300,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: isDarkMode ? [] : AppStyles.softShadow,
                ),
                child: _buildPieChart(completedTasks, pendingTasks, themeProvider),
              ),
              
              const SizedBox(height: 50),
            ],
          ),
        ),
      ),
    );
  }

  // --- WIDGET YAPILARI ---

  Widget _buildSummaryCard(String title, String value, IconData icon, Color color, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? Colors.grey.shade900 : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: isDark ? [] : [
          BoxShadow(color: color.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 4))
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
              Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87)),
            ],
          ),
          Text(title, style: TextStyle(color: isDark ? Colors.grey : Colors.grey.shade600, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildWeeklyChart(List<Task> tasks, ThemeProvider theme, bool isDark) {
    // 1. Verileri Hazırla
    List<FlSpot> spots = [];
    DateTime now = DateTime.now();
    DateTime todayMidnight = DateTime(now.year, now.month, now.day);
    
    // Son 7 günün günlük toplamlarını hesapla
    List<int> dailyCounts = List.filled(7, 0);

    for (var task in tasks) {
      if (task.isDone && task.dueDate != null) {
         DateTime taskMidnight = DateTime(task.dueDate!.year, task.dueDate!.month, task.dueDate!.day);
         int daysDiff = todayMidnight.difference(taskMidnight).inDays;
         
         if (daysDiff >= 0 && daysDiff < 7) {
           dailyCounts[6 - daysDiff]++; // 0: En eski, 6: Bugün
         }
      }
    }

    // Noktaları oluştur
    for (int i = 0; i < 7; i++) {
      spots.add(FlSpot(i.toDouble(), dailyCounts[i].toDouble()));
    }

    // Max Y (Grafik tavanı)
    double maxY = (dailyCounts.reduce((curr, next) => curr > next ? curr : next)).toDouble();
    if (maxY == 0) maxY = 4; else maxY += 1;

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
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              interval: 1,
              getTitlesWidget: (value, meta) {
                DateTime day = DateTime.now().subtract(Duration(days: 6 - value.toInt()));
                String text = DateFormat('E', 'tr_TR').format(day);
                return SideTitleWidget(
                  axisSide: meta.axisSide,
                  child: Text(text, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
                );
              },
            ),
          ),
          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        minX: 0,
        maxX: 6,
        minY: 0,
        maxY: maxY,
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true, // Dalgalı çizgi
            gradient: LinearGradient(
              colors: [theme.primaryColor, theme.secondaryColor],
            ),
            barWidth: 4,
            isStrokeCapRound: true,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, barData, index) {
                return FlDotCirclePainter(
                  radius: 4,
                  color: isDark ? Colors.white : Colors.white,
                  strokeWidth: 2,
                  strokeColor: theme.secondaryColor,
                );
              },
            ),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                colors: [
                  theme.primaryColor.withOpacity(0.3),
                  theme.secondaryColor.withOpacity(0.0),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
        ],
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            tooltipBgColor: theme.secondaryColor,
            getTooltipItems: (List<LineBarSpot> touchedBarSpots) {
              return touchedBarSpots.map((barSpot) {
                return LineTooltipItem(
                  '${barSpot.y.toInt()} Görev',
                  const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                );
              }).toList();
            },
          ),
        ),
      ),
    );
  }

  // --- YENİ WIDGET: İŞ YÜKÜ DAĞILIMI ---
  Widget _buildWorkloadChart(List<Task> tasks, TaskProvider provider, bool isDark, Color textColor) {
    // 1. Bekleyen İşleri Kişilere Göre Say
    Map<String, int> workloadMap = {};
    
    // "Atanmamış" işleri de "Havuz" olarak görelim
    workloadMap["unassigned"] = 0;

    // Tüm üyeleri map'e ekle (0 ile başlat)
    for (var member in provider.teamMembers) {
      workloadMap[member.id] = 0;
    }

    // Görevleri tara
    for (var task in tasks) {
      if (!task.isDone) {
        if (task.assignedMemberId == null) {
          workloadMap["unassigned"] = (workloadMap["unassigned"] ?? 0) + 1;
        } else if (workloadMap.containsKey(task.assignedMemberId)) {
          workloadMap[task.assignedMemberId!] = (workloadMap[task.assignedMemberId!] ?? 0) + 1;
        }
      }
    }

    // Sadece işi olanları (value > 0) listele ki grafik karışmasın
    var activeLoad = workloadMap.entries.where((e) => e.value > 0).toList();

    if (activeLoad.isEmpty) {
      return const Center(child: Text("Şu an bekleyen iş yok! Herkes rahat. 🎉", style: TextStyle(color: Colors.grey)));
    }

    // Renk Paleti
    List<Color> colors = [
      Colors.blue, Colors.red, Colors.orange, Colors.purple, Colors.teal, Colors.pink, Colors.green
    ];

    return Row(
      children: [
        // GRAFİK KISMI
        Expanded(
          flex: 3,
          child: PieChart(
            PieChartData(
              pieTouchData: PieTouchData(
                touchCallback: (FlTouchEvent event, pieTouchResponse) {
                  setState(() {
                    if (!event.isInterestedForInteractions || pieTouchResponse == null || pieTouchResponse.touchedSection == null) {
                      _workloadTouchedIndex = -1;
                      return;
                    }
                    _workloadTouchedIndex = pieTouchResponse.touchedSection!.touchedSectionIndex;
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
                
                // Havuz için gri, diğerleri için renkli
                Color color = memberId == "unassigned" ? Colors.grey : colors[index % colors.length];

                return PieChartSectionData(
                  color: color,
                  value: count.toDouble(),
                  title: '$count',
                  radius: radius,
                  titleStyle: TextStyle(fontSize: fontSize, fontWeight: FontWeight.bold, color: Colors.white),
                );
              }).toList(),
            ),
          ),
        ),
        const SizedBox(width: 20),
        
        // AÇIKLAMA KISMI (LEGEND)
        Expanded(
          flex: 2,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: activeLoad.asMap().entries.map((entry) {
              int index = entry.key;
              String memberId = entry.value.key;
              
              // İsmi bul
              String name = memberId == "unassigned" ? "Havuz (Atanmadı)" : (provider.getMemberName(memberId) ?? "Bilinmeyen");
              Color color = memberId == "unassigned" ? Colors.grey : colors[index % colors.length];
              
              return Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Row(
                  children: [
                    Container(width: 12, height: 12, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
                    const SizedBox(width: 8),
                    Expanded(child: Text(name, style: TextStyle(fontSize: 12, color: textColor, fontWeight: FontWeight.w500), overflow: TextOverflow.ellipsis)),
                  ],
                ),
              );
            }).toList(),
          ),
        )
      ],
    );
  }

  Widget _buildTeamLeaderboard(List<Task> tasks, TaskProvider provider, bool isDark, Color cardColor, Color textColor) {
    // 1. Ekip üyelerini ve tamamladıkları iş sayısını hesapla
    Map<String, int> memberScores = {};
    
    // Her üye için başlangıç skoru 0
    for (var member in provider.teamMembers) {
      memberScores[member.id] = 0;
    }

    // Görevleri say
    for (var task in tasks) {
      if (task.isDone && task.assignedMemberId != null) {
        if (memberScores.containsKey(task.assignedMemberId)) {
          memberScores[task.assignedMemberId!] = memberScores[task.assignedMemberId!]! + 1;
        }
      }
    }

    // Sırala (En yüksek puan en üstte)
    var sortedEntries = memberScores.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    if (sortedEntries.isEmpty) {
      return Center(child: Text("Henüz ekip aktivitesi yok.", style: TextStyle(color: Colors.grey)));
    }

    return Column(
      children: sortedEntries.asMap().entries.map((entry) {
        int index = entry.key; // Sıralama (1., 2., 3.)
        String memberId = entry.value.key;
        int score = entry.value.value;
        
        // Üye ismini bul
        String name = provider.getMemberName(memberId) ?? "Bilinmeyen";
        bool isTop3 = index < 3;

        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(15),
            border: isTop3 ? Border.all(color: _getRankColor(index), width: 1.5) : null,
          ),
          child: Row(
            children: [
              // Sıralama Rozeti
              Container(
                width: 30, height: 30,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isTop3 ? _getRankColor(index).withOpacity(0.2) : Colors.grey.withOpacity(0.1),
                ),
                child: Text(
                  "${index + 1}",
                  style: TextStyle(fontWeight: FontWeight.bold, color: isTop3 ? _getRankColor(index) : Colors.grey),
                ),
              ),
              const SizedBox(width: 15),
              
              // İsim ve Rol
              Expanded(
                child: Text(name, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: textColor)),
              ),
              
              // Skor
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: isDark ? Colors.grey.shade800 : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    Icon(Icons.check_circle, size: 14, color: Colors.green),
                    const SizedBox(width: 6),
                    Text("$score", style: TextStyle(fontWeight: FontWeight.bold, color: textColor)),
                  ],
                ),
              )
            ],
          ),
        );
      }).toList(),
    );
  }

  Color _getRankColor(int index) {
    if (index == 0) return const Color(0xFFFFD700); // Altın
    if (index == 1) return const Color(0xFFC0C0C0); // Gümüş
    if (index == 2) return const Color(0xFFCD7F32); // Bronz
    return Colors.grey;
  }

  Widget _buildPieChart(int done, int pending, ThemeProvider theme) {
    if (done == 0 && pending == 0) {
      return const Center(child: Text("Veri Yok"));
    }
    
    return Row(
      children: [
        Expanded(
          flex: 3,
          child: PieChart(
            PieChartData(
              pieTouchData: PieTouchData(
                touchCallback: (FlTouchEvent event, pieTouchResponse) {
                  setState(() {
                    if (!event.isInterestedForInteractions || pieTouchResponse == null || pieTouchResponse.touchedSection == null) {
                      _touchedIndex = -1;
                      return;
                    }
                    _touchedIndex = pieTouchResponse.touchedSection!.touchedSectionIndex;
                  });
                },
              ),
              borderData: FlBorderData(show: false),
              sectionsSpace: 2,
              centerSpaceRadius: 40,
              sections: [
                _buildPieSection(done, theme.secondaryColor, "Bitti", 0),
                _buildPieSection(pending, Colors.grey.shade400, "Bekleyen", 1),
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
              _buildLegendItem("Tamamlanan", theme.secondaryColor, "$done"),
              const SizedBox(height: 10),
              _buildLegendItem("Bekleyen", Colors.grey.shade400, "$pending"),
            ],
          ),
        )
      ],
    );
  }

  PieChartSectionData _buildPieSection(int value, Color color, String title, int index) {
    final isTouched = index == _touchedIndex;
    final fontSize = isTouched ? 18.0 : 14.0;
    final radius = isTouched ? 60.0 : 50.0;
    
    return PieChartSectionData(
      color: color,
      value: value.toDouble(),
      title: value > 0 ? '${(value).toInt()}' : '',
      radius: radius,
      titleStyle: TextStyle(fontSize: fontSize, fontWeight: FontWeight.bold, color: Colors.white),
    );
  }

  Widget _buildLegendItem(String title, Color color, String value) {
    return Row(
      children: [
        Container(width: 12, height: 12, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontSize: 12, color: Colors.grey)),
            Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ],
        )
      ],
    );
  }
}