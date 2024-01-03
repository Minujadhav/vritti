import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:vritti_task/MyHomePageState.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();

  factory DatabaseHelper() => _instance;

  DatabaseHelper._internal();

  late Database _database;

  Future<void> initializeDatabase() async {
    final path = await getDatabasesPath();
    final databasePath = join(path, 'employees.db');

    _database = await openDatabase(
      databasePath,
      version: 1,
      onCreate: (db, version) {
        db.execute('''
          CREATE TABLE employees (
            id INTEGER PRIMARY KEY,
            email TEXT,
            first_name TEXT,
            last_name TEXT,
            avatar TEXT
          )
        ''');
      },
    );
  }

  Future<void> insertEmployee(Employee employee) async {
    await _database.insert('employees', employee.toMap());
  }

  Future<void> updateEmployee(Employee employee) async {
    await _database.update(
      'employees',
      employee.toMap(),
      where: 'id = ?',
      whereArgs: [employee.id],
    );
  }

  Future<void> deleteEmployee(int id) async {
    await _database.delete('employees', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Employee>> getEmployees() async {
    final List<Map<String, dynamic>> maps = await _database.query('employees');
    return List.generate(maps.length, (index) => Employee.fromMap(maps[index]));
  }
}







class EditEmployeePage extends StatefulWidget {
  final Employee employee;

  EditEmployeePage({required this.employee});

  @override
  _EditEmployeePageState createState() => _EditEmployeePageState();
}

class _EditEmployeePageState extends State<EditEmployeePage> {
  late TextEditingController firstNameController;
  late TextEditingController lastNameController;
  late TextEditingController emailController;

  @override
  void initState() {
    super.initState();

    // Initialize controllers with existing employee details
    firstNameController = TextEditingController(text: widget.employee.firstName);
    lastNameController = TextEditingController(text: widget.employee.lastName);
    emailController = TextEditingController(text: widget.employee.email);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Edit Employee'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Editing Employee: ${widget.employee.firstName} ${widget.employee.lastName}'),
            SizedBox(height: 16),
            TextFormField(
              controller: firstNameController,
              decoration: InputDecoration(labelText: 'First Name'),
            ),
            SizedBox(height: 16),
            TextFormField(
              controller: lastNameController,
              decoration: InputDecoration(labelText: 'Last Name'),
            ),
            SizedBox(height: 16),
            TextFormField(
              controller: emailController,
              decoration: InputDecoration(labelText: 'Email'),
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                // Save the edited details immediately
                saveChanges();

                // Optionally, you can display a message to indicate the changes were saved
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Changes saved successfully'),
                  ),
                );

                // Pop the page
                Navigator.pop(context);
              },
              child: Text('Save Changes'),
            ),
          ],
        ),
      ),
    );
  }

  void saveChanges() async {
    // Update the employee object with the edited details
    widget.employee.firstName = firstNameController.text;
    widget.employee.lastName = lastNameController.text;
    widget.employee.email = emailController.text;

    // Update the employee in the local database
    await DatabaseHelper().updateEmployee(widget.employee);

    // Optionally, you can display a message to indicate the changes were saved
    ScaffoldMessenger.of(context as BuildContext).showSnackBar(
      SnackBar(
        content: Text('Changes saved successfully'),
      ),
    );
  }


  @override
  void dispose() {
    // Dispose of controllers to avoid memory leaks
    firstNameController.dispose();
    lastNameController.dispose();
    emailController.dispose();
    super.dispose();
  }
}
