import 'package:flutter/material.dart';
import '../providers/debt_provider.dart';
import 'debt_person_card.dart';

class DebtSearchDelegate extends SearchDelegate {
  final DebtProvider debtProvider;

  DebtSearchDelegate(this.debtProvider);

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.clear),
        onPressed: () {
          query = '';
        },
      ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () {
        close(context, null);
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    final results = debtProvider.allDebts
        .where((debt) => debt.name.toLowerCase().contains(query.toLowerCase()))
        .toList();
    return ListView.builder(
      itemCount: results.length,
      itemBuilder: (context, index) {
        final debt = results[index];
        return DebtPersonCard(
          debt: debt,
          onDelete: () => debtProvider.deleteDebt(debt.id!),
        );
      },
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return buildResults(context);
  }
}
