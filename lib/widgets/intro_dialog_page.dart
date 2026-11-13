import 'package:material_ui/material_ui.dart';

import '../screens/intro/intro_dialog.dart';
import '../services/storage_service.dart';

class IntroDialogPage extends StatefulWidget {
  final Widget child;
  final String screenId;

  const IntroDialogPage({
    super.key,
    required this.child,
    required this.screenId,
  });

  @override
  State<IntroDialogPage> createState() => _IntroDialogPageState();
}

class _IntroDialogPageState extends State<IntroDialogPage> {
  static Future<void> _dialogQueue = Future<void>.value();
  static final Set<String> _shownScreenIds = {};

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final pending = _dialogQueue.then((_) => _showIntroDialogIfNeeded());
      _dialogQueue = pending.catchError((Object error, StackTrace stackTrace) {
        _reportError(error, stackTrace, 'hiển thị IntroDialog');
      });
    });
  }

  Future<void> _showIntroDialogIfNeeded() async {
    if (!mounted || _shownScreenIds.contains(widget.screenId)) return;

    final storage = StorageService.instance;
    final seenKey =
        '${StorageService.introDialogSeenKeyPrefix}_${widget.screenId}';
    String? hasSeenIntro;
    try {
      hasSeenIntro = await storage.readString(seenKey);
    } catch (error, stackTrace) {
      _reportError(error, stackTrace, 'đọc trạng thái IntroDialog');
    }

    if (!mounted || _shownScreenIds.contains(widget.screenId)) return;
    if (hasSeenIntro == 'true') {
      _shownScreenIds.add(widget.screenId);
      return;
    }

    _shownScreenIds.add(widget.screenId);
    await IntroDialog.show(context);

    try {
      await storage.writeString(seenKey, 'true');
    } catch (error, stackTrace) {
      _reportError(error, stackTrace, 'lưu trạng thái IntroDialog');
    }
  }

  static void _reportError(
    Object error,
    StackTrace stackTrace,
    String action,
  ) {
    FlutterError.reportError(
      FlutterErrorDetails(
        exception: error,
        stack: stackTrace,
        library: 'intro dialog',
        context: ErrorDescription('khi $action'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
