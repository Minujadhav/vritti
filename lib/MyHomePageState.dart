
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'db_helper/DatabaseHelper.dart';


class Employee {
  final int id;
  late final String email;
  late final String firstName;
  late final String lastName;
  final String avatar;

  Employee({
    required this.id,
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.avatar,
  });

  factory Employee.fromJson(Map<String, dynamic> json) {
    return Employee(
      id: json['id'],
      email: json['email'],
      firstName: json['first_name'],
      lastName: json['last_name'],
      avatar: json['avatar'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'email': email,
      'first_name': firstName,
      'last_name': lastName,
      'avatar': avatar,
    };
  }

  factory Employee.fromMap(Map<String, dynamic> map) {
    return Employee(
      id: map['id'],
      email: map['email'],
      firstName: map['first_name'],
      lastName: map['last_name'],
      avatar: map['avatar'],
    );
  }
}

class EmployeeListScreen extends StatelessWidget {
  final List<Employee> employees;

  const EmployeeListScreen({required this.employees});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: employees.length,
      itemBuilder: (context, index) {
        final employee = employees[index];
        return ListTile(
          leading: CircleAvatar(
            backgroundImage: NetworkImage(employee.avatar),
          ),
          title: Text(employee.firstName + ' ' + employee.lastName),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => EmployeeDetailsScreen(employee: employee),
              ),
            );
          },
        );
      },
    );
  }
}
class EmployeesScreen extends StatefulWidget {
  @override
  _EmployeesScreenState createState() => _EmployeesScreenState();
}

class _EmployeesScreenState extends State<EmployeesScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late Future<List<Employee>> _employees;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this);
    _employees = fetchEmployees();
  }

  Future<List<Employee>> fetchEmployees() async {
    final url = Uri.parse('https://reqres.in/api/users?page=1');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final jsonBody = jsonDecode(response.body);
      final List<dynamic> data = jsonBody['data'];

      final List<Employee> employees = data.map((jsonEmployee) {
        return Employee.fromJson(jsonEmployee);
      }).toList();

      return employees;
    } else {
      throw Exception('Failed to fetch employees');
    }
  }

  Future<void> _refreshEmployees() async {
    List<Employee> refreshedEmployees = [];

    for (int i = 1; i <= 6; i++) {
      final employee = await fetchEmployee(i);
      refreshedEmployees.add(employee);
    }

    setState(() {
      _employees = Future.value(refreshedEmployees);
    });
  }

  Future<Employee> fetchEmployee(int employeeId) async {
    final url = Uri.parse('https://reqres.in/api/users/$employeeId');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final jsonBody = jsonDecode(response.body);
      final dynamic data = jsonBody['data'];

      return Employee.fromJson(data);
    } else {
      throw Exception('Failed to fetch employee $employeeId');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Home Page'),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: 'Employee 1'),
            Tab(text: 'Employee 2'),
            Tab(text: 'Employee 3'),
            Tab(text: 'Employee 4'),
            Tab(text: 'Employee 5'),
            Tab(text: 'Employee 6'),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _refreshEmployees,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshEmployees,
        child: FutureBuilder<List<Employee>>(
          future: _employees,
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              final employees = snapshot.data!;
              return TabBarView(
                controller: _tabController,
                children: employees.map((employee) {
                  return EmployeeDetailsScreen(employee: employee);
                }).toList(),
              );
            } else if (snapshot.hasError) {
              return Center(child: Text('Failed to fetch employees'));
            }
            return Center(child: CircularProgressIndicator());
          },
        ),
      ),
    );
  }
}

class EmployeeDetailsScreen extends StatelessWidget {
  final Employee employee;

  EmployeeDetailsScreen({required this.employee});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircleAvatar(
            backgroundImage: NetworkImage(employee.avatar),
            radius: 50,
          ),
          SizedBox(height: 8),
          Text('ID: ${employee.id}'),
          SizedBox(height: 8),
          Text('Email: ${employee.email}'),
          SizedBox(height: 16),
          Text('First Name: ${employee.firstName}'),
          SizedBox(height: 8),
          Text('Last Name: ${employee.lastName}'),
          SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              // Navigate to the EditEmployeePage
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => EditEmployeePage(employee: employee),
                ),
              );
            },
            child: Text('Edit Employee'),
          ),
          ElevatedButton(
            onPressed: () async {
              // Delete employee from the local database
              await DatabaseHelper().deleteEmployee(employee.id);
              Navigator.pop(context); // Go back to the previous screen
            },
            child: Text('Delete Employee'),
          ),
        ],
      ),
    );
  }
}
