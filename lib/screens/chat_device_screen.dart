import 'package:ai_assistent_bluetooth/cubit/chat/chat_cubit.dart';
import 'package:ai_assistent_bluetooth/cubit/chat/chat_state.dart';
import 'package:ai_assistent_bluetooth/cubit/scan/scan_cubit.dart';
import 'package:ai_assistent_bluetooth/models/chat_message.dart';
import 'package:ai_assistent_bluetooth/screens/dashboard_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

class DeviceChatView extends StatefulWidget {
  const DeviceChatView({super.key});

  @override
  State<DeviceChatView> createState() => _DeviceChatViewState();
}

class _DeviceChatViewState extends State<DeviceChatView> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  Widget _buildChatList(List<ChatMessage> messages) {
    // Group messages by date for better organization
    if (messages.isEmpty) {
      return const Center(
        child: Text(
          'Nessun messaggio',
          style: TextStyle(
            color: Colors.grey,
            fontSize: 16,
          ),
        ),
      );
    }

    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      itemCount: messages.length,
      itemBuilder: (context, index) {
        final msg = messages[index];
        final bool showAvatar = !msg.isSentByUser;
        
        // Check if we need to show timestamp
        // final bool showTimestamp = index == 0 || 
        //     index == messages.length - 1 ||
        //     messages[index].timestamp.day != messages[index - 1].timestamp.day;
        
        return Column(
          children: [
            // if (showTimestamp) _buildDateDivider(msg.timestamp),
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                mainAxisAlignment: msg.isSentByUser
                    ? MainAxisAlignment.end
                    : MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (showAvatar) ...[
                    const CircleAvatar(
                      radius: 16,
                      backgroundColor: Colors.blue,
                      child: Icon(
                        Icons.device_unknown,
                        size: 16,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  Flexible(
                    child: Container(
                      constraints: BoxConstraints(
                        maxWidth: MediaQuery.of(context).size.width * 0.75,
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: msg.isSentByUser
                            ? Theme.of(context).primaryColor
                            : Theme.of(context).brightness == Brightness.dark
                                ? Colors.grey[800]
                                : Colors.grey[200],
                        borderRadius: BorderRadius.circular(20).copyWith(
                          bottomLeft: msg.isSentByUser
                              ? const Radius.circular(20)
                              : const Radius.circular(0),
                          bottomRight: !msg.isSentByUser
                              ? const Radius.circular(20)
                              : const Radius.circular(0),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            msg.message,
                            style: TextStyle(
                              color: msg.isSentByUser
                                  ? Colors.white
                                  : Theme.of(context).textTheme.bodyLarge?.color,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            // DateFormat('HH:mm').format(msg.timestamp),
                            "data",
                            style: TextStyle(
                              color: msg.isSentByUser
                                  ? Colors.white.withOpacity(0.7)
                                  : Colors.grey[600],
                              fontSize: 12,
                            ),
                            textAlign: TextAlign.right,
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (!showAvatar) const SizedBox(width: 40),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDateDivider(DateTime timestamp) {
    final now = DateTime.now();
    String dateText;
    
    if (timestamp.year == now.year && 
        timestamp.month == now.month && 
        timestamp.day == now.day) {
      dateText = 'Oggi';
    } else if (timestamp.year == now.year && 
               timestamp.month == now.month && 
               timestamp.day == now.day - 1) {
      dateText = 'Ieri';
    } else {
      dateText = DateFormat('d MMMM yyyy').format(timestamp);
    }
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        children: [
          const Expanded(child: Divider()),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              dateText,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const Expanded(child: Divider()),
        ],
      ),
    );
  }

  Widget _buildMessageInput(ChatCubit cubit) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[900] : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: isDark ? Colors.grey[800] : Colors.grey[100],
                borderRadius: BorderRadius.circular(24),
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(
                      Icons.emoji_emotions_outlined,
                      color: theme.iconTheme.color?.withOpacity(0.6),
                    ),
                    onPressed: () {
                      // TODO: Implement emoji picker
                    },
                  ),
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      maxLines: 5,
                      minLines: 1,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: const InputDecoration(
                        hintText: "Scrivi un messaggio...",
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(vertical: 12),
                      ),
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.attach_file,
                      color: theme.iconTheme.color?.withOpacity(0.6),
                    ),
                    onPressed: () {
                      // TODO: Implement file attachment
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            decoration: BoxDecoration(
              color: theme.primaryColor,
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(
                Icons.send_rounded,
                color: Colors.white,
              ),
              onPressed: () {
                String text = _controller.text.trim();
                if (text.isNotEmpty) {
                  cubit.sendMessage(text);
                  _controller.clear();
                  _scrollToBottom();
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConnectionStatus(bool isConnected, bool isWaitingForAi) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      height: isConnected ? 0 : 36,
      color: isConnected ? Colors.green : Colors.orange,
      child: Center(
        child: Text(
          isConnected ? "" : "Connessione in corso...",
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ChatCubit, ChatState>(
      builder: (context, state) {
        return Scaffold(
          appBar: AppBar(
            elevation: 1,
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  // state.deviceName.isNotEmpty ? state.deviceName : "Dispositivo",
                  "Nome dispositivo",
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  state.isConnected ? "Connesso" : "Connessione in corso...",
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.more_vert),
                onPressed: () {
                  showModalBottomSheet(
                    context: context,
                    builder: (context) => Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ListTile(
                          leading: const Icon(Icons.refresh),
                          title: const Text("Riconnetti"),
                          onTap: () {
                            // context.read<ChatCubit>().reconnect();
                            Navigator.pop(context);
                          },
                        ),
                        ListTile(
                          leading: const Icon(Icons.delete_outline, color: Colors.red),
                          title: const Text("Cancella chat", style: TextStyle(color: Colors.red)),
                          onTap: () {
                            // context.read<ChatCubit>().clearChat();
                            Navigator.pop(context);
                          },
                        ),
                        ListTile(
                          leading: const Icon(Icons.cancel, color: Colors.red),
                          title: const Text("Disconnetti", style: TextStyle(color: Colors.red)),
                          onTap: () async {
                            await context.read<ChatCubit>().disconnect();
                            await context.read<ScanCubit>().disconnectFromAllDevices();
                            Navigator.pop(context);
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(builder: (context) => const DashboardView()),
                            );
                          },
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
          body: SafeArea(
            child: Column(
              children: [
                _buildConnectionStatus(state.isConnected, state.isWaitingForAi),
                if(!state.isWaitingForAi)      
                Expanded(child: _buildChatList(state.messages)),
                if(!state.isWaitingForAi)
                _buildMessageInput(context.read<ChatCubit>()),
              ],
            ),
          ),
        );
      },
    );
  }
}