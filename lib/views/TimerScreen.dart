import 'package:flutter/material.dart';
import 'package:programadoro/models/ElapsedTimeModel.dart';
import 'package:programadoro/storage/HistoryRepository.dart';
import 'package:programadoro/storage/Settings.dart';
import 'package:programadoro/views/Controlls.dart';
import 'package:programadoro/views/DurationSettingsDialog.dart';
import 'package:programadoro/views/StatsScreen.dart';
import 'package:programadoro/views/DurationOutput.dart';
import 'package:provider/provider.dart';

import 'TimeCounter.dart';
import 'dart:async';

import '../models/TimerModel.dart';
import '../models/TimerStates.dart';
import 'TimerScreenLogic.dart';

class TimerScreen extends StatefulWidget {
  const TimerScreen({Key? key}) : super(key: key);

  @override
  _TimerScreenState createState() => _TimerScreenState();
}

class _TimerScreenState extends State<TimerScreen> {
  void _tick() {
    var timerModel = context.read<TimerModel>();
    var elapsedTimeModel = context.read<ElapsedTimeModel>();

    tick(elapsedTimeModel, timerModel);
  }

  @override
  void initState() {
    super.initState();
    Timer.periodic(Duration(seconds: 1), (Timer t) => _tick());
    clearOldHistory();
  }

  String stateLabel(TimerModel watchTimerModel) {
    return watchTimerModel.state.toString();
  }

  Color backgroundColor(TimerModel watchTimerModel) {
    switch (watchTimerModel.state) {
      case TimerStates.sessionWorkingOvertime:
      case TimerStates.sessionRestingOvertime:
        {
          return Color(0xFFF08080);
        }
      case TimerStates.sessionWorking:
      case TimerStates.sessionResting:
      case TimerStates.noSession:
        {
          return Color(0xFFFFFFFF);
        }
    }
  }

  Widget proceedStageFab() {
    return FloatingActionButton(
      heroTag: "proceed-fab",
      onPressed: () {
        var timerModel = context.read<TimerModel>();
        var elapsedTimeModel = context.read<ElapsedTimeModel>();
        nextStage(elapsedTimeModel, timerModel);
      },
      child: Icon(Icons.skip_next),
      backgroundColor: Colors.green,
    );
  }

  Widget pauseResumeFab() {
    var watchTimerModel = context.read<TimerModel>();
    return FloatingActionButton(
      heroTag: "pause-resume-fab",
      onPressed: () {
        pauseResume(watchTimerModel);
      },
      child:
          watchTimerModel.isPaused ? Icon(Icons.play_arrow) : Icon(Icons.pause),
      backgroundColor: Colors.pink,
    );
  }

  Widget seeStatsButton() {
    return Container(
      margin: new EdgeInsets.only(left: 8, top: 8),
      child: ElevatedButton(
        child: Text('See stats'),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => StatsScreen()),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    var watchTimerModel = context.watch<TimerModel>();
    var settings = context.watch<Settings>();
    return Scaffold(
        backgroundColor: backgroundColor(watchTimerModel),
        appBar: AppBar(
          title: const Text('programadoro'),
        ),
        body: Stack(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                seeStatsButton(),
                Container(
                  margin: new EdgeInsets.only(right: 8, top: 8),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      DurationOutput(
                          duration: settings.workDuration,
                          label: "Work duration"),
                      DurationOutput(
                          duration: settings.restDuration,
                          label: "Rest duration"),
                      Container(
                        child: ElevatedButton(
                          child: Icon(Icons.settings),
                          onPressed: () async {
                            await showDialog<void>(
                              context: context,
                              builder: (BuildContext context) {
                                TextEditingController
                                    _workDurationInputController =
                                    TextEditingController();
                                TextEditingController
                                    _restDurationInputController =
                                    TextEditingController();
                                return DurationsSettingsDialog(
                                    settings: settings,
                                    workDurationInputController:
                                        _workDurationInputController,
                                    restDurationInputController:
                                        _restDurationInputController);
                              },
                            );
                          },
                        ),
                      )
                    ],
                  ),
                ),
              ],
            ),
            Center(
                child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Text(stateLabel(watchTimerModel)),
                TimerCounter(),
              ],
            ))
          ],
        ),
        floatingActionButton: FloatingActionButtons(
            expendIcon: Icon(Icons.timer),
            collapsedIcon: Icon(Icons.timer_off),
            distance: 112.0,
            onExpend: () {
              var timerModel = context.read<TimerModel>();
              var elapsedTimeModel = context.read<ElapsedTimeModel>();
              startSession(elapsedTimeModel, timerModel);
            },
            onCollapse: () {
              var timerModel = context.read<TimerModel>();
              var elapsedTimeModel = context.read<ElapsedTimeModel>();
              stopSession(elapsedTimeModel, timerModel);
            },
            children: [proceedStageFab(), pauseResumeFab()]));
  }

  @override
  void dispose() {
    notifiers.forEach((element) {
      element.dispose();
    });
    super.dispose();
  }
}
