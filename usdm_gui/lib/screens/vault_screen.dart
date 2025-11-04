import 'package:flutter/material.dart';
import 'package:usdm_gui/services/api_client.dart';
import 'package:flutter/services.dart';
import 'package:usdm_gui/screens/home_page.dart';

class VaultScreen extends StatefulWidget {
  const VaultScreen({super.key});

  @override
  State<VaultScreen> createState() => _VaultScreenState();
}

class _VaultScreenState extends State<VaultScreen> {
  bool _loading = true;
  List<Map<String, dynamic>> _items = [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    try {
      await ApiClient().loadToken();
      await _loadItems();
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    }
  }

  Future<void> _loadItems() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final items = await ApiClient().listVault();
      setState(() {
        _items = items;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _addItemDialog() async {
    final titleCtrl = TextEditingController();
    final userCtrl = TextEditingController();
    final urlCtrl = TextEditingController();
    final passCtrl = TextEditingController();
    final notesCtrl = TextEditingController();

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Add Vault Item'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: 'Title')),
                TextField(controller: userCtrl, decoration: const InputDecoration(labelText: 'Username')),
                TextField(controller: urlCtrl, decoration: const InputDecoration(labelText: 'URL')),
                TextField(controller: passCtrl, decoration: const InputDecoration(labelText: 'Password'), obscureText: true),
                TextField(controller: notesCtrl, decoration: const InputDecoration(labelText: 'Notes')),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
            ElevatedButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Save')),
          ],
        );
      },
    );

    if (ok == true) {
      try {
        await ApiClient().addVaultItem(
          title: titleCtrl.text.trim(),
          username: userCtrl.text.trim().isEmpty ? null : userCtrl.text.trim(),
          url: urlCtrl.text.trim().isEmpty ? null : urlCtrl.text.trim(),
          password: passCtrl.text,
          notes: notesCtrl.text.trim().isEmpty ? null : notesCtrl.text.trim(),
        );
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Item saved'), backgroundColor: Colors.green),
        );
        await _loadItems();
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _deleteItem(int id) async {
    try {
      await ApiClient().deleteVaultItem(id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Deleted'), backgroundColor: Colors.green),
      );
      await _loadItems();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Vault'),
        actions: [
          IconButton(
            tooltip: 'Logout',
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await ApiClient().clearToken();
              if (!mounted) return;
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const HomePage()),
                (route) => false,
              );
            },
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : RefreshIndicator(
                  onRefresh: _loadItems,
                  child: ListView.separated(
                    physics: const AlwaysScrollableScrollPhysics(),
                    itemCount: _items.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (ctx, i) {
                      final it = _items[i];
                      return ListTile(
                        title: Text(it['title'] ?? ''),
                        subtitle: Text(it['username'] ?? ''),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              tooltip: 'Copy password',
                              icon: const Icon(Icons.copy),
                              onPressed: () async {
                                final pw = (it['password'] ?? '').toString();
                                if (pw.isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('No password available')), 
                                  );
                                  return;
                                }
                                await Clipboard.setData(ClipboardData(text: pw));
                                if (!mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Password copied')), 
                                );
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _deleteItem((it['id'] as num).toInt()),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addItemDialog,
        child: const Icon(Icons.add),
      ),
    );
  }
}
