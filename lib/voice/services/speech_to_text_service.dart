import 'package:flutter/foundation.dart';

/// 语音识别服务封装
class SpeechToTextService {
  bool _isAvailable = false;
  bool _isListening = false;

  bool get isAvailable => _isAvailable;
  bool get isListening => _isListening;

  /// 初始化语音识别
  Future<bool> initialize() async {
    try {
      // speech_to_text 包需要在这里初始化
      // final speech = SpeechToText();
      // _isAvailable = await speech.initialize();
      _isAvailable = true; // 占位
      debugPrint('[STT] 语音识别初始化完成');
      return _isAvailable;
    } catch (e) {
      debugPrint('[STT] 初始化失败: $e');
      _isAvailable = false;
      return false;
    }
  }

  /// 开始监听语音
  Stream<String> startListening() async* {
    if (!_isAvailable) {
      yield '语音识别不可用';
      return;
    }

    _isListening = true;
    debugPrint('[STT] 开始语音识别...');

    // 模拟语音识别 — 实际项目替换为 speech_to_text 调用
    // final speech = SpeechToText();
    // speech.listen(
    //   onResult: (result) => yield result.recognizedWords,
    // );

    yield '（语音输入功能需要在真机上测试）';
    _isListening = false;
  }

  /// 停止监听
  Future<void> stopListening() async {
    _isListening = false;
    debugPrint('[STT] 停止语音识别');
  }

  /// 释放资源
  void dispose() {
    stopListening();
  }
}
