import 'package:material_ui/material_ui.dart';

class IntroDialogPage extends StatelessWidget {
  final Widget child;
  final String screenId;

  const IntroDialogPage({
    super.key,
    required this.child,
    required this.screenId,
  });

  @override
  Widget build(BuildContext context) {
    return child;
  }
}
