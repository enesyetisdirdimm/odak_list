import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:odak_list/models/task.dart';
import 'package:odak_list/models/team_member.dart';
import 'package:odak_list/utils/app_colors.dart';
import 'package:odak_list/utils/app_styles.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart'; // Web için şart
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
  
  // Rapor Ayı
  DateTime _selectedReportMonth = DateTime.now();
  
  // Yükleme durumu (DateFormat için)
  bool _isLocaleLoaded = false;

  @override
  void initState() {
    super.initState();
    // WEB İÇİN KRİTİK: Tarih formatını başlat
    initializeDateFormatting('tr_TR', null).then((_) {
      if (mounted) setState(() => _isLocaleLoaded = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    // Tarih formatı yüklenmeden ekranı çizme (Hata önleyici)
    if (!_isLocaleLoaded) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final themeProvider = Provider.of<ThemeProvider>(context);
    final taskProvider = Provider.of<TaskProvider>(context);

    final isDarkMode = themeProvider.themeMode == ThemeMode.dark;
    final textColor = isDarkMode ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final subTextColor = isDarkMode ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;
    final cardColor = Theme.of(context).cardColor;

    final allTasks = taskProvider.tasks;
    final totalTasks = allTasks.length;
    final completedTasks = allTasks.where((t) => t.isDone).length;
    final pendingTasks = totalTasks - completedTasks;

    final myId = taskProvider.currentMember?.id;
    final myCompletedCount = allTasks.where((t) => t.isDone && t.assignedMemberId == myId).length;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1000),
          child: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Raporlar ve Analiz",
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: textColor),
                  ),
                  Text(
                    "Ekip performansı ve iş dağılımı.",
                    style: TextStyle(color: subTextColor, fontSize: 16),
                  ),
                  const SizedBox(height: 24),

                  // 1. ÖZET KARTLARI
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: MediaQuery.of(context).size.width > 600 ? 4 : 2,
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

                  // 2. DETAYLI PERSONEL DURUMU (LİSTE)
                  Text("Detaylı Personel Durumu", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor)),
                  const SizedBox(height: 15),
                  _buildDetailedTeamStats(taskProvider, isDarkMode, cardColor, textColor, subTextColor),
                  
                  const SizedBox(height: 30),

                  // 3. AYLIK PERFORMANS GRAFİĞİ (BAR)
                  Text("Aylık İş Yükü & Performans", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor)),
                  const SizedBox(height: 15),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: isDarkMode ? [] : AppStyles.softShadow,
                    ),
                    child: _buildMonthlyPerformance(allTasks, taskProvider.teamMembers, isDarkMode, textColor),
                  ),

                  const SizedBox(height: 30),

                  // 4. HAFTALIK VERİMLİLİK (ÇİZGİ)
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

                  // 5. İŞ YÜKÜ DAĞILIMI (PASTA)
                  Text("Aktif İş Yükü Dağılımı", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor)),
                  const SizedBox(height: 15),
                  Container(
                    height: 350, // Yükseklik artırıldı
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: isDarkMode ? [] : AppStyles.softShadow,
                    ),
                    child: _buildWorkloadChart(allTasks, taskProvider, isDarkMode, textColor),
                  ),

                  const SizedBox(height: 30),

                  // 6. LİDERLİK TABLOSU
                  Text("Ekip Liderleri 🏆", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor)),
                  const SizedBox(height: 15),
                  _buildTeamLeaderboard(allTasks, taskProvider, isDarkMode, cardColor, textColor),

                  const SizedBox(height: 50),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // --- WIDGETLAR ---

  // A. AYLIK PERFORMANS (BAR CHART) - DÜZELTİLMİŞ HALİ
  Widget _buildMonthlyPerformance(List<Task> allTasks, List<TeamMember> members, bool isDark, Color textColor) {
    // 1. Seçili aydaki görevleri filtrele
    final tasksInMonth = allTasks.where((t) {
      if (t.dueDate == null) return false;
      return t.dueDate!.year == _selectedReportMonth.year && 
             t.dueDate!.month == _selectedReportMonth.month;
    }).toList();

    // 2. İstatistikleri Hesapla
    Map<String, Map<String, int>> stats = {};
    for (var m in members) { stats[m.id] = {'total': 0, 'done': 0}; }
    stats['unassigned'] = {'total': 0, 'done': 0};

    for (var task in tasksInMonth) {
      String key = task.assignedMemberId ?? 'unassigned';
      if (stats.containsKey(key)) {
        stats[key]!['total'] = stats[key]!['total']! + 1;
        if (task.isDone) {
          stats[key]!['done'] = stats[key]!['done']! + 1;
        }
      }
    }

    List<BarChartGroupData> barGroups = [];
    List<String> names = [];
    
    int i = 0;
    stats.forEach((memberId, data) {
      String name = memberId == 'unassigned' 
          ? 'Havuz' 
          : members.firstWhere((m) => m.id == memberId, orElse: () => TeamMember(id: '', name: '-', role: '')).name;
      
      if (name.contains(' ')) name = name.split(' ')[0];
      names.add(name);

      barGroups.add(
        BarChartGroupData(
          x: i,
          showingTooltipIndicators: [0, 1], 
          barRods: [
            BarChartRodData(
              toY: data['total']!.toDouble(),
              color: Colors.blue.withOpacity(0.5),
              width: 12,
              borderRadius: BorderRadius.circular(4),
            ),
            BarChartRodData(
              toY: data['done']!.toDouble(),
              color: Colors.green,
              width: 12,
              borderRadius: BorderRadius.circular(4),
            ),
          ],
        ),
      );
      i++;
    });

    double maxY = 0;
    for (var group in barGroups) {
      for (var rod in group.barRods) {
        if (rod.toY > maxY) maxY = rod.toY;
      }
    }
    maxY = maxY == 0 ? 5 : maxY * 1.3; 

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(icon: const Icon(Icons.chevron_left), onPressed: () => setState(() { _selectedReportMonth = DateTime(_selectedReportMonth.year, _selectedReportMonth.month - 1); })),
            Text(DateFormat('MMMM yyyy', 'tr_TR').format(_selectedReportMonth), style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textColor)),
            IconButton(icon: const Icon(Icons.chevron_right), onPressed: () => setState(() { _selectedReportMonth = DateTime(_selectedReportMonth.year, _selectedReportMonth.month + 1); })),
          ],
        ),
        const SizedBox(height: 10),
        AspectRatio(
          aspectRatio: 1.5,
          child: BarChart(
            BarChartData(
              maxY: maxY,
              barGroups: barGroups,
              // --- TOOLTIP DÜZELTMESİ (tooltipBgColor) ---
              barTouchData: BarTouchData(
                enabled: false, 
                touchTooltipData: BarTouchTooltipData(
                  tooltipBgColor: Colors.transparent, 
                  tooltipPadding: EdgeInsets.zero,
                  tooltipMargin: 4, 
                  getTooltipItem: (group, groupIndex, rod, rodIndex) {
                    return BarTooltipItem(
                      rod.toY.toInt().toString(), 
                      TextStyle(color: rod.color, fontWeight: FontWeight.bold, fontSize: 10),
                    );
                  },
                ),
              ),
              gridData: FlGridData(show: true, drawVerticalLine: false, getDrawingHorizontalLine: (value) => FlLine(color: Colors.grey.withOpacity(0.1))),
              borderData: FlBorderData(show: false),
              titlesData: FlTitlesData(
                leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      if (value.toInt() < names.length) {
                        return Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(names[value.toInt()], style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                        );
                      }
                      return const Text('');
                    },
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(width: 12, height: 12, color: Colors.blue.withOpacity(0.5)),
            const SizedBox(width: 5),
            const Text("Atanan", style: TextStyle(fontSize: 12)),
            const SizedBox(width: 20),
            Container(width: 12, height: 12, color: Colors.green),
            const SizedBox(width: 5),
            const Text("Tamamlanan", style: TextStyle(fontSize: 12)),
          ],
        )
      ],
    );
  }

  // B. DETAYLI PERSONEL LİSTESİ
 Widget _buildDetailedTeamStats(TaskProvider provider, bool isDark, Color cardColor, Color textColor, Color subTextColor) {
    List<TeamMember> members = List.from(provider.teamMembers);
    members.add(TeamMember(id: "unassigned", name: "Ortak Havuz", role: "system"));
    
    // Ekran genişliğini alıyoruz
    double width = MediaQuery.of(context).size.width;
    
    // Genişliğe göre kaç sütun olacağına karar veriyoruz
    int crossAxisCount = 1;
    if (width > 1200) {
      crossAxisCount = 3; // Geniş Web: 3 yan yana
    } else if (width > 800) {
      crossAxisCount = 2; // Tablet / Dar Web: 2 yan yana
    }
    // Telefon: 1 (Alt alta)

    return GridView.builder(
      shrinkWrap: true, // Scroll hatasını önler
      physics: const NeverScrollableScrollPhysics(), // Ana sayfanın scroll'unu kullanır
      itemCount: members.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        childAspectRatio: crossAxisCount == 1 ? 2.2 : 1.8, // Kartın en/boy oranı (Kartın sığması için önemli)
        crossAxisSpacing: 15, // Yatay boşluk
        mainAxisSpacing: 15,  // Dikey boşluk
      ),
      itemBuilder: (context, index) {
        final member = members[index];
        final isHavuz = member.id == "unassigned";

        final memberTasks = provider.tasks.where((t) {
          if (isHavuz) return t.assignedMemberId == null;
          return t.assignedMemberId == member.id;
        }).toList();

        final total = memberTasks.length;
        final completed = memberTasks.where((t) => t.isDone).length;
        final active = total - completed;
        final double progress = total == 0 ? 0.0 : (completed / total);

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(16),
            border: isDark ? Border.all(color: Colors.white10) : null,
            boxShadow: isDark ? [] : [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 2))]
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center, // İçeriği dikey ortala
            children: [
              // ÜST KISIM: İsim ve Yüzde
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: isHavuz ? Colors.orange.withOpacity(0.2) : Colors.blue.withOpacity(0.2),
                    radius: 20, // Biraz küçülttük
                    child: isHavuz 
                      ? const Icon(Icons.layers, color: Colors.orange, size: 20)
                      : Text(member.name.isNotEmpty ? member.name[0].toUpperCase() : "?", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue, fontSize: 14)),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(member.name, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: textColor), overflow: TextOverflow.ellipsis),
                        Text(isHavuz ? "Sahipsiz" : (member.role == 'admin' ? "Yönetici" : "Editör"), style: TextStyle(fontSize: 11, color: subTextColor)),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text("%${(progress * 100).toInt()}", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: textColor)),
                    ],
                  )
                ],
              ),
              
              const Spacer(), // Araya esnek boşluk
              
              // PROGRESS BAR
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 6,
                  backgroundColor: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
                  valueColor: AlwaysStoppedAnimation<Color>(isHavuz ? Colors.orange : (progress == 1.0 ? Colors.green : Colors.blue)),
                ),
              ),
              
              const Spacer(), // Araya esnek boşluk

              // ALT KISIM: İstatistik Kutucukları
              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                      decoration: BoxDecoration(color: Colors.orange.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                      child: Row(
                        children: [
                          const Icon(Icons.hourglass_empty, size: 14, color: Colors.orange),
                          const SizedBox(width: 6),
                          Text("Aktif: $active", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: textColor)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                      decoration: BoxDecoration(color: Colors.green.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                      child: Row(
                        children: [
                          const Icon(Icons.check_circle, size: 14, color: Colors.green),
                          const SizedBox(width: 6),
                          Text("Biten: $completed", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: textColor)),
                        ],
                      ),
                    ),
                  ),
                ],
              )
            ],
          ),
        );
      },
    );
  }

  // C. İŞ YÜKÜ (PASTA)
  Widget _buildWorkloadChart(List<Task> tasks, TaskProvider provider, bool isDark, Color textColor) {
    Map<String, int> workloadMap = {};
    workloadMap["unassigned"] = 0;
    for (var member in provider.teamMembers) { workloadMap[member.id] = 0; }

    for (var task in tasks) {
      if (!task.isDone) {
        if (task.assignedMemberId == null) {
          workloadMap["unassigned"] = (workloadMap["unassigned"] ?? 0) + 1;
        } else if (workloadMap.containsKey(task.assignedMemberId)) {
          workloadMap[task.assignedMemberId!] = (workloadMap[task.assignedMemberId!] ?? 0) + 1;
        }
      }
    }

    var activeLoad = workloadMap.entries.where((e) => e.value > 0).toList();

    if (activeLoad.isEmpty) return const Center(child: Text("Şu an bekleyen iş yok! Herkes rahat. 🎉", style: TextStyle(color: Colors.grey)));

    List<Color> colors = [Colors.blue, Colors.red, Colors.orange, Colors.purple, Colors.teal, Colors.pink, Colors.green];

    return Row(
      children: [
        Expanded(
          flex: 3,
          child: PieChart(
            PieChartData(
              pieTouchData: PieTouchData(touchCallback: (FlTouchEvent event, pieTouchResponse) {
                  setState(() {
                    if (!event.isInterestedForInteractions || pieTouchResponse == null || pieTouchResponse.touchedSection == null) {
                      _workloadTouchedIndex = -1; return;
                    }
                    _workloadTouchedIndex = pieTouchResponse.touchedSection!.touchedSectionIndex;
                  });
                }),
              borderData: FlBorderData(show: false), sectionsSpace: 2, centerSpaceRadius: 40,
              sections: activeLoad.asMap().entries.map((entry) {
                int index = entry.key; String memberId = entry.value.key; int count = entry.value.value;
                final isTouched = index == _workloadTouchedIndex;
                final double radius = isTouched ? 60.0 : 50.0; final double fontSize = isTouched ? 18.0 : 14.0;
                Color color = memberId == "unassigned" ? Colors.grey : colors[index % colors.length];
                return PieChartSectionData(color: color, value: count.toDouble(), title: '$count', radius: radius, titleStyle: TextStyle(fontSize: fontSize, fontWeight: FontWeight.bold, color: Colors.white));
              }).toList(),
            ),
          ),
        ),
        const SizedBox(width: 20),
        Expanded(
          flex: 2,
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start,
              children: activeLoad.asMap().entries.map((entry) {
                int index = entry.key; String memberId = entry.value.key;
                String name = memberId == "unassigned" ? "Havuz" : (provider.getMemberName(memberId) ?? "Bilinmeyen");
                Color color = memberId == "unassigned" ? Colors.grey : colors[index % colors.length];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Row(children: [Container(width: 12, height: 12, decoration: BoxDecoration(color: color, shape: BoxShape.circle)), const SizedBox(width: 8), Expanded(child: Text(name, style: TextStyle(fontSize: 12, color: textColor, fontWeight: FontWeight.w500), overflow: TextOverflow.ellipsis))]),
                );
              }).toList(),
            ),
          ),
        )
      ],
    );
  }

  // D. ÖZET KART
  Widget _buildSummaryCard(String title, String value, IconData icon, Color color, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? Colors.grey.shade900 : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: isDark ? [] : [BoxShadow(color: color.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 4))],
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

  // E. HAFTALIK GRAFİK
  Widget _buildWeeklyChart(List<Task> tasks, ThemeProvider theme, bool isDark) {
    List<FlSpot> spots = [];
    DateTime now = DateTime.now();
    DateTime todayMidnight = DateTime(now.year, now.month, now.day);
    List<int> dailyCounts = List.filled(7, 0);

    for (var task in tasks) {
      if (task.isDone && task.dueDate != null) {
        DateTime taskMidnight = DateTime(task.dueDate!.year, task.dueDate!.month, task.dueDate!.day);
        int daysDiff = todayMidnight.difference(taskMidnight).inDays;
        if (daysDiff >= 0 && daysDiff < 7) {
          dailyCounts[6 - daysDiff]++;
        }
      }
    }

    for (int i = 0; i < 7; i++) {
      spots.add(FlSpot(i.toDouble(), dailyCounts[i].toDouble()));
    }

    double maxY = (dailyCounts.reduce((curr, next) => curr > next ? curr : next)).toDouble();
    if (maxY == 0) maxY = 4; else maxY += 1;

    return LineChart(
      LineChartData(
        gridData: FlGridData(show: true, drawVerticalLine: false, getDrawingHorizontalLine: (value) => FlLine(color: isDark ? Colors.white10 : Colors.grey.shade200, strokeWidth: 1)),
        titlesData: FlTitlesData(
          show: true,
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 30, interval: 1, getTitlesWidget: (value, meta) {
                DateTime day = DateTime.now().subtract(Duration(days: 6 - value.toInt()));
                String text = DateFormat('E', 'tr_TR').format(day);
                return SideTitleWidget(axisSide: meta.axisSide, child: Text(text, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)));
              })),
          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        minX: 0, maxX: 6, minY: 0, maxY: maxY,
        lineBarsData: [
          LineChartBarData(
            spots: spots, isCurved: true, gradient: LinearGradient(colors: [theme.primaryColor, theme.secondaryColor]),
            barWidth: 4, isStrokeCapRound: true, dotData: FlDotData(show: true),
            belowBarData: BarAreaData(show: true, gradient: LinearGradient(colors: [theme.primaryColor.withOpacity(0.3), theme.secondaryColor.withOpacity(0.0)], begin: Alignment.topCenter, end: Alignment.bottomCenter)),
          ),
        ],
      ),
    );
  }

  // F. LİDERLİK TABLOSU
  Widget _buildTeamLeaderboard(List<Task> tasks, TaskProvider provider, bool isDark, Color cardColor, Color textColor) {
    Map<String, int> memberScores = {};
    for (var member in provider.teamMembers) { memberScores[member.id] = 0; }
    for (var task in tasks) {
      if (task.isDone && task.assignedMemberId != null) {
        if (memberScores.containsKey(task.assignedMemberId)) {
          memberScores[task.assignedMemberId!] = memberScores[task.assignedMemberId!]! + 1;
        }
      }
    }
    var sortedEntries = memberScores.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    if (sortedEntries.isEmpty) return const Center(child: Text("Henüz ekip aktivitesi yok.", style: TextStyle(color: Colors.grey)));

    return Column(
      children: sortedEntries.asMap().entries.map((entry) {
        int index = entry.key; String memberId = entry.value.key; int score = entry.value.value;
        String name = provider.getMemberName(memberId) ?? "Bilinmeyen";
        bool isTop3 = index < 3;
        Color rankColor = index == 0 ? const Color(0xFFFFD700) : (index == 1 ? const Color(0xFFC0C0C0) : (index == 2 ? const Color(0xFFCD7F32) : Colors.grey));

        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(15), border: isTop3 ? Border.all(color: rankColor, width: 1.5) : null),
          child: Row(
            children: [
              Container(width: 30, height: 30, alignment: Alignment.center, decoration: BoxDecoration(shape: BoxShape.circle, color: isTop3 ? rankColor.withOpacity(0.2) : Colors.grey.withOpacity(0.1)), child: Text("${index + 1}", style: TextStyle(fontWeight: FontWeight.bold, color: isTop3 ? rankColor : Colors.grey))),
              const SizedBox(width: 15),
              Expanded(child: Text(name, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: textColor))),
              Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), decoration: BoxDecoration(color: isDark ? Colors.grey.shade800 : Colors.grey.shade100, borderRadius: BorderRadius.circular(20)), child: Row(children: [const Icon(Icons.check_circle, size: 14, color: Colors.green), const SizedBox(width: 6), Text("$score", style: TextStyle(fontWeight: FontWeight.bold, color: textColor))]))
            ],
          ),
        );
      }).toList(),
    );
  }
}