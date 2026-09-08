import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

class TypingInputArea extends StatefulWidget {
  final ValueChanged<String> onSubmit;
  final VoidCallback onHint;
  final VoidCallback onSkip;
  final VoidCallback onDontKnow;
  final int currentHintLevel;
  final bool isEvaluated;

  const TypingInputArea({
    super.key,
    required this.onSubmit,
    required this.onHint,
    required this.onSkip,
    required this.onDontKnow,
    required this.currentHintLevel,
    this.isEvaluated = false,
  });

  @override
  State<TypingInputArea> createState() => _TypingInputAreaState();
}

class _TypingInputAreaState extends State<TypingInputArea> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
    _focusNode = FocusNode();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_focusNode.hasFocus && !widget.isEvaluated) {
        _focusNode.requestFocus();
      }
    });
  }

  @override
  void didUpdateWidget(covariant TypingInputArea oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isEvaluated && !widget.isEvaluated) {
      _controller.clear();
      _focusNode.requestFocus();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _handleSubmit() {
    final text = _controller.text.trim();
    if (text.isNotEmpty) {
      widget.onSubmit(text);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Typing Text Field
          TextField(
            controller: _controller,
            focusNode: _focusNode,
            enabled: !widget.isEvaluated,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _handleSubmit(),
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
              color: AppTheme.textPrimaryLight,
            ),
            decoration: InputDecoration(
              hintText: 'Type academic word here...',
              hintStyle: TextStyle(
                color: Colors.grey.shade400,
                fontWeight: FontWeight.normal,
              ),
              prefixIcon: const Icon(Icons.keyboard_outlined, color: AppTheme.primary),
              suffixIcon: _controller.text.isNotEmpty && !widget.isEvaluated
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 20),
                      onPressed: () {
                        setState(() {
                          _controller.clear();
                        });
                      },
                    )
                  : null,
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 12),

          // Action Toolbar
          SizedBox(
            width: double.infinity,
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    // Hint Button
                    OutlinedButton.icon(
                      onPressed: widget.currentHintLevel >= 3 || widget.isEvaluated
                          ? null
                          : widget.onHint,
                      icon: const Icon(Icons.lightbulb_outline, size: 16),
                      label: Text(
                        widget.currentHintLevel == 0
                            ? 'Hint'
                            : 'Hint (${widget.currentHintLevel}/3)',
                        style: const TextStyle(fontSize: 12.5),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.warning,
                        side: BorderSide(color: AppTheme.warning.withValues(alpha: 0.5)),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                        visualDensity: VisualDensity.compact,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),

                    // Don't Know Button
                    OutlinedButton.icon(
                      onPressed: widget.isEvaluated ? null : widget.onDontKnow,
                      icon: const Icon(Icons.help_outline, size: 16),
                      label: const Text(
                        "Don't Know",
                        style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.error,
                        side: BorderSide(color: AppTheme.error.withValues(alpha: 0.5)),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                        visualDensity: VisualDensity.compact,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),

                    // Skip Button
                    TextButton.icon(
                      onPressed: widget.isEvaluated ? null : widget.onSkip,
                      icon: const Icon(Icons.fast_forward_outlined, size: 15),
                      label: const Text('Skip', style: TextStyle(fontSize: 12)),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.grey.shade600,
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                        visualDensity: VisualDensity.compact,
                      ),
                    ),
                  ],
                ),

                // Submit / Check Button
                ElevatedButton.icon(
                  onPressed: widget.isEvaluated || _controller.text.trim().isEmpty
                      ? null
                      : _handleSubmit,
                  icon: const Icon(Icons.check_circle_outline, size: 17),
                  label: const Text(
                    'Check',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.accentDark,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                    visualDensity: VisualDensity.compact,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
