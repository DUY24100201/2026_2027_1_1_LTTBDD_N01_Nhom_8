import 'package:material_ui/material_ui.dart';

import '../screens/intro/intro_dialog.dart';

class IntroDialogPage extends StatefulWidget {
  final Widget child;

  const IntroDialogPage({super.key, required this.child});

  @override
  State<IntroDialogPage> createState() => _IntroDialogPageState();
}

class _IntroDialogPageState extends State<IntroDialogPage> {
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      IntroDialog.show(context);
    });
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
