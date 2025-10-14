import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import '../services/api_service.dart';
import 'deposit_screen.dart';
import 'withdraw_screen.dart';

class AccountsScreen extends StatefulWidget {
  const AccountsScreen({super.key});

  @override
  State<AccountsScreen> createState() => _AccountsScreenState();
}

class _AccountsScreenState extends State<AccountsScreen> {
  final ApiService api = ApiService();
  bool _loading = true;
  List<Map<String, dynamic>> accounts = [];

  @override
  void initState() {
    super.initState();
    fetchAccounts();
  }

  Future<void> fetchAccounts() async {
    setState(() => _loading = true);
    try {
      final data = await api.getAccounts();
      if (!mounted) return;
      setState(() {
        accounts = data;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error fetching accounts: $e")),
      );
    }
  }

  void navigateDeposit(String accountId) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => DepositScreen(accountId: accountId)),
    ).then((_) => fetchAccounts());
  }

  void navigateWithdraw(String accountId) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => WithdrawScreen(accountId: accountId)),
    ).then((_) => fetchAccounts());
  }

  // Multi-step create account dialog
  void _showCreateAccountDialog() {
    final phoneController = TextEditingController();
    final targetController = TextEditingController();
    final planNoteController = TextEditingController();
    String planType = 'goal';
    int step = 0;
    bool submitting = false;

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setStateDialog) => AlertDialog(
          title: const Text("Add Savings Account"),
          content: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.6,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (step == 0)
                    TextField(
                      controller: phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(labelText: "Phone"),
                    ),
                  if (step == 1)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextField(
                          controller: targetController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                              labelText: "Target Amount"),
                        ),
                        const SizedBox(height: 8),
                        const Text("Plan Type:"),
                        RadioListTile<String>(
                          title: const Text("Goal"),
                          value: "goal",
                          groupValue: planType,
                          onChanged: (v) =>
                              setStateDialog(() => planType = v!),
                        ),
                        RadioListTile<String>(
                          title: const Text("Project"),
                          value: "project",
                          groupValue: planType,
                          onChanged: (v) =>
                              setStateDialog(() => planType = v!),
                        ),
                        TextField(
                          controller: planNoteController,
                          decoration:
                              const InputDecoration(labelText: "Note"),
                          maxLines: 2,
                        ),
                      ],
                    ),
                  if (submitting)
                    Padding(
                      padding: const EdgeInsets.only(top: 16.0),
                      child: Lottie.asset(
                        'assets/loader.json',
                        width: 50,
                        height: 50,
                      ),
                    ),
                ],
              ),
            ),
          ),
          actions: [
            if (step > 0)
              TextButton(
                onPressed: submitting
                    ? null
                    : () => setStateDialog(() => step--),
                child: const Text("Back"),
              ),
            TextButton(
              onPressed: submitting ? null : () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: submitting
                  ? null
                  : () async {
                      if (step == 0) {
                        if (phoneController.text.isEmpty) return;
                        setStateDialog(() => step = 1);
                      } else {
                        setStateDialog(() => submitting = true);
                        try {
                          final newAccount = await api.createAccount(
                            phoneController.text.trim(),
                            target: targetController.text.isEmpty
                                ? 0
                                : int.parse(targetController.text.trim()),
                            planType: planType,
                            planNote: planNoteController.text.trim(),
                          );
                          if (!mounted) return;
                          setState(() {
                            accounts.add(newAccount);
                          });
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text(
                                    "Savings account created successfully!")),
                          );
                        } catch (e) {
                          setStateDialog(() => submitting = false);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                                content: Text(
                                    "Failed to create savings account: $e")),
                          );
                        }
                      }
                    },
              child: Text(step == 0 ? "Next" : "Create Savings Account"),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Savings Accounts'),
        backgroundColor: Colors.blue.shade800,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: "Create Savings Account",
            onPressed: _showCreateAccountDialog,
          ),
        ],
      ),
      body: _loading
          ? Center(
              child: Lottie.asset(
                'assets/loader.json',
                width: 100,
                height: 100,
              ),
            )
          : accounts.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            "No Savings accounts found. Create one to start saving!",
                            style: TextStyle(fontSize: 16),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: _showCreateAccountDialog,
                            icon: const Icon(Icons.add),
                            label: const Text("Create Savings Account"),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: fetchAccounts,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: accounts.length,
                    itemBuilder: (_, index) {
                      final account = accounts[index];
                      final isMain = account['isMain'] == true;

                      return Card(
                        elevation: 4,
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        color: isMain
                            ? Colors.blue.shade100
                            : Colors.blue.shade50,
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    account['phone'],
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.blue.shade900,
                                    ),
                                  ),
                                  if (isMain)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: Colors.blue.shade700,
                                        borderRadius:
                                            BorderRadius.circular(8),
                                      ),
                                      child: const Text(
                                        'Main',
                                        style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Balance: ${(account['balance'] as num).toStringAsFixed(2)} TZS',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.blue.shade900,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(
                                    child: ElevatedButton.icon(
                                      onPressed: () =>
                                          navigateDeposit(account['id']),
                                      icon:
                                          const Icon(Icons.arrow_downward),
                                      label: const Text('Deposit'),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: ElevatedButton.icon(
                                      onPressed: () =>
                                          navigateWithdraw(account['id']),
                                      icon: const Icon(Icons.arrow_upward),
                                      label: const Text('Withdraw'),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
