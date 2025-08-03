import 'package:flutter/material.dart';
import 'db_helper.dart';

class DatabaseScreen extends StatefulWidget {
  const DatabaseScreen({Key? key}) : super(key: key);

  @override
  State<DatabaseScreen> createState() => _DatabaseScreenState();
}

class _DatabaseScreenState extends State<DatabaseScreen> {
  final DBHelper dbHelper = DBHelper();
  Map<String, List<Map<String, dynamic>>> allTableData = {};
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchAllTablesAndData();
  }

  Future<void> fetchAllTablesAndData() async {
    try {
      List<String> tables = await dbHelper.getAllTables();

      if (tables.isEmpty) {
        print("⚠️ No tables found.");
        setState(() {
          isLoading = false;
        });
        return;
      }

      for (String table in tables) {
        List<Map<String, dynamic>> rows = await dbHelper.getAllRows(table);

        print("📋 Table: $table");
        for (var row in rows) {
          print("   ➤ $row");
        }

        allTableData[table] = rows;
      }

      setState(() {
        isLoading = false;
      });
    } catch (e) {
      print("❌ Error: $e");
      setState(() {
        isLoading = false;
      });
    }
  }

  Widget buildTable(String tableName, List<Map<String, dynamic>> rows) {
    if (rows.isEmpty) {
      return Text("No data in $tableName");
    }

    List<String> columns = rows.first.keys.toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '📋 Table: $tableName',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            columns: columns.map((col) => DataColumn(label: Text(col))).toList(),
            rows: rows.map((row) {
              return DataRow(
                cells: columns.map((col) {
                  return DataCell(Text(row[col].toString()));
                }).toList(),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Database Viewer"),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : allTableData.isEmpty
          ? const Center(child: Text("No tables found in the database."))
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: allTableData.entries
              .map((entry) => buildTable(entry.key, entry.value))
              .toList(),
        ),
      ),
    );
  }
}
