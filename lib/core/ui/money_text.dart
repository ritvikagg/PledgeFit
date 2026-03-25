import 'package:flutter/material.dart';

import '../money.dart';

class MoneyText extends StatelessWidget {
  final Money money;
  final TextStyle? style;
  final bool bold;

  const MoneyText(
    this.money, {
    super.key,
    this.style,
    this.bold = false,
  });

  @override
  Widget build(BuildContext context) {
    final resolved = style ??
        Theme.of(context).textTheme.bodyLarge?.copyWith(
              fontWeight: bold ? FontWeight.w600 : FontWeight.w400,
            );
    return Text(
      money.format(),
      style: resolved,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }
}

