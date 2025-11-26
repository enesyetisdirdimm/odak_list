import 'package:flutter/material.dart';
import 'package:odak_list/models/task.dart';
import 'package:odak_list/screens/task_detail_screen.dart';
import 'package:odak_list/services/database_service.dart';
import 'package:odak_list/theme_provider.dart';
import 'package:odak_list/task_provider.dart'; // YENİ: Veri Akışı
import 'package:odak_list/utils/app_colors.dart';
import 'package:odak_list/utils/app_styles.dart'; // Stil dosyası
import 'package:odak_list/widgets/task_card.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';

class CalendarScreen extends StatefulWidget {
  final DatabaseService dbService;
  const CalendarScreen({super.key, required this.dbService});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  
  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
  }

  // Belirli bir günün görevlerini Provider listesinden süzer
  List<Task> _getTasksForDay(DateTime day, List<Task> allTasks) {
    return allTasks.where((task) {
      if (task.dueDate == null) return false;
      return isSameDay(task.dueDate, day);
    }).toList();
  }

  void _navigateToDetail(Task task) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TaskDetailScreen(
          task: task,
          dbService: widget.dbService,
        ),
      ),
    );
    // Geri dönünce veriyi yenile (Provider sayesinde otomatik olacak ama garanti olsun)
    if(mounted) context.read<TaskProvider>().loadData();
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    // Veriyi anlık dinliyoruz (listen: true varsayılandır)
    final taskProvider = Provider.of<TaskProvider>(context); 
    
    final isDarkMode = themeProvider.themeMode == ThemeMode.dark;
    final textColor = isDarkMode ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final bgColor = Theme.of(context).scaffoldBackgroundColor;

    // Tüm görevleri al
    final allTasks = taskProvider.tasks;
    // Seçili günün görevlerini filtrele
    final selectedEvents = _getTasksForDay(_selectedDay!, allTasks);

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Column(
          children: [
            // --- TAKVİM ---
            Container(
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(20),
                boxShadow: isDarkMode ? [] : AppStyles.softShadow, // AppStyles kullanıldı
              ),
              child: TableCalendar<Task>(
                firstDay: DateTime.utc(2020, 1, 1),
                lastDay: DateTime.utc(2030, 12, 31),
                focusedDay: _focusedDay,
                calendarFormat: _calendarFormat,
                
                // Stil Ayarları
                headerStyle: HeaderStyle(
                  titleCentered: true,
                  formatButtonVisible: false,
                  titleTextStyle: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor),
                  leftChevronIcon: Icon(Icons.chevron_left, color: themeProvider.secondaryColor),
                  rightChevronIcon: Icon(Icons.chevron_right, color: themeProvider.secondaryColor),
                ),
                calendarStyle: CalendarStyle(
                  defaultTextStyle: TextStyle(color: textColor),
                  weekendTextStyle: TextStyle(color: textColor),
                  todayDecoration: BoxDecoration(
                    color: themeProvider.secondaryColor.withOpacity(0.5),
                    shape: BoxShape.circle,
                  ),
                  selectedDecoration: BoxDecoration(
                    color: themeProvider.secondaryColor,
                    shape: BoxShape.circle,
                  ),
                  markerDecoration: BoxDecoration(
                    color: isDarkMode ? Colors.white : themeProvider.primaryColor,
                    shape: BoxShape.circle,
                  ),
                ),

                // Mantık
                selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                onDaySelected: (selectedDay, focusedDay) {
                  if (!isSameDay(_selectedDay, selectedDay)) {
                    setState(() {
                      _selectedDay = selectedDay;
                      _focusedDay = focusedDay;
                    });
                  }
                },
                onFormatChanged: (format) {
                  if (_calendarFormat != format) setState(() => _calendarFormat = format);
                },
                onPageChanged: (focusedDay) {
                  _focusedDay = focusedDay;
                },
                // Takvim üzerindeki noktaları (marker) oluşturmak için listeyi veriyoruz
                eventLoader: (day) => _getTasksForDay(day, allTasks),
              ),
            ),

            const SizedBox(height: 10),
            
            // --- BAŞLIK ---
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "Seçili Günün Planı",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor),
                ),
              ),
            ),
            const SizedBox(height: 10),

            // --- LİSTE ---
            Expanded(
              child: selectedEvents.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.event_busy, size: 50, color: Colors.grey.withOpacity(0.5)),
                          const SizedBox(height: 10),
                          const Text("Bugün için planlanmış görev yok.", style: TextStyle(color: Colors.grey)),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                      itemCount: selectedEvents.length,
                      itemBuilder: (context, index) {
                        final task = selectedEvents[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12.0),
                          child: TaskCard(
                            task: task,
                            categories: const {}, // Kategoriler kullanılmıyor
                            onTap: () => _navigateToDetail(task),
                            onToggleDone: () {
                              // Provider üzerinden güncelleme yapıyoruz ki her yer haber alsın
                              taskProvider.toggleTaskStatus(task);
                            },
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}