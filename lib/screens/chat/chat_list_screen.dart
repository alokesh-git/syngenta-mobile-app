import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme.dart';

import '../../providers/auth_provider.dart';
import '../../providers/chat_provider.dart';
import '../../models/farmer_model.dart';
import 'chat_screen.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final uid = context.read<AuthProvider>().user?.uid ?? 'demo_user';
      context.read<ChatProvider>().loadChatRooms(uid);
    });
  }

  List<_MockChat> get _mockChats => [
        _MockChat(
          name: 'Rajesh Kumar',
          lastMessage: 'Yes I have extra DAP, come today',
          time: '2 min ago',
          isOnline: true,
          crop: 'Wheat',
        ),
        _MockChat(
          name: 'Suresh Patil',
          lastMessage: 'Which pesticide for bollworm?',
          time: '1 hr ago',
          isOnline: false,
          crop: 'Cotton',
        ),
        _MockChat(
          name: 'Murugan S.',
          lastMessage: 'Thanks for the SCORE advice!',
          time: 'Yesterday',
          isOnline: false,
          crop: 'Rice',
        ),
        _MockChat(
          name: 'Ramesh Singh',
          lastMessage: 'Blast attack in my field too',
          time: '2 days ago',
          isOnline: true,
          crop: 'Rice',
        ),
      ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(
        title: Text('chat_title'.tr(),
            style: const TextStyle(color: Colors.white)),
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: Colors.white),
            onPressed: () {},
          ),
        ],
      ),
      body: ListView.separated(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: _mockChats.length,
        separatorBuilder: (_, __) => const Divider(height: 1, indent: 72),
        itemBuilder: (context, i) {
          final chat = _mockChats[i];
          return ListTile(
            leading: Stack(
              children: [
                CircleAvatar(
                  radius: 26,
                  backgroundColor: AppTheme.primary.withOpacity(0.15),
                  child: Text(
                    chat.name[0],
                    style: const TextStyle(
                      color: AppTheme.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
                  ),
                ),
                if (chat.isOnline)
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: AppTheme.success,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                    ),
                  ),
              ],
            ),
            title: Row(
              children: [
                Text(
                  chat.name,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppTheme.surface,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    chat.crop,
                    style: const TextStyle(
                        color: AppTheme.primary,
                        fontSize: 10,
                        fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
            subtitle: Text(
              chat.lastMessage,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13),
            ),
            trailing: Text(
              chat.time,
              style: const TextStyle(
                  color: AppTheme.textSecondary, fontSize: 11),
            ),
            onTap: () {
              final mockFarmer = FarmerModel(
                uid: 'mock_${chat.name.hashCode}',
                name: chat.name,
                crops: [chat.crop.toLowerCase()],
                isOnline: chat.isOnline,
                createdAt: DateTime.now(),
              );
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ChatScreen(
                    chatRoomId: 'chat_${chat.name.hashCode}',
                    otherFarmer: mockFarmer,
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _MockChat {
  final String name;
  final String lastMessage;
  final String time;
  final bool isOnline;
  final String crop;

  _MockChat({
    required this.name,
    required this.lastMessage,
    required this.time,
    required this.isOnline,
    required this.crop,
  });
}
