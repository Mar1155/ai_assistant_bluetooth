import 'package:ai_assistent_bluetooth/cubit/chat/chat_cubit.dart';
import 'package:ai_assistent_bluetooth/cubit/chat/chat_state.dart';
import 'package:ai_assistent_bluetooth/cubit/scan/scan_cubit.dart';
import 'package:ai_assistent_bluetooth/models/chat_message.dart';
import 'package:ai_assistent_bluetooth/screens/scan_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class DeviceChatView extends StatefulWidget {
  const DeviceChatView({super.key});

  @override
  State<DeviceChatView> createState() => _DeviceChatViewState();
}

class _DeviceChatViewState extends State<DeviceChatView> {
  final TextEditingController _controller = TextEditingController();

  Widget _buildChatList(List<ChatMessage> messages) {
    return ListView.builder(
      padding: const EdgeInsets.all(10),
      itemCount: messages.length,
      itemBuilder: (context, index) {
        final msg = messages[index];
        return Align(
          alignment:
              msg.isSentByUser ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 5),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: msg.isSentByUser ? Colors.blueAccent : Colors.grey[300],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              msg.message,
              style: TextStyle(
                color: msg.isSentByUser ? Colors.white : Colors.black,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildMessageInput(ChatCubit cubit) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      color: Colors.grey[200],
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
              String text = _controller.text.trim();
              if (text.isNotEmpty) {
                cubit.sendMessage(text);
                _controller.clear();
              }
            },
          ),
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
            title: Text(state.isConnected ? "Chat" : "Connecting..."),
            actions: [
              IconButton(
                icon: const Icon(Icons.cancel),
                onPressed: () async {
                  await context.read<ChatCubit>().disconnect();
                  await context.read<ScanCubit>().disconnectFromAllDevices();
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => ScanView()),
                  );
                },
              ),
            ],
          ),
          body: Column(
            children: [
              Expanded(child: _buildChatList(state.messages)),
              _buildMessageInput(context.read<ChatCubit>()),
            ],
          ),
        );
      },
    );
  }
}
