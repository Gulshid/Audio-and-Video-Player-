import 'package:flutter/material.dart';

enum DeviceType { phone, tablet, desktop }

/// Wraps [LayoutBuilder] and exposes a [DeviceType] to the child builder.
///
/// Usage:
/// ```dart
/// ResponsiveBuilder(
///   builder: (context, device) => device == DeviceType.phone
///       ? _PhoneLayout()
///       : _TabletLayout(),
/// )
/// ```
class ResponsiveBuilder extends StatelessWidget {
  const ResponsiveBuilder({required this.builder, super.key});

  final Widget Function(BuildContext context, DeviceType device) builder;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (ctx, constraints) {
        final device = _resolve(constraints.maxWidth);
        return builder(ctx, device);
      },
    );
  }

  static DeviceType _resolve(double width) {
    if (width < 600)  return DeviceType.phone;
    if (width < 1200) return DeviceType.tablet;
    return DeviceType.desktop;
  }
}

/// Returns [DeviceType] for the current screen width.
DeviceType deviceTypeOf(BuildContext context) {
  final width = MediaQuery.sizeOf(context).width;
  if (width < 600)  return DeviceType.phone;
  if (width < 1200) return DeviceType.tablet;
  return DeviceType.desktop;
}
