import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../utilities/constants.dart';

class BirthdayGroupDropdown extends StatefulWidget {
  final Function(int) onValueChanged;

  BirthdayGroupDropdown({required this.onValueChanged});

  @override
  _BirthdayGroupDropdownState createState() => _BirthdayGroupDropdownState();
}

class _BirthdayGroupDropdownState extends State<BirthdayGroupDropdown> {
  late List<Map<String, dynamic>> _birthdayGroups;
  late int _selectedGroupId;

  @override
  void initState() {
    super.initState();
    _fetchBirthdayGroups();
  }

  Future<void> _fetchBirthdayGroups() async {
    try {
      final response = await http.get(Uri.parse(Constants.apiBaseUrl+'/BirthdayGroup'));
      if (response.statusCode == 200) {
        List<dynamic> data = json.decode(response.body);
        setState(() {
          _birthdayGroups = data.cast<Map<String, dynamic>>();
          _selectedGroupId = _birthdayGroups.isNotEmpty ? _birthdayGroups[0]['id'] : 0;
        });
      } else {
        throw Exception('Failed to load birthday groups');
      }
    } catch (e) {
      print('Error fetching birthday groups: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return DropdownButton<int>(
      value: _selectedGroupId,
      onChanged: (value) {
        setState(() {
          _selectedGroupId = value!;
        });
        widget.onValueChanged(value!);
      },
      items: _birthdayGroups.map<DropdownMenuItem<int>>((group) {
        return DropdownMenuItem<int>(
          value: group['id'],
          child: Text(group['name']),
        );
      }).toList(),
    );
  }
}
