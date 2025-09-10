import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class DataHumanScreen extends StatefulWidget {
  @override
  _DataHumanScreenState createState() => _DataHumanScreenState();
}

class _DataHumanScreenState extends State<DataHumanScreen> {
  final String apiUrl = 'https://sugarcane-czzs8k3ah-suphachais-projects-d3438f04.vercel.app/pulluser';
  List<Map<String, dynamic>> _users = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchData();
  }

  Future<void> fetchData() async {
    try {
      final response = await http.get(Uri.parse(apiUrl));

      if (response.statusCode == 200) {
        final List<dynamic> jsonData = jsonDecode(response.body);
        setState(() {
          _users = jsonData.cast<Map<String, dynamic>>();
          _isLoading = false;
        });
      } else {
        print('Error: ${response.statusCode}');
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error fetching data: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _editUser(Map<String, dynamic> user) {
    final TextEditingController _nameController =
    TextEditingController(text: user['name']);
    final TextEditingController _emailController =
    TextEditingController(text: user['email']);
    final TextEditingController _numberController =
    TextEditingController(text: user['number']?.toString());
    final TextEditingController _usernameController =
    TextEditingController(text: user['username']);
    final TextEditingController _passwordController =
    TextEditingController(text: user['password']);
    String selectedMenu = user['menu']?.toString() ?? '1';

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('แก้ไขข้อมูลสมาชิก'),
          content: SingleChildScrollView(
            child: Column(
              children: [
                TextField(
                  controller: _nameController,
                  decoration: InputDecoration(labelText: 'ชื่อ'),
                ),
                TextField(
                  controller: _emailController,
                  decoration: InputDecoration(labelText: 'อีเมล'),
                ),
                TextField(
                  controller: _numberController,
                  decoration: InputDecoration(labelText: 'เบอร์โทร'),
                  keyboardType: TextInputType.number,
                ),
                TextField(
                  controller: _usernameController,
                  decoration: InputDecoration(labelText: 'ชื่อผู้ใช้'),
                ),
                TextField(
                  controller: _passwordController,
                  decoration: InputDecoration(labelText: 'รหัสผ่าน'),
                  obscureText: true,
                ),
                DropdownButtonFormField<String>(
                  value: selectedMenu,
                  items: ['1', '2', '3']
                      .map((menu) => DropdownMenuItem(
                    value: menu,
                    child: Text('Menu $menu'),
                  ))
                      .toList(),
                  onChanged: (value) {
                    selectedMenu = value!;
                  },
                  decoration: InputDecoration(labelText: 'เลือกเมนู'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text('ยกเลิก'),
            ),
            TextButton(
              onPressed: () async {
                await _updateUser(
                  user['_id'],
                  _nameController.text,
                  _emailController.text,
                  int.tryParse(_numberController.text) ?? 0,
                  _usernameController.text,
                  _passwordController.text,
                  int.parse(selectedMenu),
                );
                Navigator.pop(context);
              },
              child: Text('บันทึก'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _updateUser(
      String userId,
      String name,
      String email,
      int number,
      String username,
      String password,
      int menu,
      ) async {
    final updateUrl = 'https://sugarcane-czzs8k3ah-suphachais-projects-d3438f04.vercel.app/updateuser/$userId';
    try {
      final response = await http.put(
        Uri.parse(updateUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'name': name,
          'email': email,
          'number': number,
          'username': username,
          'password': password,
          'menu': menu,
        }),
      );

      if (response.statusCode == 200) {
        fetchData();
      } else {
        print('Error updating user: ${response.statusCode}');
      }
    } catch (e) {
      print('Error updating user: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('จัดการข้อมูลสมาชิก'),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : ListView.builder(
        itemCount: _users.length,
        itemBuilder: (context, index) {
          final user = _users[index];
          return Card(
            child: ListTile(
              title: Text(user['name'] ?? 'ไม่มีชื่อ'),
              subtitle: Text(
                'อีเมล: ${user['email'] ?? 'ไม่มีข้อมูล'}\n'
                    'เบอร์โทร: ${user['number'] ?? 'ไม่มีข้อมูล'}\n'
                    'เมนู: ${user['menu'] ?? 'ไม่ระบุ'}',
              ),
              trailing: IconButton(
                icon: Icon(Icons.edit),
                onPressed: () => _editUser(user),
              ),
            ),
          );
        },
      ),
    );
  }
}
