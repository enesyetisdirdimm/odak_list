import 'package:flutter/material.dart';
import 'package:odak_list/models/task.dart';
import 'package:odak_list/screens/task_detail_screen.dart';
import 'package:odak_list/services/database_service.dart';
import 'package:odak_list/task_provider.dart';
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
    return Consumer<TaskProvider>(
      builder: (context, taskProvider, child) {
        final allTasks = taskProvider.tasks;
        
        final selectedEvents = _getTasksForDay(_selectedDay ?? _focusedDay, allTasks);

        return Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          // --- BURASI DÜZELTİLDİ: SafeArea eklendi ---
          body: SafeArea( 
            child: Column(
              children: [
                TableCalendar<Task>(
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
                    markerDecoration: BoxDecoration(color: Theme.of(context).primaryColor, shape: BoxShape.circle),
                    todayDecoration: BoxDecoration(color: Colors.blueAccent.withOpacity(0.5), shape: BoxShape.circle),
                    selectedDecoration: BoxDecoration(color: Theme.of(context).primaryColor, shape: BoxShape.circle),
                  ),
                ),
                const SizedBox(height: 8.0),
                
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
                                categories: const {}, 
                                onTap: () => _navigateToDetail(task),
                                onToggleDone: () {
                                  // AYNI KONTROL BURADA DA VAR
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
              ],
            ),
          ),
        );
      },
    );
  }
}