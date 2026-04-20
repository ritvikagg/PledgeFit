import 'package:flutter/material.dart';

import '../../theme/pledge_colors.dart';

/// Primary CTA with brand gradient — use for hero actions (e.g. onboarding).
class PledgeGradientCtaButton extends StatelessWidget {
  const PledgeGradientCtaButton({
    super.key,
    required this.label,
    this.onPressed,
    this.trailingIcon = Icons.chevron_right_rounded,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData trailingIcon;

  @override
  Widget build(BuildContext context) {
    final disabled = onPressed == null;
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: disabled
                ? [
                    PledgeColors.inkSoft,
                    PledgeColors.inkSoft,
                  ]
                : [
                    PledgeColors.primaryGreen,
                    PledgeColors.primaryGreenDark,
                  ],
          ),
          boxShadow: disabled
              ? null
              : [
                  BoxShadow(
                    color: PledgeColors.primaryGreen.withValues(alpha: 0.35),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onPressed,
            borderRadius: BorderRadius.circular(16),
            child: Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(trailingIcon, color: Colors.white, size: 22),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class PledgePrimaryButton extends StatelessWidget {
  const PledgePrimaryButton({
    super.key,
    required this.label,
    this.icon,
    this.onPressed,
    this.isLoading = false,
  });

  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: FilledButton(
        onPressed: onPressed == null || isLoading ? null : onPressed,
        child: isLoading
            ? const SizedBox(
                height: 22,
                width: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: 22),
                    const SizedBox(width: 10),
                  ],
                  Text(label),
                ],
              ),
      ),
    );
  }
}

class PledgeSecondaryButton extends StatelessWidget {
  const PledgeSecondaryButton({
    super.key,
    required this.label,
    this.onPressed,
  });

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: FilledButton(
        style: FilledButton.styleFrom(
          backgroundColor: PledgeColors.secondaryButtonBg,
          foregroundColor: PledgeColors.ink,
        ),
        onPressed: onPressed,
        child: Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
      ),
    );
  }
}
