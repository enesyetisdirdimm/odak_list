import 'package:flutter/material.dart';
import 'package:odak_list/models/task.dart';
import 'package:odak_list/screens/task_detail_screen.dart';
import 'package:odak_list/services/database_service.dart';
import 'package:odak_list/services/notification_service.dart';
import 'package:odak_list/theme_provider.dart';
import 'package:odak_list/utils/app_colors.dart';
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
  
  List<Task> _allTasks = [];
  // Seçilen güne ait görevleri tutacak liste
  ValueNotifier<List<Task>> _selectedEvents = ValueNotifier([]);

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    _loadTasks();
  }

  Future<void> _loadTasks() async {
    final tasks = await widget.dbService.getTasks();
    setState(() {
      _allTasks = tasks;
      _selectedEvents.value = _getTasksForDay(_selectedDay!);
    });
  }

  // Belirli bir güne ait görevleri filtreleyen fonksiyon
  List<Task> _getTasksForDay(DateTime day) {
    return _allTasks.where((task) {
      if (task.dueDate == null) return false;
      return isSameDay(task.dueDate, day);
    }).toList();
  }

  Future<void> _toggleTaskStatus(Task task) async {
    task.isDone = !task.isDone;
    await widget.dbService.updateTask(task);
    _loadTasks(); // Listeyi yenile
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
    _loadTasks();
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.themeMode == ThemeMode.dark;
    final textColor = isDarkMode ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final bgColor = Theme.of(context).scaffoldBackgroundColor;

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Column(
          children: [
            // --- TAKVİM BÖLÜMÜ ---
            Container(
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(20),
                boxShadow: isDarkMode ? [] : [
                  BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))
                ],
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
                  // Bugünün Yuvarlağı
                  todayDecoration: BoxDecoration(
                    color: themeProvider.secondaryColor.withOpacity(0.5),
                    shape: BoxShape.circle,
                  ),
                  // Seçili Günün Yuvarlağı
                  selectedDecoration: BoxDecoration(
                    color: themeProvider.secondaryColor,
                    shape: BoxShape.circle,
                  ),
                  // Görevi olan günlerdeki NOKTA (Marker)
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
                    _selectedEvents.value = _getTasksForDay(selectedDay);
                  }
                },
                onFormatChanged: (format) {
                  if (_calendarFormat != format) setState(() => _calendarFormat = format);
                },
                onPageChanged: (focusedDay) {
                  _focusedDay = focusedDay;
                },
                // Markerları (Noktaları) yükleyen kısım
                eventLoader: _getTasksForDay,
              ),
            ),

            const SizedBox(height: 10),
            
            // --- SEÇİLİ GÜNÜN GÖREVLERİ ---
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

            Expanded(
              child: ValueListenableBuilder<List<Task>>(
                valueListenable: _selectedEvents,
                builder: (context, value, _) {
                  if (value.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.event_busy, size: 50, color: Colors.grey.withOpacity(0.5)),
                          const SizedBox(height: 10),
                          const Text("Bugün için planlanmış görev yok.", style: TextStyle(color: Colors.grey)),
                        ],
                      ),
                    );
                  }
                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: value.length,
                    itemBuilder: (context, index) {
                      final task = value[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12.0),
                        child: TaskCard(
                          task: task,
                          // Kategorileri artık kullanmıyoruz ama TaskCard istiyor, boş yollayalım
                          categories: const {}, 
                          onTap: () => _navigateToDetail(task),
                          onToggleDone: () => _toggleTaskStatus(task),
                        ),
                      );
                    },
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