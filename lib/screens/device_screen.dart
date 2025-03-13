// lib/screens/device_screen.dart
import 'package:ai_assistent_bluetooth/cubit/chat/chat_cubit.dart';
import 'package:ai_assistent_bluetooth/cubit/chat/chat_state.dart';
import 'package:ai_assistent_bluetooth/cubit/scan/scan_cubit.dart';
import 'package:ai_assistent_bluetooth/models/chat_message.dart';
import 'package:ai_assistent_bluetooth/screens/scan_screen.dart';
import 'package:ai_assistent_bluetooth/theme/app_theme.dart';
import 'package:ai_assistent_bluetooth/widgets/message_bubble.dart';
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

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ChatCubit, ChatState>(
      listener: (context, state) {
        // Scroll to bottom when new messages arrive
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _scrollToBottom();
        });
      },
      builder: (context, state) {
        return Scaffold(
          appBar: AppBar(
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  state.isConnected ? "Machine Assistant" : "Connecting...",
                  style: AppTheme.headingSmall.copyWith(color: Colors.white),
                ),
                Text(
                  state.machineStatus,
                  style: AppTheme.bodySmall.copyWith(color: Colors.white70),
                ),
              ],
            ),
            actions: [
              // IconButton(
              //   icon: const Icon(Icons.refresh),
              //   onPressed: () {
              //     // Refresh connection
              //     context.read<ChatCubit>().disconnect();
              //     final cubit = context.read<ChatCubit>();
              //     // Using reflection to access private method
              //     // In real app, you'd expose this method as public
              //     // cubit.connectAndDiscover();
              //   },
              //   tooltip: 'Refresh connection',
              // ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () async {
                  await context.read<ChatCubit>().disconnect();
                  await context.read<ScanCubit>().disconnectFromAllDevices();
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => const ScanView()),
                  );
                },
                tooltip: 'Disconnect',
              ),
            ],
          ),
          body: Column(
            children: [
              // Machine status card
              // if (state.machineData != null)
              //   MachineStatusCard(machineData: state.machineData!),
              
              // Chat messages
              Expanded(
                child: state.messages.isEmpty
                    ? _buildEmptyChat()
                    : _buildChatList(state.messages),
              ),
              
              // Input field
              _buildMessageInput(context.read<ChatCubit>()),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEmptyChat() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.chat_outlined,
            size: 80,
            color: AppTheme.textSecondary.withOpacity(0.5),
          ),
          const SizedBox(height: AppTheme.spacingM),
          Text(
            "No messages yet",
            style: AppTheme.bodyLarge.copyWith(
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: AppTheme.spacingS),
          Text(
            "Ask a question about your machine",
            style: AppTheme.bodyMedium.copyWith(
              color: AppTheme.textSecondary.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatList(List<ChatMessage> messages) {
    String? currentDate;
    
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(AppTheme.spacingM),
      itemCount: messages.length,
      itemBuilder: (context, index) {
        final msg = messages[index];
        
        // Check if we need to show a date header
        final messageDate = DateFormat('yyyy-MM-dd').format(msg.timestamp);
        final showDateHeader = currentDate != messageDate;
        if (showDateHeader) {
          currentDate = messageDate;
        }
        
        return Column(
          children: [
            if (showDateHeader)
              _buildDateHeader(msg.timestamp),
            
            MessageBubble(message: msg),
          ],
        );
      },
    );
  }

  Widget _buildDateHeader(DateTime timestamp) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final messageDate = DateTime(
      timestamp.year,
      timestamp.month,
      timestamp.day,
    );
    
    String dateText;
    if (messageDate == today) {
      dateText = 'Today';
    } else if (messageDate == yesterday) {
      dateText = 'Yesterday';
    } else {
      dateText = DateFormat('MMMM d, yyyy').format(timestamp);
    }
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppTheme.spacingM),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppTheme.spacingM,
            vertical: AppTheme.spacingXS,
          ),
          decoration: BoxDecoration(
            color: AppTheme.dividerColor,
            borderRadius: BorderRadius.circular(AppTheme.radiusM),
          ),
          child: Text(
            dateText,
            style: AppTheme.bodySmall,
          ),
        ),
      ),
    );
  }

  Widget _buildMessageInput(ChatCubit cubit) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingM),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: AppTheme.lightShadow,
        border: Border(
          top: BorderSide(color: AppTheme.dividerColor),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              decoration: InputDecoration(
                hintText: "Ask a question or type a command...",
                hintStyle: AppTheme.bodyMedium.copyWith(
                  color: AppTheme.textSecondary.withOpacity(0.6),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusL),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: AppTheme.backgroundColor,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.spacingM,
                  vertical: AppTheme.spacingM,
                ),
              ),
              textInputAction: TextInputAction.send,
              onSubmitted: (text) {
                _sendMessage(cubit);
              },
            ),
          ),
          const SizedBox(width: AppTheme.spacingM),
          InkWell(
            onTap: () => _sendMessage(cubit),
            borderRadius: BorderRadius.circular(AppTheme.radiusL),
            child: Container(
              padding: const EdgeInsets.all(AppTheme.spacingM),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor,
                borderRadius: BorderRadius.circular(AppTheme.radiusL),
              ),
              child: const Icon(
                Icons.send_rounded,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _sendMessage(ChatCubit cubit) {
    final text = _controller.text.trim();
    if (text.isNotEmpty) {
      cubit.sendMessage(text);
      _controller.clear();
    }
  }
}
  // void _showCommandsHelp(BuildContext context) {
  //   showModalBottomSheet(
  //     context: context,
  //     shape: const RoundedRectangleBorder(
  //       borderRadius: BorderRadius.vertical(
  //         top: Radius.circular(AppTheme.radiusL),
  //       ),
  //     ),
  //     builder: (context) {
  //       return Container(
  //         padding: const EdgeInsets.all(AppTheme.spacingL),
  //         child: Column(
  //           mainAxisSize: MainAxisSize.min,
  //           crossAxisAlignment: CrossAxisAlignment.start,
  //           children: [
  //             Text(
  //               "Available Commands",
  //               style: AppTheme.headingMedium,
  //             ),
  //             const SizedBox(height: AppTheme.spacingM),
  //             const Text(
  //               "Start commands with / to control the machine:",
  //               style: AppTheme.bodyMedium,
  //             ),
  //             const SizedBox(height: AppTheme.spacingM),
  //             _buildCommandItem("/status", "Get current machine status"),
  //             _buildCommandItem("/reset", "Reset the machine"),
  //             _buildCommandItem("/maintenance", "Start maintenance mode"),
  //             _buildCommandItem("/help", "Show all available commands"),
  //             const SizedBox(height: AppTheme.spacingM),
  //             const Text(
  //               "For everything else, just ask a question and the AI assistant will help you.",
  //               style: AppTheme.bodyMedium,
  //             ),
  //           ],
  //         ),
  //       );
  //     },
  //   );
  // }

//   Widget _buildCommandItem(String command, String description) {
//     return Padding(
//       padding: const EdgeInsets.symmetric(vertical: AppTheme.spacingS),
//       child: Row(
//         children: [
//           Container(
//             padding: const EdgeInsets.symmetric(
//               horizontal: AppTheme.spacingM,
//               vertical: AppTheme.spacingS,
//             ),
//             decoration: BoxDecoration(
//               color: AppTheme.backgroundColor,
//               borderRadius: BorderRadius.circular(AppTheme.radiusM),
//             ),
//             child: Text(
//               command,
//               style: AppTheme.bodyMedium.copyWith(
//                 fontWeight: FontWeight.bold,
//                 color: AppTheme.primaryColor,
//               ),
//             ),
//           ),
//           const SizedBox(width: AppTheme.spacingM),
//           Text(
//             description,
//             style: AppTheme.bodyMedium,
//           ),
//         ],
//       ),
//     );
//   }
// }