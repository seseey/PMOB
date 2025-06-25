import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ChangeProfilPage extends StatefulWidget {
  @override
  _ChangeProfilPageState createState() => _ChangeProfilPageState();
}

class _ChangeProfilPageState extends State<ChangeProfilPage> {
  final TextEditingController _usernameController = TextEditingController();
  bool _isSaving = false;

  Future<void> _saveUsername() async {
    final newUsername = _usernameController.text.trim();
    if (newUsername.isEmpty) return;

    setState(() => _isSaving = true);

    try {
      final supabase = Supabase.instance.client;
      final user = supabase.auth.currentUser;

      if (user != null) {
        final response =
            await supabase
                .from('Users')
                .update({'username': newUsername})
                .eq('id', user.id)
                .select()
                .maybeSingle();

        if (response == null) {
          throw 'Tidak bisa mendapatkan respons dari server.';
        }

        // Periksa apakah response berisi error melalui null response
        if (response.isEmpty) {
          throw 'Username gagal diperbarui.';
        }

        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Username berhasil diperbarui')));
        Navigator.pop(context);
      } else {
        throw 'User tidak ditemukan.';
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Gagal mengganti username: $e')));
    } finally {
      setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Change Username'),
        backgroundColor: const Color(0xFFA7B59E),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _usernameController,
              decoration: InputDecoration(
                labelText: 'New Username',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xCC2E8B57),
              ),
              onPressed: _isSaving ? null : _saveUsername,
              child:
                  _isSaving
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Save Changes'),
            ),
          ],
        ),
      ),
    );
  }
}
