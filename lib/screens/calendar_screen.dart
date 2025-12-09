import 'package:flutter/material.dart';
import 'package:odak_list/models/task.dart';
import 'package:odak_list/screens/task_detail_screen.dart';
import 'package:odak_list/services/database_service.dart';
import 'package:odak_list/task_provider.dart';
import 'package:odak_list/widgets/task_card.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:odak_list/theme_provider.dart';
import 'package:odak_list/utils/app_colors.dart';

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
    final isDarkMode = themeProvider.themeMode == ThemeMode.dark;

    return Consumer<TaskProvider>(
      builder: (context, taskProvider, child) {
        final allTasks = taskProvider.tasks;
        final selectedEvents = _getTasksForDay(_selectedDay ?? _focusedDay, allTasks);

        return Scaffold(
          // 1. ARKA PLAN TAMAMEN BEYAZ
          backgroundColor: isDarkMode ? AppColors.backgroundDark : Colors.white,
          
          body: Align( // Center yerine Align kullanıyoruz (Dikeyde esnemesi için)
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1000), // Web genişlik sınırı
              child: SafeArea( 
                child: Column(
                  children: [
                    // --- TAKVİM ALANI ---
                    Container(
                      margin: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.grey.withOpacity(0.1)),
                        boxShadow: [
                          if (!isDarkMode)
                            BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))
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
                        
                        // Takvim Stili
                        calendarStyle: CalendarStyle(
                          markerDecoration: BoxDecoration(color: themeProvider.primaryColor, shape: BoxShape.circle),
                          todayDecoration: BoxDecoration(color: themeProvider.secondaryColor.withOpacity(0.5), shape: BoxShape.circle),
                          selectedDecoration: BoxDecoration(color: themeProvider.secondaryColor, shape: BoxShape.circle),
                          defaultTextStyle: TextStyle(color: isDarkMode ? Colors.white : Colors.black87),
                          weekendTextStyle: TextStyle(color: isDarkMode ? Colors.white70 : Colors.black54),
                        ),
                        headerStyle: HeaderStyle(
                          formatButtonVisible: false,
                          titleCentered: true,
                          titleTextStyle: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isDarkMode ? Colors.white : Colors.black87),
                          leftChevronIcon: Icon(Icons.chevron_left, color: isDarkMode ? Colors.white : Colors.black54),
                          rightChevronIcon: Icon(Icons.chevron_right, color: isDarkMode ? Colors.white : Colors.black54),
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 5),
                    
                    // --- GÖREV LİSTESİ BAŞLIĞI ---
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                      child: Row(
                        children: [
                          Text(
                            "Planlananlar", 
                            style: TextStyle(
                              fontSize: 16, 
                              fontWeight: FontWeight.bold, 
                              color: isDarkMode ? Colors.white70 : Colors.grey.shade700
                            )
                          ),
                          const SizedBox(width: 8),
                          if (selectedEvents.isNotEmpty)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(color: themeProvider.secondaryColor.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                              child: Text("${selectedEvents.length}", style: TextStyle(fontWeight: FontWeight.bold, color: themeProvider.secondaryColor)),
                            )
                        ],
                      ),
                    ),

                    // --- LİSTE ALANI (TAM BEYAZ & GÖRÜNÜR) ---
                    Expanded(
                      child: Container(
                        width: double.infinity,
                        // 2. LİSTE ARKA PLANI TAMAMEN BEYAZ
                        decoration: BoxDecoration(
                          color: isDarkMode ? AppColors.backgroundDark : Colors.white,
                          border: Border(top: BorderSide(color: Colors.grey.withOpacity(0.1))),
                        ),
                        child: selectedEvents.isEmpty
                            ? Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.event_available, size: 60, color: Colors.grey.withOpacity(0.1)),
                                    const SizedBox(height: 15),
                                    Text("Bugün için görev yok.", style: TextStyle(color: Colors.grey.shade400, fontSize: 16, fontWeight: FontWeight.w500)),
                                  ],
                                ),
                              )
                            : ListView.builder(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
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