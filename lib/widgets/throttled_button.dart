import 'dart:async';
import 'package:flutter/material.dart';

class ThrottledButton extends StatefulWidget {
  final Widget child;
  final FutureOr<void> Function() onPressed;
  final ButtonStyle? style;
  final Duration throttleDuration;
  final Widget? loadingWidget;
  final bool isElevated;
  final bool isText;
  final bool isIcon;
  final bool isOutlined;
  final IconData? icon;

  const ThrottledButton.elevated({
    super.key,
    required this.child,
    required this.onPressed,
    this.style,
    this.throttleDuration = const Duration(seconds: 2),
    this.loadingWidget,
  })  : isElevated = true,
        isText = false,
        isIcon = false,
        isOutlined = false,
        icon = null;

  const ThrottledButton.text({
    super.key,
    required this.child,
    required this.onPressed,
    this.style,
    this.throttleDuration = const Duration(seconds: 2),
    this.loadingWidget,
  })  : isElevated = false,
        isText = true,
        isIcon = false,
        isOutlined = false,
        icon = null;

  const ThrottledButton.icon({
    super.key,
    required this.icon,
    required this.onPressed,
    this.style,
    this.throttleDuration = const Duration(seconds: 2),
    this.loadingWidget,
  })  : isElevated = false,
        isText = false,
        isIcon = true,
        isOutlined = false,
        child = const SizedBox.shrink();

  const ThrottledButton.outlined({
    super.key,
    required this.child,
    required this.onPressed,
    this.style,
    this.throttleDuration = const Duration(seconds: 2),
    this.loadingWidget,
  })  : isElevated = false,
        isText = false,
        isIcon = false,
        isOutlined = true,
        icon = null;

  @override
  State<ThrottledButton> createState() => _ThrottledButtonState();
}

class _ThrottledButtonState extends State<ThrottledButton> {
  bool _isProcessing = false;
  Timer? _timer;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _handlePress() async {
    if (_isProcessing) return;

    setState(() {
      _isProcessing = true;
    });

    try {
      await widget.onPressed();
    } finally {
      if (mounted) {
        _timer = Timer(widget.throttleDuration, () {
          if (mounted) {
            setState(() {
              _isProcessing = false;
            });
          }
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isIcon) {
      return IconButton(
        onPressed: _isProcessing ? null : _handlePress,
        icon: _isProcessing
            ? (widget.loadingWidget ?? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2)))
            : Icon(widget.icon),
        style: widget.style,
      );
    }

    if (widget.isText) {
      return TextButton(
        onPressed: _isProcessing ? null : _handlePress,
        style: widget.style,
        child: _isProcessing
            ? (widget.loadingWidget ?? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)))
            : widget.child,
      );
    }

    if (widget.isOutlined) {
      return OutlinedButton(
        onPressed: _isProcessing ? null : _handlePress,
        style: widget.style,
        child: _isProcessing
            ? (widget.loadingWidget ?? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)))
            : widget.child,
      );
    }

    return ElevatedButton(
      onPressed: _isProcessing ? null : _handlePress,
      style: widget.style,
      child: _isProcessing
          ? (widget.loadingWidget ?? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)))
          : widget.child,
    );
  }
}
