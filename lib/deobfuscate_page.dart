import 'dart:io';

import 'package:auto_size_text/auto_size_text.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:path_provider/path_provider.dart';
import 'package:test_deobfuscate/symbolize.dart';

class DeobfuscatePage extends StatefulWidget {
  const DeobfuscatePage({super.key});

  @override
  State<DeobfuscatePage> createState() => _DeobfuscatePageState();
}

class _DeobfuscatePageState extends State<DeobfuscatePage> {

  final Symbolize symbolizeCommand = Symbolize();
  final _formKey = GlobalKey<FormBuilderState>();

  final ValueNotifier<String> _clearStacktraceNotifier = ValueNotifier<String>('');

  @override
  Widget build(BuildContext context) {
    return SafeArea(
        child: Scaffold(
          body: ListView(
            shrinkWrap: true,
            children: [
              FormBuilder(
                key: _formKey,
                child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                  const SizedBox(height: 12,),
                  Row(
                    children: [
                      Expanded(
                        child: FormBuilderTextField(
                            name: 'stackTrace',
                            maxLength: 50000,
                            maxLines: null,
                            textAlignVertical: TextAlignVertical.top,
                            keyboardType: TextInputType.multiline,
                            validator: FormBuilderValidators.compose([
                              FormBuilderValidators.required(
                                  errorText: 'required')
                            ]),
                            decoration: const InputDecoration(
                              floatingLabelAlignment: FloatingLabelAlignment.center,
                              floatingLabelBehavior: FloatingLabelBehavior.always,
                            )
                        ),
                      ),
                    ],
                  ),
                  ElevatedButton(
                      onPressed: () {
                        _saveTicket();
                      },
                      child: const Text('Process')
                  ),
                  ValueListenableBuilder<String>(
                      valueListenable: _clearStacktraceNotifier,
                      builder: (context, text, __) {
                        return Row(
                          children: [
                            Expanded(
                              child: AutoSizeText(
                                text,
                                maxLines: 500,
                              ),
                            ),
                          ],
                        );
                      }
                  )
                ]),
              )
            ],
          ),
        )
    );
  }

  Future<void> _saveTicket() async {
    if (_formKey.currentState?.saveAndValidate() ?? false) {
      final Directory temporaryDirectory = await getTemporaryDirectory();
      var formValue = _formKey.currentState!.value;
      final String stackTrace = formValue["stackTrace"];
      File stackTraceFile = await File('${temporaryDirectory.path}/stackTrace.txt').create();
      await stackTraceFile.writeAsString(stackTrace);
      FilePickerResult? sympbolsPicker = await FilePicker.platform.pickFiles(dialogTitle: "Pick Symboles");
      if (sympbolsPicker != null) {
        final File symbols = File(sympbolsPicker.files.single.path!);

        _clearStacktraceNotifier.value = await symbolizeCommand.run(stackTraceFile, symbols, temporaryDirectory);
      }
    }
  }
}