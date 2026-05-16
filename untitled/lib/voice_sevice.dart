import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

class VoiceService {
  static final AudioRecorder _recorder = AudioRecorder();
  static String? _recordingPath;

  static Future<bool> startRecording() async {
    if (await Permission.microphone.request().isDenied) return false;

    final dir = await getApplicationDocumentsDirectory();
    _recordingPath = '${dir.path}/voice_${DateTime.now().millisecondsSinceEpoch}.m4a';

    await _recorder.start(const RecordConfig(), path: _recordingPath!);
    return true;
  }

  static Future<String?> stopRecording() async {
    await _recorder.stop();
    return _recordingPath;
  }

  static Future<bool> isRecording() async {
    return await _recorder.isRecording();
  }
}