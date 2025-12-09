import 'package:flutter/material.dart';
import 'package:odak_list/models/team_member.dart';
import 'package:odak_list/screens/navigation_screen.dart';
import 'package:odak_list/services/database_service.dart';
import 'package:odak_list/task_provider.dart';
import 'package:provider/provider.dart';

class ProfileSelectScreen extends StatelessWidget {
  const ProfileSelectScreen({super.key});

  void _onProfileTap(BuildContext context, TeamMember member) {
    if (member.profilePin != null && member.profilePin!.isNotEmpty) {
      _showPinDialog(context, member);
    } else {
      _enterApp(context, member);
    }
  }

  void _showPinDialog(BuildContext context, TeamMember member) {
    final pinCheckController = TextEditingController();
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: Column(
          children: [
            const Icon(Icons.lock, size: 40, color: Colors.blue),
            const SizedBox(height: 10),
            Text("${member.name} Girişi"),
          ],
        ),
        content: TextField(
          controller: pinCheckController,
          autofocus: true,
          obscureText: true,
          keyboardType: TextInputType.number,
          maxLength: 4,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 24, letterSpacing: 8),
          decoration: const InputDecoration(hintText: "****", counterText: ""),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("İptal")),
          ElevatedButton(
            onPressed: () {
              if (pinCheckController.text == member.profilePin) {
                Navigator.pop(ctx);
                _enterApp(context, member);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Hatalı Şifre!"), backgroundColor: Colors.red),
                );
                pinCheckController.clear();
              }
            },
            child: const Text("Giriş"),
          )
        ],
      ),
    );
  }

  void _enterApp(BuildContext context, TeamMember member) {
    Provider.of<TaskProvider>(context, listen: false).selectMember(member);
    Navigator.pushReplacement(
      context, 
      MaterialPageRoute(builder: (_) => NavigationScreen(dbService: DatabaseService()))
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Kim İzliyor?"),
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      body: StreamBuilder<List<TeamMember>>(
        stream: DatabaseService().getTeamMembersStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final members = snapshot.data ?? [];

          // WEB UYUMLULUĞU: İçeriği Ortala ve Genişliği Sınırla
          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600), // Web'de maksimum 600px
              child: GridView.builder(
                padding: const EdgeInsets.all(40),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 30,
                  mainAxisSpacing: 30,
                  childAspectRatio: 0.9, // Kartların oranını biraz daha kareye yakın tut
                ),
                itemCount: members.length, 
                itemBuilder: (context, index) {
                  final member = members[index];
                  final hasPin = member.profilePin != null && member.profilePin!.isNotEmpty;

                  return GestureDetector(
                    onTap: () => _onProfileTap(context, member),
                    child: Container(
                      decoration: BoxDecoration(
                        color: member.role == 'admin' ? Colors.blue.shade50 : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: member.role == 'admin' ? Colors.blue : Colors.grey.shade300, width: 2),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 15, offset: const Offset(0, 8))
                        ]
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Stack(
                            children: [
                              CircleAvatar(
                                radius: 40,
                                backgroundColor: member.role == 'admin' ? Colors.blue : Colors.orange,
                                child: Text(
                                  member.name.isNotEmpty ? member.name[0].toUpperCase() : "?", 
                                  style: const TextStyle(fontSize: 32, color: Colors.white, fontWeight: FontWeight.bold)
                                ),
                              ),
                              if (hasPin)
                                const Positioned(
                                  right: 0, bottom: 0,
                                  child: CircleAvatar(radius: 14, backgroundColor: Colors.white, child: Icon(Icons.lock, size: 18, color: Colors.black)),
                                )
                            ],
                          ),
                          const SizedBox(height: 20),
                          Text(member.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20), textAlign: TextAlign.center),
                          const SizedBox(height: 5),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: member.role == 'admin' ? Colors.blue.withOpacity(0.1) : Colors.orange.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10)
                            ),
                            child: Text(member.role == 'admin' ? "Yönetici" : "Editör", style: TextStyle(color: member.role == 'admin' ? Colors.blue : Colors.orange, fontSize: 12, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }
}