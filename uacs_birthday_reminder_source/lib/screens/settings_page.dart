import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:path_provider/path_provider.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import '../../components/view_title.dart';
import '../../screens/about_page.dart';
import '../../utilities/constants.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> with WidgetsBindingObserver {
  TimeOfDay? _selectedTime;
  bool notiOneDayBefore = false;
  bool notiOneWeekBefore = false;
  bool notiOneMonthBefore = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadNotificationTime();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> _loadNotificationTime() async {
    try {
      final response = await http.get(Uri.parse('https://matejcho.com/api/BirthdaySetting/notification_time'));
      if (response.statusCode == 200) {
        var data = jsonDecode(response.body);
        List<String> parts = data['time'].split(':');
        if (mounted) {
          setState(() {
            _selectedTime = TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
          });
        }
      } else {
        print('Failed to load notification time. Status code: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching notification time: $e');
    }
  }

  Future<void> _saveNotificationTime() async {
    try {
      final response = await http.put(
        Uri.parse('https://matejcho.com/api/BirthdaySetting/notification_time'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'time': '${_selectedTime!.hour}:${_selectedTime!.minute}'})
      );
      if (response.statusCode == 200) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Notification time updated successfully!'))
          );
        }
      } else {
        print('Failed to update notification time. Status code: ${response.statusCode}');
      }
    } catch (e) {
      print('Error updating notification time: $e');
    }
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? TimeOfDay.now(),
    );
    if (pickedTime != null && pickedTime != _selectedTime) {
      if (mounted) {
        setState(() {
          _selectedTime = pickedTime;
        });
        _saveNotificationTime(); // Update on API
      }
    }
  }

  Future<void> _exportData() async {
    try {
      final response = await http.get(Uri.parse('https://matejcho.com/api/BirthdaySetting/export_data'));
      if (response.statusCode == 200) {
        final directory = await getApplicationDocumentsDirectory();
        final file = File('${directory.path}/birthday_data.json');
        await file.writeAsString(response.body);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Data exported successfully!'))
          );
        }
      } else {
        print('Failed to export data. Status code: ${response.statusCode}');
      }
    } catch (e) {
      print('Error exporting data: $e');
    }
  }

  Future<void> _importData() async {
    final result = await FilePicker.platform.pickFiles();
    if (result != null) {
      final file = File(result.files.single.path!);
      final data = await file.readAsString();
      try {
        final response = await http.put(
          Uri.parse('https://matejcho.com/api/BirthdaySetting/import_data'),
          headers: {'Content-Type': 'application/json'},
          body: data
        );
        if (response.statusCode == 200) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Data imported successfully!'))
            );
          }
        } else {
          print('Failed to import data. Status code: ${response.statusCode}');
        }
      } catch (e) {
        print('Error importing data: $e');
      }
    }
  }

  void requestNotificationAccess(BuildContext context) {
    AwesomeNotifications().requestPermissionToSendNotifications().then((_) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Constants.blackPrimary,
      appBar: appBar(),
      body: body(),
    );
  }

  AppBar appBar() {
    return AppBar(
      automaticallyImplyLeading: false,
      backgroundColor: Constants.blackPrimary,
      iconTheme: const IconThemeData(
        color: Constants.whiteSecondary,
      ),
      title: Text(
        AppLocalizations.of(context)!.settings,
        style: const TextStyle(
          color: Constants.purpleSecondary,
          fontSize: Constants.titleFontSize,
          fontWeight: FontWeight.bold,
        ),
      ),
      actions: [
        infoButton(context),
      ],
      leading: backButton(context),
    );
  }

  GestureDetector backButton(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      child: Container(
        margin: const EdgeInsets.only(left: 15),
        child: const Icon(
          Icons.arrow_back,
          size: 30,
        ),
      ),
      onTap: () {
        Navigator.pop(context);
      },
    );
  }

  GestureDetector infoButton(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      child: Container(
        margin: const EdgeInsets.only(right: 15),
        child: const Icon(
          Icons.info_outline,
          size: 30,
        ),
      ),
      onTap: () {
        Navigator.of(context).push(MaterialPageRoute(
          builder: (BuildContext context) {
            return const AboutPage();
          },
        ));
      },
    );
  }

  Widget body() {
    return Container(
      margin: const EdgeInsets.only(top: 20),
      child: Column(
        children: [
          ViewTitle(AppLocalizations.of(context)!.notifications),
          activateNotificationBanner(),
          Container(
            margin: const EdgeInsets.only(right: 50, left: 50, bottom: 30),
            child: Column(
              children: [
                notificationOneDayBefore(),
                notificationOneWeekBefore(),
                notificationOneMonthBefore(),
              ],
            ),
          ),
          ViewTitle(AppLocalizations.of(context)!.notificationTime),
          Container(
            margin: const EdgeInsets.only(right: 50, left: 50, bottom: 30),
            child: Column(
              children: [
                notificationsTimeSetting(),
              ],
            ),
          ),
          ViewTitle(AppLocalizations.of(context)!.exportImport),
          ListTile(
            title: const Text('Export Data'),
            onTap: _exportData,
          ),
          ListTile(
            title: const Text('Import Data'),
            onTap: _importData,
          ),
        ],
      ),
    );
  }

  FutureBuilder<bool> activateNotificationBanner() {
    return FutureBuilder(
      future: AwesomeNotifications().isNotificationAllowed(),
      builder: (context, snapshot) {
        if (snapshot.hasData && !(snapshot.data as bool)) {
          return infoText();
        }
        return Container();
      },
    );
  }

  Widget infoText() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Container(
        decoration: const BoxDecoration(
          color: Constants.darkGreySecondary,
          borderRadius: BorderRadius.all(Radius.circular(5)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  AppLocalizations.of(context)!.allowNotifications,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Constants.lighterGrey,
                    fontSize: Constants.smallerFontSize + 2,
                  ),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: ElevatedButton(
                  onPressed: (() => requestNotificationAccess(context)),
                  child: Text(
                    AppLocalizations.of(context)!.activate,
                    style: const TextStyle(
                      fontSize: Constants.smallerFontSize + 2,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Row notificationsTimeSetting() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          AppLocalizations.of(context)!.timeForNotification,
          style: const TextStyle(
            color: Constants.whiteSecondary,
            fontSize: Constants.normalFontSize,
          ),
        ),
        const Spacer(),
        GestureDetector(
          onTap: () => _selectTime(context),
          child: Container(
            width: 70,
            height: 55,
            decoration: BoxDecoration(
              color: Constants.lighterGrey,
              borderRadius: BorderRadius.circular(8),
            ),
            alignment: Alignment.center,
            child: Text(
              _selectedTime?.format(context) ?? 'Set Time',
              style: const TextStyle(
                color: Constants.whiteSecondary,
                fontSize: 16,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Row notificationOneDayBefore() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          AppLocalizations.of(context)!.oneDayBefore,
          style: const TextStyle(
            color: Constants.whiteSecondary,
            fontSize: Constants.normalFontSize,
          ),
        ),
        const Spacer(),
        SizedBox(
          width: 70,
          height: 55,
          child: FittedBox(
            fit: BoxFit.fill,
            child: Switch(
              value: notiOneDayBefore,
              onChanged: (value) {
                if (mounted) {
                  setState(() {
                    notiOneDayBefore = value;
                  });
                }
              },
              inactiveThumbColor: Constants.lighterGrey,
              inactiveTrackColor: Constants.darkGreySecondary,
            ),
          ),
        ),
      ],
    );
  }

  Row notificationOneWeekBefore() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          AppLocalizations.of(context)!.oneWeekBefore,
          style: const TextStyle(
            color: Constants.whiteSecondary,
            fontSize: Constants.normalFontSize,
          ),
        ),
        const Spacer(),
        SizedBox(
          width: 70,
          height: 55,
          child: FittedBox(
            fit: BoxFit.fill,
            child: Switch(
              value: notiOneWeekBefore,
              onChanged: (value) {
                if (mounted) {
                  setState(() {
                    notiOneWeekBefore = value;
                  });
                }
              },
              inactiveThumbColor: Constants.lighterGrey,
              inactiveTrackColor: Constants.darkGreySecondary,
            ),
          ),
        ),
      ],
    );
  }

  Row notificationOneMonthBefore() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          AppLocalizations.of(context)!.oneMonthBefore,
          style: const TextStyle(
            color: Constants.whiteSecondary,
            fontSize: Constants.normalFontSize,
          ),
        ),
        const Spacer(),
        SizedBox(
          width: 70,
          height: 55,
          child: FittedBox(
            fit: BoxFit.fill,
            child: Switch(
              value: notiOneMonthBefore,
              onChanged: (value) {
                if (mounted) {
                  setState(() {
                    notiOneMonthBefore = value;
                  });
                }
              },
              inactiveThumbColor: Constants.lighterGrey,
              inactiveTrackColor: Constants.darkGreySecondary,
            ),
          ),
        ),
      ],
    );
  }
}

