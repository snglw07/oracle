import 'package:flutter/material.dart';

/// Flutter AlertDialog and SimpleDialog
///http://androidkt.com/flutter-alertdialog-example/
Future<void> _ackAlert(BuildContext context) {
  return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
            title: Text('Not in stock'),
            content: const Text('This item is no longer available'),
            actions: <Widget>[
              ElevatedButton(
                  child: Text('Ok'),
                  onPressed: () {
                    Navigator.of(context).pop();
                  })
            ]);
      });
}

enum ConfirmAction { CANCEL, ACCEPT }

Future<ConfirmAction?> _asyncConfirmDialog(BuildContext context) async {
  return showDialog<ConfirmAction>(
      context: context,
      barrierDismissible: false, // user must tap button for close dialog!
      builder: (BuildContext context) {
        return AlertDialog(
            title: Text('Reset settings?'),
            content: Text(
                'This will reset your device to its default factory settings.'),
            actions: <Widget>[
              ElevatedButton(
                  child: Text('CANCEL'),
                  onPressed: () {
                    Navigator.of(context).pop(ConfirmAction.CANCEL);
                  }),
              ElevatedButton(
                  child: Text('ACCEPT'),
                  onPressed: () {
                    Navigator.of(context).pop(ConfirmAction.ACCEPT);
                  })
            ]);
      });
}

Future<String?> _asyncInputDialog(BuildContext context) async {
  String teamName = '';
  return showDialog<String>(
      context: context,
      barrierDismissible:
          false, // dialog is dismissible with a tap on the barrier
      builder: (BuildContext context) {
        return AlertDialog(
            title: Text('Enter current team'),
            content: Row(children: <Widget>[
              Expanded(
                  child: TextField(
                      autofocus: true,
                      decoration: InputDecoration(
                          labelText: 'Team Name',
                          hintText: 'eg. Juventus F.C.'),
                      onChanged: (value) {
                        teamName = value;
                      }))
            ]),
            actions: <Widget>[
              ElevatedButton(
                  child: Text('Ok'),
                  onPressed: () {
                    Navigator.of(context).pop(teamName);
                  })
            ]);
      });
}

enum Departments { Production, Research, Purchasing, Marketing, Accounting }

Future<Departments?> _asyncSimpleDialog(BuildContext context) async {
  return await showDialog<Departments>(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return SimpleDialog(
            title: const Text('Select Departments '),
            children: <Widget>[
              SimpleDialogOption(
                  onPressed: () {
                    Navigator.pop(context, Departments.Production);
                  },
                  child: const Text('Production')),
              SimpleDialogOption(
                  onPressed: () {
                    Navigator.pop(context, Departments.Research);
                  },
                  child: const Text('Research')),
              SimpleDialogOption(
                  onPressed: () {
                    Navigator.pop(context, Departments.Purchasing);
                  },
                  child: const Text('Purchasing')),
              SimpleDialogOption(
                  onPressed: () {
                    Navigator.pop(context, Departments.Marketing);
                  },
                  child: const Text('Marketing')),
              SimpleDialogOption(
                  onPressed: () {
                    Navigator.pop(context, Departments.Accounting);
                  },
                  child: const Text('Accounting'))
            ]);
      });
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(title: Text("Dialog")),
        body: Center(
            child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
              ElevatedButton(
                  onPressed: () {
                    _ackAlert(context);
                  },
                  child: const Text("Ack Dialog")),
              ElevatedButton(
                  onPressed: () async {
                    final ConfirmAction? action =
                        await _asyncConfirmDialog(context);
                    print("Confirm Action $action");
                  },
                  child: const Text("Confirm Dialog")),
              ElevatedButton(
                  onPressed: () async {
                    final Departments? deptName =
                        await _asyncSimpleDialog(context);
                    print("Selected Departement is $deptName");
                  },
                  child: const Text("Simple dialog")),
              ElevatedButton(
                  onPressed: () async {
                    final String? currentTeam =
                        await _asyncInputDialog(context);
                    print("Current team name is $currentTeam");
                  },
                  child: const Text("Input Dialog"))
            ])));
  }
}

void main() {
  runApp(MaterialApp(home: MyApp()));
}
