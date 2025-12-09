import 'package:flutter/material.dart';
import 'package:odak_list/models/task.dart';
import 'package:odak_list/screens/task_detail_screen.dart';
import 'package:odak_list/services/database_service.dart';
import 'package:odak_list/task_provider.dart';
import 'package:odak_list/widgets/task_card.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:odak_list/theme_provider.dart'; // EKLENDİ

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

  // Güne göre görevleri filtrele
  List<Task> _getTasksForDay(DateTime day, List<Task> allTasks) {
    return allTasks.where((task) {
      if (task.dueDate == null) return false;
      return isSameDay(task.dueDate, day);
    }).toList();
  }

  void _navigateToDetail(Task task) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => TaskDetailScreen(task: task, dbService: widget.dbService)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Consumer<TaskProvider>(
      builder: (context, taskProvider, child) {
        final allTasks = taskProvider.tasks;
        final selectedEvents = _getTasksForDay(_selectedDay ?? _focusedDay, allTasks);

        return Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          body: Center( // WEB İÇİN ORTALAMA
            child: ConstrainedBox( // GENİŞLİK SINIRLAMASI
              constraints: const BoxConstraints(maxWidth: 1000),
              child: SafeArea( 
                child: Column(
                  children: [
                    // --- TAKVİM KISMI (KART) ---
                    Container(
                      margin: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          if (!isDarkMode)
                            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))
                        ]
                      ),
                      child: TableCalendar<Task>(
                        firstDay: DateTime.utc(2020, 10, 16),
                        lastDay: DateTime.utc(2030, 3, 14),
                        focusedDay: _focusedDay,
                        calendarFormat: _calendarFormat,
                        
                        eventLoader: (day) => _getTasksForDay(day, allTasks),
                        
                        selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                        onDaySelected: (selectedDay, focusedDay) {
                          setState(() {
                            _selectedDay = selectedDay;
                            _focusedDay = focusedDay;
                          });
                        },
                        onFormatChanged: (format) {
                          if (_calendarFormat != format) {
                            setState(() => _calendarFormat = format);
                          }
                        },
                        onPageChanged: (focusedDay) {
                          _focusedDay = focusedDay;
                        },
                        calendarStyle: CalendarStyle(
                          markerDecoration: BoxDecoration(color: themeProvider.primaryColor, shape: BoxShape.circle),
                          todayDecoration: BoxDecoration(color: themeProvider.secondaryColor.withOpacity(0.5), shape: BoxShape.circle),
                          selectedDecoration: BoxDecoration(color: themeProvider.secondaryColor, shape: BoxShape.circle),
                        ),
                        headerStyle: const HeaderStyle(
                          formatButtonVisible: false,
                          titleCentered: true,
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 8.0),
                    
                    // --- LİSTE KISMI (BEYAZ ARKA PLAN) ---
                    Expanded(
                      child: Container(
                        width: double.infinity,
                        // BURASI: Takvimin altındaki listenin arka planını beyaz yapıyoruz
                        decoration: BoxDecoration(
                          color: isDarkMode ? Colors.black26 : Colors.white, 
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
                          boxShadow: [
                            if (!isDarkMode)
                              BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5))
                          ]
                        ),
                        child: selectedEvents.isEmpty
                            ? Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.event_note, size: 60, color: Colors.grey.withOpacity(0.3)),
                                    const SizedBox(height: 10),
                                    Text("Bugün için planlanmış görev yok.", style: TextStyle(color: Colors.grey.shade500, fontSize: 16)),
                                  ],
                                ),
                              )
                            : ListView.builder(
                                padding: const EdgeInsets.all(20),
                                itemCount: selectedEvents.length,
                                itemBuilder: (context, index) {
                                  final task = selectedEvents[index];
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 12.0),
                                    child: TaskCard(
                                      task: task,
                                      categories: const {}, 
                                      onTap: () => _navigateToDetail(task),
                                      onToggleDone: () {
                                        if (taskProvider.canCompleteTask(task)) {
                                          taskProvider.toggleTaskStatus(task);
                                        } else {
                                           String ownerName = taskProvider.getMemberName(task.assignedMemberId) ?? "Başkası";
                                           ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(content: Text("Bu görev $ownerName kişisine ait."), backgroundColor: Colors.red)
                                           );
                                        }
                                      },
                                    ),
                                  );
                                },
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}