import 'dart:async';
import 'dart:io';

import 'package:ai_assistent_bluetooth/services/chat_gpt_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ai_assistent_bluetooth/cubit/chat/chat_cubit.dart';
import 'package:ai_assistent_bluetooth/cubit/chat/chat_state.dart';
import 'package:ai_assistent_bluetooth/models/chat_message.dart';
import 'package:ai_assistent_bluetooth/cubit/scan/scan_cubit.dart';
import 'package:ai_assistent_bluetooth/cubit/scan/scan_state.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

class DeviceChatView extends StatefulWidget {
  final String? errorCode;
  final String errorMessage;
  const DeviceChatView({Key? key, this.errorCode, required this.errorMessage})
    : super(key: key);

  @override
  State<DeviceChatView> createState() => _DeviceChatViewState();
}

class _DeviceChatViewState extends State<DeviceChatView> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  String? _lastProcessedErrorCode;

  final AudioRecorder _record = AudioRecorder();
  final FlutterTts _flutterTts = FlutterTts();
  bool _isRecording = false;
  bool _isProcessingAudio = false;
  bool _isSpeaking = false;
  double _recordingVolume = 0.0;
  Timer? _volumeTimer;

  // TTS settings
  bool _autoPlayResponses = true;
  double _speechRate = 0.5; // Default medium speed
  double _pitch = 1.0; // Default pitch

  @override
  void initState() {
    super.initState();
    _lastProcessedErrorCode = widget.errorCode;
    _initTts();
  }

  void _initTts() async {
    await _flutterTts.setLanguage("it-IT");
    await _flutterTts.setPitch(_pitch);
    await _flutterTts.setSpeechRate(_speechRate);

    _flutterTts.setCompletionHandler(() {
      setState(() {
        _isSpeaking = false;
      });
    });
  }

  // Funzione per iniziare la registrazione audio
  Future<void> _startRecording() async {
    if (await _record.hasPermission()) {
      // Inizia a registrare e salva in un file temporaneo
      Directory tempDir = await getTemporaryDirectory();
      String filePath =
          '${tempDir.path}/audio_${DateTime.now().millisecondsSinceEpoch}.m4a';
      await _record.start(
        const RecordConfig(encoder: AudioEncoder.aacLc),
        path: filePath,
      );

      setState(() {
        _isRecording = true;
      });

      // Monitora il volume durante la registrazione
      _volumeTimer = Timer.periodic(const Duration(milliseconds: 200), (
        _,
      ) async {
        final amplitude = await _record.getAmplitude();
        final volume = amplitude.current * 0.01;
        setState(() {
          _recordingVolume = volume > 1.0 ? 1.0 : volume;
        });
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Permesso di registrazione non concesso')),
      );
    }
  }

  // Funzione per terminare la registrazione e processare l'audio
  Future<void> _stopRecordingAndProcess() async {
    _volumeTimer?.cancel();
    setState(() {
      _isRecording = false;
      _isProcessingAudio = true;
      _recordingVolume = 0.0;
    });

    String? path = await _record.stop();

    if (path != null) {
      File audioFile = File(path);
      // Trascrivi l'audio in testo
      String? userText = await ChatGptService().transcribeAudio(audioFile);

      if (userText != null && userText.trim().isNotEmpty) {
        // Invia il testo trascritto al ChatGptService via ChatCubit
        if (mounted) {
          _controller.text = userText; // Mostra il testo trascritto nell'input
          context.read<ChatCubit>().sendMessage(userText);
          _controller.clear();
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Non ho capito. Riprova a parlare')),
          );
        }
      }
    }

    setState(() {
      _isProcessingAudio = false;
    });
  }

  // Funzione per interrompere o riprendere la sintesi vocale
  void _toggleTts() async {
    if (_isSpeaking) {
      await _flutterTts.stop();
      setState(() {
        _isSpeaking = false;
      });
    } else {
      final lastMessage =
          context.read<ChatCubit>().state.messages.isNotEmpty
              ? context.read<ChatCubit>().state.messages.last
              : null;

      if (lastMessage != null && !lastMessage.isSentByUser) {
        setState(() {
          _isSpeaking = true;
        });
        await _flutterTts.speak(lastMessage.message);
      }
    }
  }

  @override
  void dispose() {
    context.read<ChatCubit>().resetChat();
    _controller.dispose();
    _scrollController.dispose();
    _volumeTimer?.cancel();
    _flutterTts.stop();
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
    // If no messages exist, use the initial errorMessage as the first chat message
    List<ChatMessage> chatMessages =
        messages.isEmpty && widget.errorMessage.isNotEmpty
            ? [ChatMessage(message: widget.errorMessage, isSentByUser: false)]
            : messages;

    if (chatMessages.isEmpty) {
      return const Center(child: Text('Nessun messaggio'));
    }
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      itemCount: chatMessages.length,
      itemBuilder: (context, index) {
        if (index == 0) return SizedBox.shrink();
        final msg = chatMessages[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            mainAxisAlignment:
                msg.isSentByUser
                    ? MainAxisAlignment.end
                    : MainAxisAlignment.start,
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
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color:
                        msg.isSentByUser
                            ? Theme.of(context).primaryColor
                            : Colors.grey[200],
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Stack(
                    children: [
                      Text(
                        msg.message,
                        style: TextStyle(
                          color: msg.isSentByUser ? Colors.white : Colors.black,
                          fontSize: 16,
                        ),
                      ),
                      if (!msg.isSentByUser)
                        Positioned(
                          right: 0,
                          bottom: -8,
                          child: IconButton(
                            iconSize: 18,
                            icon: Icon(
                              _isSpeaking
                                  ? Icons.pause_circle
                                  : Icons.play_circle,
                              color: Colors.blue,
                            ),
                            onPressed: _toggleTts,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<ScanCubit, ScanState>(
          listener: (context, scanState) {
            if (scanState.errorList.isNotEmpty) {
              final newError = scanState.errorList.last;
              if (newError.code != _lastProcessedErrorCode) {
                _lastProcessedErrorCode = newError.code;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Nuovo errore: ${newError.code}')),
                );
                context.read<ChatCubit>().sendMessage(newError.code);
              }
            }
          },
        ),
        BlocListener<ChatCubit, ChatState>(
          listener: (context, chatState) {
            // Se l'ultimo messaggio è inviato dall'assistente e auto-play è attivo, riproduci la voce
            if (chatState.messages.isNotEmpty &&
                !chatState.messages.last.isSentByUser &&
                _autoPlayResponses) {
              setState(() {
                _isSpeaking = true;
              });
              _flutterTts.speak(chatState.messages.last.message);
            }
          },
        ),
      ],
      child: BlocBuilder<ChatCubit, ChatState>(
        builder: (context, state) {
          return Scaffold(
            appBar: AppBar(
              title: const Text("Assistente AI"),
              actions: [
                // Pulsante per le impostazioni vocali
                IconButton(
                  icon: Icon(
                    _autoPlayResponses ? Icons.volume_up : Icons.volume_off,
                  ),
                  onPressed: () => _showVoiceSettingsDialog(),
                ),
                IconButton(
                  icon: Icon(Icons.refresh),
                  onPressed: () {
                    _flutterTts.stop();
                    context.read<ChatCubit>().resetChat();
                  },
                ),
              ],
            ),
            body: SafeArea(
              child: Column(
                children: [
                  if (state.isWaitingForAi)
                    Container(
                      padding: const EdgeInsets.all(8),
                      child: const Text(
                        "Thinking...",
                        style: TextStyle(fontStyle: FontStyle.italic),
                      ),
                    ),
                  Expanded(child: _buildChatList(state.messages)),
                  if (widget.errorMessage.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16.0,
                        vertical: 8.0,
                      ),
                      child: ElevatedButton(
                        onPressed: () {
                          context.read<ChatCubit>().sendMessage(
                            widget.errorMessage,
                          );
                        },
                        child: const Text("Ripeti scansione"),
                      ),
                    ),
                  _buildMessageInput(context.read<ChatCubit>()),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // Visualizza il dialogo delle impostazioni vocali
  Future<void> _showVoiceSettingsDialog() async {
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Impostazioni Vocali'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SwitchListTile(
                      title: const Text('Riproduzione automatica'),
                      subtitle: const Text('Leggi automaticamente le risposte'),
                      value: _autoPlayResponses,
                      onChanged: (value) {
                        setDialogState(() {
                          _autoPlayResponses = value;
                        });
                        setState(() {
                          _autoPlayResponses = value;
                        });
                      },
                    ),
                    const Text('Velocità della voce'),
                    Slider(
                      value: _speechRate,
                      min: 0.1,
                      max: 1.0,
                      divisions: 9,
                      label: _speechRate.toStringAsFixed(1),
                      onChanged: (value) {
                        setDialogState(() {
                          _speechRate = value;
                        });
                      },
                      onChangeEnd: (value) async {
                        await _flutterTts.setSpeechRate(value);
                        setState(() {
                          _speechRate = value;
                        });
                      },
                    ),
                    const Text('Tono della voce'),
                    Slider(
                      value: _pitch,
                      min: 0.5,
                      max: 2.0,
                      divisions: 15,
                      label: _pitch.toStringAsFixed(1),
                      onChanged: (value) {
                        setDialogState(() {
                          _pitch = value;
                        });
                      },
                      onChangeEnd: (value) async {
                        await _flutterTts.setPitch(value);
                        setState(() {
                          _pitch = value;
                        });
                      },
                    ),
                    ElevatedButton(
                      child: const Text('Prova voce'),
                      onPressed: () {
                        _flutterTts.speak(
                          "Questa è una prova della voce con le impostazioni attuali",
                        );
                      },
                    ),
                  ],
                ),
              ),
              actions: <Widget>[
                TextButton(
                  child: const Text('Chiudi'),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  // Widget dell'input dei messaggi con funzionalità vocali migliorate
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
      child: Column(
        children: [
          if (_isRecording)
            Container(
              height: 40,
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: LinearProgressIndicator(
                      value: _recordingVolume,
                      backgroundColor: Colors.grey[300],
                      valueColor: AlwaysStoppedAnimation<Color>(
                        _recordingVolume > 0.6 ? Colors.red : Colors.green,
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Registrazione in corso...',
                    style: TextStyle(
                      color: Colors.grey[700],
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
          if (_isProcessingAudio)
            Container(
              height: 40,
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Colors.blue[700]!,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Elaborazione audio...',
                    style: TextStyle(
                      color: Colors.blue[700],
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
          Row(
            children: [
              // Pulsante Microfono con effetti animati
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: _isRecording ? 56 : 48,
                height: _isRecording ? 56 : 48,
                decoration: BoxDecoration(
                  color: _isRecording ? Colors.red : Colors.blue,
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: Icon(
                    _isRecording ? Icons.stop : Icons.mic,
                    color: Colors.white,
                    size: _isRecording ? 28 : 24,
                  ),
                  onPressed: () async {
                    if (_isRecording) {
                      await _stopRecordingAndProcess();
                    } else {
                      await _startRecording();
                    }
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _controller,
                  decoration: InputDecoration(
                    hintText: "Scrivi un messaggio...",
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Colors.grey[200],
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                  onSubmitted: (text) {
                    if (text.trim().isNotEmpty) {
                      cubit.sendMessage(text);
                      _controller.clear();
                    }
                  },
                ),
              ),
              const SizedBox(width: 8),
              Container(
                decoration: BoxDecoration(
                  color: theme.primaryColor,
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: const Icon(Icons.send, color: Colors.white),
                  onPressed: () {
                    final text = _controller.text.trim();
                    if (text.isNotEmpty) {
                      cubit.sendMessage(text);
                      _controller.clear();
                    }
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
