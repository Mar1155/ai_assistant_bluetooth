// chat_device_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ai_assistent_bluetooth/cubit/chat/chat_cubit.dart';
import 'package:ai_assistent_bluetooth/cubit/chat/chat_state.dart';
import 'package:ai_assistent_bluetooth/models/chat_message.dart';
import 'package:intl/intl.dart';

class DeviceChatView extends StatefulWidget {
  final String? errorCode;
  final String errorMessage;
  const DeviceChatView({Key? key, this.errorCode, required this.errorMessage}) : super(key: key);

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
    if (messages.isEmpty) {
      return const Center(child: Text('Nessun messaggio'));
    }
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      itemCount: messages.length,
      itemBuilder: (context, index) {
        final msg = messages[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            mainAxisAlignment: msg.isSentByUser ? MainAxisAlignment.end : MainAxisAlignment.start,
            children: [
              if (!msg.isSentByUser)
                const CircleAvatar(
                  radius: 16,
                  backgroundColor: Colors.blue,
                  child: Icon(Icons.android, size: 16, color: Colors.white),
                ),
              if (!msg.isSentByUser) const SizedBox(width: 8),
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: msg.isSentByUser ? Theme.of(context).primaryColor : Colors.grey[200],
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    msg.message,
                    style: TextStyle(
                      color: msg.isSentByUser ? Colors.white : Colors.black,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMessageInput(ChatCubit cubit) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              decoration: const InputDecoration(
                hintText: "Scrivi un messaggio...",
                border: InputBorder.none,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.send),
            onPressed: () {
              final text = _controller.text.trim();
              if (text.isNotEmpty) {
                cubit.sendMessage(text);
                _controller.clear();
              }
            },
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ChatCubit, ChatState>(
      builder: (context, state) {
        return Scaffold(
          appBar: AppBar(
            title: const Text("Chat con ChatGPT"),
          ),
          body: SafeArea(
            child: Column(
              children: [
                if (state.isWaitingForAi)
                  Container(
                    padding: const EdgeInsets.all(8),
                    child: const Text("Thinking...", style: TextStyle(fontStyle: FontStyle.italic)),
                  ),
                Expanded(child: _buildChatList(state.messages)),
                _buildMessageInput(context.read<ChatCubit>()),
              ],
            ),
          ),
        );
      },
    );
  }
}
