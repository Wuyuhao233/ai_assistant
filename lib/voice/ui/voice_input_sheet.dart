import 'dart:async';
import 'package:flutter/material.dart';
import '../services/speech_to_text_service.dart';

/// 语音输入底部弹窗
class VoiceInputSheet extends StatefulWidget {
  final void Function(String text) onResult;

  const VoiceInputSheet({super.key, required this.onResult});

  /// 显示底部弹窗
  static Future<void> show(BuildContext context, {required void Function(String) onResult}) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => VoiceInputSheet(onResult: onResult),
    );
  }

  @override
  State<VoiceInputSheet> createState() => _VoiceInputSheetState();
}

class _VoiceInputSheetState extends State<VoiceInputSheet>
    with SingleTickerProviderStateMixin {
  final SpeechToTextService _stt = SpeechToTextService();
  StreamSubscription<String>? _subscription;
  String _recognizedText = '';
  bool _isListening = false;
  double _volume = 0.0;

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // 自动开始监听
    WidgetsBinding.instance.addPostFrameCallback((_) => _startListening());
  }

  Future<void> _startListening() async {
    final available = await _stt.initialize();
    if (!available && mounted) {
      setState(() => _recognizedText = '语音识别不可用，请在真机上测试');
      return;
    }

    setState(() => _isListening = true);
    _subscription = _stt.startListening().listen((text) {
      if (mounted) {
        setState(() => _recognizedText = text);
        // 模拟音量变化
        _volume = (0.3 + (DateTime.now().millisecondsSinceEpoch % 70) / 100.0)
            .clamp(0.0, 1.0);
      }
    });
  }

  Future<void> _stopAndSend() async {
    await _stt.stopListening();
    _subscription?.cancel();
    if (_recognizedText.isNotEmpty && _recognizedText != '（语音输入功能需要在真机上测试）') {
      widget.onResult(_recognizedText);
    }
    if (mounted) Navigator.pop(context);
  }

  Future<void> _cancel() async {
    await _stt.stopListening();
    _subscription?.cancel();
    if (mounted) Navigator.pop(context);
  }

  @override
  void dispose() {
    _stt.dispose();
    _subscription?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;

    return Container(
      height: size.height * 0.4,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 16),

            // 拖拽指示条
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: theme.colorScheme.onSurface.withOpacity(0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            const SizedBox(height: 32),

            // 语音提示
            Text(
              _isListening ? '正在聆听...' : '处理中',
              style: theme.textTheme.titleMedium,
            ),

            const SizedBox(height: 32),

            // 麦克风动画按钮
            GestureDetector(
              onTap: _isListening ? _stopAndSend : _startListening,
              child: AnimatedBuilder(
                animation: _pulseAnimation,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _isListening ? _pulseAnimation.value : 1.0,
                    child: Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _isListening
                            ? theme.colorScheme.primary
                            : theme.colorScheme.surfaceContainerHighest,
                      ),
                      child: Icon(
                        _isListening ? Icons.mic : Icons.mic_off,
                        size: 48,
                        color: _isListening
                            ? Colors.white
                            : theme.colorScheme.onSurface,
                      ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 24),

            // 识别结果
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 32),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                _recognizedText.isEmpty ? '点击麦克风说话...' : _recognizedText,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: _recognizedText.isEmpty
                      ? theme.colorScheme.onSurface.withOpacity(0.4)
                      : null,
                ),
              ),
            ),

            const Spacer(),

            // 底部操作栏
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton.icon(
                    onPressed: _cancel,
                    icon: const Icon(Icons.close),
                    label: const Text('取消'),
                  ),
                  if (_recognizedText.isNotEmpty)
                    FilledButton.icon(
                      onPressed: _stopAndSend,
                      icon: const Icon(Icons.send_rounded),
                      label: const Text('发送'),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// AnimatedBuilder 兼容版本
class AnimatedBuilder extends AnimatedWidget {
  final Widget Function(BuildContext context, Widget? child) builder;
  final Widget? child;

  const AnimatedBuilder({
    super.key,
    required super.listenable,
    required this.builder,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    return builder(context, child);
  }
}
