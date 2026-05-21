import 'package:flutter/material.dart';

class TimeSlotPicker extends StatelessWidget {
  final List<String> slots;
  final List<String> bookedSlots;
  final String? selectedSlot;
  final ValueChanged<String> onSelected;

  const TimeSlotPicker({
    super.key,
    required this.slots,
    required this.bookedSlots,
    required this.selectedSlot,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: slots.map((slot) {
        final isBooked = bookedSlots.contains(slot);
        final isSelected = selectedSlot == slot;

        return GestureDetector(
          onTap: isBooked ? null : () => onSelected(slot),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: isSelected
                  ? const Color(0xFF4CAF50)
                  : isBooked
                      ? const Color(0xFF2A2A2A)
                      : const Color(0xFF1C2128),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isSelected
                    ? const Color(0xFF4CAF50)
                    : isBooked
                        ? Colors.transparent
                        : const Color(0xFF30363D),
              ),
            ),
            child: Text(
              slot,
              style: TextStyle(
                color: isSelected
                    ? Colors.white
                    : isBooked
                        ? Colors.white24
                        : Colors.white70,
                fontWeight:
                    isSelected ? FontWeight.bold : FontWeight.normal,
                decoration: isBooked ? TextDecoration.lineThrough : null,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}