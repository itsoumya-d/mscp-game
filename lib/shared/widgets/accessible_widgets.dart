import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';

/// Accessible Widgets - Task E1: Screen Reader Optimization
/// Pre-built widgets with proper semantic labels and WCAG compliance
/// 
/// Features:
/// - Semantic labels for all interactive elements
/// - Proper reading order
/// - Live region announcements
/// - Focus management
/// - WCAG 2.1 AAA compliance

/// Accessible Button with semantic labels
class AccessibleButton extends StatelessWidget {
  final String label;
  final String? hint;
  final VoidCallback onPressed;
  final Widget child;
  final bool enabled;

  const AccessibleButton({
    Key? key,
    required this.label,
    this.hint,
    required this.onPressed,
    required this.child,
    this.enabled = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: label,
      hint: hint,
      button: true,
      enabled: enabled,
      child: ElevatedButton(
        onPressed: enabled ? onPressed : null,
        child: child,
      ),
    );
  }
}

/// Accessible Icon Button
class AccessibleIconButton extends StatelessWidget {
  final String label;
  final String? hint;
  final IconData icon;
  final VoidCallback onPressed;
  final bool enabled;

  const AccessibleIconButton({
    Key? key,
    required this.label,
    this.hint,
    required this.icon,
    required this.onPressed,
    this.enabled = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: label,
      hint: hint,
      button: true,
      enabled: enabled,
      child: IconButton(
        icon: Icon(icon),
        onPressed: enabled ? onPressed : null,
        tooltip: label,
      ),
    );
  }
}

/// Accessible Text Field
class AccessibleTextField extends StatelessWidget {
  final String label;
  final String? hint;
  final TextEditingController? controller;
  final TextInputType? keyboardType;
  final bool obscureText;
  final String? errorText;

  const AccessibleTextField({
    Key? key,
    required this.label,
    this.hint,
    this.controller,
    this.keyboardType,
    this.obscureText = false,
    this.errorText,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: label,
      hint: hint,
      textField: true,
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        obscureText: obscureText,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          errorText: errorText,
        ),
      ),
    );
  }
}

/// Accessible Card with semantic grouping
class AccessibleCard extends StatelessWidget {
  final String label;
  final String? hint;
  final Widget child;
  final VoidCallback? onTap;

  const AccessibleCard({
    Key? key,
    required this.label,
    this.hint,
    required this.child,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: label,
      hint: hint,
      button: onTap != null,
      child: Card(
        child: InkWell(
          onTap: onTap,
          child: child,
        ),
      ),
    );
  }
}

/// Accessible Image with description
class AccessibleImage extends StatelessWidget {
  final String description;
  final ImageProvider image;
  final double? width;
  final double? height;
  final BoxFit? fit;

  const AccessibleImage({
    Key? key,
    required this.description,
    required this.image,
    this.width,
    this.height,
    this.fit,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: description,
      image: true,
      child: Image(
        image: image,
        width: width,
        height: height,
        fit: fit,
        semanticLabel: description,
      ),
    );
  }
}

/// Accessible Progress Indicator with live updates
class AccessibleProgressIndicator extends StatelessWidget {
  final double value;
  final String label;
  final bool showPercentage;

  const AccessibleProgressIndicator({
    Key? key,
    required this.value,
    required this.label,
    this.showPercentage = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final percentage = (value * 100).toInt();
    final semanticLabel = showPercentage
        ? '$label: $percentage percent complete'
        : label;

    return Semantics(
      label: semanticLabel,
      value: '$percentage%',
      liveRegion: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label),
          const SizedBox(height: 8),
          LinearProgressIndicator(value: value),
          if (showPercentage)
            Text('$percentage%', style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}

/// Accessible List Item with proper reading order
class AccessibleListItem extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? leading;
  final Widget? trailing;
  final VoidCallback? onTap;
  final int? sortKey;

  const AccessibleListItem({
    Key? key,
    required this.title,
    this.subtitle,
    this.leading,
    this.trailing,
    this.onTap,
    this.sortKey,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    String semanticLabel = title;
    if (subtitle != null) {
      semanticLabel += '. $subtitle';
    }

    return Semantics(
      label: semanticLabel,
      button: onTap != null,
      sortKey: sortKey != null ? OrdinalSortKey(sortKey!.toDouble()) : null,
      child: ListTile(
        leading: leading,
        title: Text(title),
        subtitle: subtitle != null ? Text(subtitle!) : null,
        trailing: trailing,
        onTap: onTap,
      ),
    );
  }
}

/// Accessible Switch with clear state
class AccessibleSwitch extends StatelessWidget {
  final String label;
  final String? hint;
  final bool value;
  final ValueChanged<bool> onChanged;

  const AccessibleSwitch({
    Key? key,
    required this.label,
    this.hint,
    required this.value,
    required this.onChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final semanticLabel = '$label, ${value ? "on" : "off"}';

    return Semantics(
      label: semanticLabel,
      hint: hint,
      toggled: value,
      child: SwitchListTile(
        title: Text(label),
        subtitle: hint != null ? Text(hint!) : null,
        value: value,
        onChanged: onChanged,
      ),
    );
  }
}

/// Accessible Slider with value announcements
class AccessibleSlider extends StatelessWidget {
  final String label;
  final double value;
  final double min;
  final double max;
  final int? divisions;
  final ValueChanged<double> onChanged;
  final String Function(double)? valueFormatter;

  const AccessibleSlider({
    Key? key,
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    this.divisions,
    required this.onChanged,
    this.valueFormatter,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final formattedValue = valueFormatter?.call(value) ?? value.toStringAsFixed(1);
    final semanticLabel = '$label: $formattedValue';

    return Semantics(
      label: semanticLabel,
      value: formattedValue,
      slider: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label),
          Slider(
            value: value,
            min: min,
            max: max,
            divisions: divisions,
            label: formattedValue,
            onChanged: onChanged,
          ),
          Text(formattedValue, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}

/// Accessible Alert Dialog
class AccessibleAlertDialog extends StatelessWidget {
  final String title;
  final String content;
  final String confirmLabel;
  final String? cancelLabel;
  final VoidCallback onConfirm;
  final VoidCallback? onCancel;

  const AccessibleAlertDialog({
    Key? key,
    required this.title,
    required this.content,
    required this.confirmLabel,
    this.cancelLabel,
    required this.onConfirm,
    this.onCancel,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Alert: $title',
      scopesRoute: true,
      child: AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          if (cancelLabel != null)
            AccessibleButton(
              label: cancelLabel!,
              onPressed: onCancel ?? () => Navigator.of(context).pop(),
              child: Text(cancelLabel!),
            ),
          AccessibleButton(
            label: confirmLabel,
            onPressed: () {
              onConfirm();
              Navigator.of(context).pop();
            },
            child: Text(confirmLabel),
          ),
        ],
      ),
    );
  }
}

/// Accessible Tab Bar
class AccessibleTabBar extends StatelessWidget {
  final List<String> labels;
  final int currentIndex;
  final ValueChanged<int> onTap;

  const AccessibleTabBar({
    Key? key,
    required this.labels,
    required this.currentIndex,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return TabBar(
      onTap: onTap,
      tabs: labels.asMap().entries.map((entry) {
        final index = entry.key;
        final label = entry.value;
        final isSelected = index == currentIndex;
        final semanticLabel = '$label tab, ${isSelected ? "selected" : "not selected"}';

        return Semantics(
          label: semanticLabel,
          selected: isSelected,
          button: true,
          child: Tab(text: label),
        );
      }).toList(),
    );
  }
}

/// Live Region for announcements
class LiveRegion extends StatelessWidget {
  final String message;
  final Widget child;

  const LiveRegion({
    Key? key,
    required this.message,
    required this.child,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: message,
      liveRegion: true,
      child: child,
    );
  }
}

/// Focus Trap for modal dialogs
class FocusTrap extends StatelessWidget {
  final Widget child;

  const FocusTrap({
    Key? key,
    required this.child,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Semantics(
      scopesRoute: true,
      namesRoute: true,
      child: child,
    );
  }
}

