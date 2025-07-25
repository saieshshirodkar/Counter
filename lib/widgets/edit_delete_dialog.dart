import 'package:flutter/material.dart';

class EditDeleteDialog extends StatelessWidget {
  final String counterName;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onReorder;

  const EditDeleteDialog({
    Key? key,
    required this.counterName,
    required this.onEdit,
    required this.onDelete,
    required this.onReorder,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(counterName),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.edit),
            title: const Text('Edit'),
            onTap: () {
              Navigator.of(context).pop();
              onEdit();
            },
          ),
          ListTile(
            leading: const Icon(Icons.delete),
            title: const Text('Delete'),
            onTap: () {
              Navigator.of(context).pop();
              onDelete();
            },
          ),
          ListTile(
            leading: const Icon(Icons.reorder),
            title: const Text('Reorder'),
            onTap: () {
              Navigator.of(context).pop();
              onReorder();
            },
          ),
        ],
      ),
    );
  }
}
