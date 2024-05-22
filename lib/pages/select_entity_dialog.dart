import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SelectEntityDialog extends StatelessWidget {
  final List<DocumentSnapshot> accounts;
  final Function(DocumentSnapshot) onEntitySelected;

  const SelectEntityDialog({
    Key? key,
    required this.accounts,
    required this.onEntitySelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Select Device'),
      content: SingleChildScrollView(
        child: ListBody(
          children: accounts.map((account) {
            String email = account.id; // Use the document ID as the email
            return ListTile(
              title: Text(email),
              onTap: () {
                Navigator.of(context).pop();
                onEntitySelected(account);
              },
            );
          }).toList(),
        ),
      ),
    );
  }
}
