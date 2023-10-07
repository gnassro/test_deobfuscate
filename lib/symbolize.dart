import 'dart:io';
import 'dart:typed_data';
import 'dwarf_symbolization_service.dart';

class Symbolize {
  final DwarfSymbolizationService _dwarfSymbolizationService = const DwarfSymbolizationService();

  Future<String> run(File stackTrace, File symbolsFile, Directory temporaryDirectory) async {
    Stream<List<int>> input;
    IOSink output;

    final File outputFile = File('${temporaryDirectory.path}/deobfuscate.txt');
    if (!outputFile.parent.existsSync()) {
      outputFile.parent.createSync(recursive: true);
    }
    output = outputFile.openWrite();

    final Uint8List symbols = symbolsFile.readAsBytesSync();

    input = stackTrace.openRead();
    await _dwarfSymbolizationService.decode(
      input: input,
      output: output,
      symbols: symbols,
    );
    return await outputFile.readAsString();
  }
}
