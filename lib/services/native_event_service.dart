import 'package:flutter/services.dart';

class NativeEventService {
  static const EventChannel _eventChannel = EventChannel('fylgja/events');
  
  /// Listen for events from the native Android service
  static Stream<String> get eventStream {
    return _eventChannel.receiveBroadcastStream().cast<String>();
  }
}


