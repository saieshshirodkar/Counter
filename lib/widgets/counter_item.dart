import 'package:flutter/material.dart';
import '../models/counter.dart';
import '../models/enums/counter_shape.dart';

class CounterItem extends StatelessWidget {
  final Counter counter;
  final CounterShape counterShape;
  final bool isReorderMode;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;
  final VoidCallback onSet;
  final VoidCallback onEdit;

  const CounterItem({
    required Key key,
    required this.counter,
    required this.counterShape,
    required this.isReorderMode,
    required this.onIncrement,
    required this.onDecrement,
    required this.onSet,
    required this.onEdit,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      key: key,
      color: counter.color.withOpacity(0.2),
      shape: counterShape == CounterShape.circle
          ? const CircleBorder()
          : RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onLongPress: isReorderMode ? null : onEdit,
        borderRadius: counterShape == CounterShape.circle
            ? BorderRadius.circular(100)
            : BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    counter.name,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox.shrink(),
                ],
              ),
              Expanded(
                child: Center(
                  child: GestureDetector(
                    onDoubleTap: onSet,
                    child: FittedBox(
                      fit: BoxFit.contain,
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 250),
                        transitionBuilder:
                            (Widget child, Animation<double> animation) {
                          return ScaleTransition(
                            scale: animation,
                            child: child,
                          );
                        },
                        child: Text(
                          '${counter.value}',
                          key: ValueKey<int>(counter.value),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 60,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.remove),
                    onPressed: onDecrement,
                    splashRadius: 24,
                  ),
                  const SizedBox(width: 32),
                  IconButton(
                    icon: const Icon(Icons.add),
                    onPressed: onIncrement,
                    splashRadius: 24,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
