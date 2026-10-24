import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:scorely/core/theme/colors.dart';

class QuickTapActionBoard extends StatelessWidget {
  final String? selectedAction;
  final void Function(String action) onActionTap;

  const QuickTapActionBoard({
    super.key,
    required this.selectedAction,
    required this.onActionTap,
  });

  Widget _buildActionButton(String action) {
    final isSelected = selectedAction == action;
    Color buttonBg = isSelected ? AppColors.success : AppColors.darkCard2;
    Color textColor = isSelected ? Colors.black : Colors.white;

    if (action == 'W' && !isSelected) {
      buttonBg = AppColors.primary.withValues(alpha: 0.15);
      textColor = AppColors.primary;
    } else if ((action == '4' || action == '6') && !isSelected) {
      buttonBg = AppColors.success.withValues(alpha: 0.15);
      textColor = AppColors.success;
    }

    return Expanded(
      child: GestureDetector(
        onTap: () => onActionTap(action),
        child: Container(
          margin: const EdgeInsets.all(6),
          height: 60,
          decoration: BoxDecoration(
            color: buttonBg,
            borderRadius: BorderRadius.circular(30),
            border: Border.all(
              color: isSelected ? Colors.white : Colors.white.withValues(alpha: 0.05),
              width: 1.5,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: AppColors.success.withValues(alpha: 0.3),
                      blurRadius: 8,
                      spreadRadius: 2,
                    )
                  ]
                : null,
          ),
          alignment: Alignment.center,
          child: Text(
            action,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10.0),
      child: Column(
        children: [
          Row(
            children: [
              _buildActionButton('W'),
              _buildActionButton('WD'),
              _buildActionButton('NB'),
              _buildActionButton('B'),
              _buildActionButton('LB'),
            ],
          ),
          Row(
            children: [
              _buildActionButton('0'),
              _buildActionButton('1'),
              _buildActionButton('2'),
              _buildActionButton('3'),
            ],
          ),
          Row(
            children: [
              _buildActionButton('4'),
              _buildActionButton('5'),
              _buildActionButton('6'),
            ],
          ),
        ],
      ),
    );
  }
}
