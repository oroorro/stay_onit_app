import 'package:flutter/material.dart';
import 'app_state.dart';

class StateManagerModel extends ChangeNotifier {

  AppState _currentState = AppState.none;

  AppState get currentState => _currentState;

  void updateCurrentState(AppState newState) {
    print("newState is :${newState}");
    _currentState = newState;
    notifyListeners();
  }
}