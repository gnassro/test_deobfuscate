import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:native_stack_traces/native_stack_traces.dart';


// i took this code from flutter project when running 'flutter symbolize'


typedef SymbolsTransformer = StreamTransformer<String, String> Function(Uint8List);

StreamTransformer<String, String> _defaultTransformer(Uint8List symbols) {
  final Dwarf? dwarf = Dwarf.fromBytes(symbols);
  if (dwarf == null) {
    throw Exception('Failed to decode symbols file');
  }
  return DwarfStackTraceDecoder(dwarf, includeInternalFrames: true);
}

// A no-op transformer for `DwarfSymbolizationService.test`
StreamTransformer<String, String> _testTransformer(Uint8List buffer) {
  return StreamTransformer<String, String>.fromHandlers(
      handleData: (String data, EventSink<String> sink) {
        sink.add(data);
      },
      handleDone: (EventSink<String> sink) {
        sink.close();
      },
      handleError: (Object error, StackTrace stackTrace, EventSink<String> sink) {
        sink.addError(error, stackTrace);
      }
  );
}

class DwarfSymbolizationService {
  const DwarfSymbolizationService({
    SymbolsTransformer symbolsTransformer = _defaultTransformer,
  }) : _transformer = symbolsTransformer;

  /// Create a DwarfSymbolizationService with a no-op transformer for testing.
  @visibleForTesting
  factory DwarfSymbolizationService.test() {
    return const DwarfSymbolizationService(
        symbolsTransformer: _testTransformer
    );
  }

  final SymbolsTransformer _transformer;

  /// Decode a stack trace from [input] and place the results in [output].
  ///
  /// Requires [symbols] to be a buffer created from the `--split-debug-info`
  /// command line flag.
  ///
  /// Throws a [ToolExit] if the symbols cannot be parsed or the stack trace
  /// cannot be decoded.
  Future<void> decode({
    required Stream<List<int>> input,
    required IOSink output,
    required Uint8List symbols,
  }) async {
    final Completer<void> onDone = Completer<void>();
    StreamSubscription<void>? subscription;
    subscription = input
        .cast<List<int>>()
        .transform(const Utf8Decoder())
        .transform(const LineSplitter())
        .transform(_transformer(symbols))
        .listen((String line) {
      try {
        output.writeln(line);
      } on Exception catch (e, s) {
        subscription?.cancel().whenComplete(() {
          if (!onDone.isCompleted) {
            onDone.completeError(e, s);
          }
        });
      }
    }, onDone: onDone.complete, onError: onDone.completeError);

    try {
      await onDone.future;
      await output.close();
    } on Exception {
      rethrow;
    }
  }
}