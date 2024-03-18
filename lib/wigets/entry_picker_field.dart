import 'package:boginni_overlays/utils/input_decoration_extension.dart';
import 'package:boginni_utils/boginni_utils.dart';
import 'package:flutter/material.dart';

import 'overlay_entry_widget.dart';

typedef PickerFieldFetchData<T> = Future<List<T>?> Function(String query);

typedef PickerFieldItemToString<T> = String Function(T?);

typedef PickerFieldItemBuilder<T> = Widget? Function(BuildContext context, T?);

typedef PickerFieldInputDecoration<T> = InputDecoration Function(BuildContext context, T?);

class EntryPickerField<T> extends StatefulWidget {
  const EntryPickerField({
    super.key,
    required this.onSelected,
    required this.validator,
    required this.decoration,
    required this.enabled,
    required this.readOnly,
    required this.selectedEntry,
    required this.itemToString,
    required this.itemBuilder,
    required this.fetchData,
    required this.decorationBuilder,
    this.dataHandler,
  });

  final ValueChanged<T?> onSelected;
  final String? Function(String?)? validator;
  final InputDecoration decoration;
  final bool enabled;
  final bool readOnly;
  final T? selectedEntry;
  final List<T> Function(List<T>? data)? dataHandler;
  final PickerFieldItemToString<T> itemToString;
  final PickerFieldItemBuilder<T> itemBuilder;
  final PickerFieldFetchData<T> fetchData;
  final PickerFieldInputDecoration<T>? decorationBuilder;

  @override
  State<EntryPickerField<T>> createState() => _EntryPickerFieldState<T>();
}

class _EntryPickerFieldState<T> extends State<EntryPickerField<T>> {
  final key = GlobalKey();

  final items = ValueNotifier<List<T>?>(null);

  OverlayEntry? _overlayEntry;
  final controller = TextEditingController();

  final _debouncer = Debouncer(
    delay: const Duration(milliseconds: 350),
  );

  @override
  void initState() {
    super.initState();
    controller.text = widget.itemToString(widget.selectedEntry);
  }

  @override
  void dispose() {
    super.dispose();
    controller.dispose();
  }

  @override
  void didUpdateWidget(covariant EntryPickerField<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      controller.text = widget.itemToString(widget.selectedEntry);
    });
  }

  void _fetchData() async {
    final query = controller.text;

    final data = await widget.fetchData(query);

    items.value = widget.dataHandler?.call(data) ?? data;
  }

  void _closeOverlay() {
    setState(() {
      _overlayEntry?.remove();
      _overlayEntry = null;
    });
  }

  void _showOverlay() {
    if (_overlayEntry != null) {
      return;
    }

    _overlayEntry = OverlayEntry(
      builder: (context) => OverlayEntryWidget(
        widgetKey: key,
        width: 200,
        builder: (context) {
          return ValueListenableBuilder(
            valueListenable: items,
            builder: (context, value, child) {
              return EntryPickerOverlayWidget<T>(
                onSelected: (item) {
                  widget.onSelected(item);
                },
                close: _closeOverlay,
                data: value,
                itemBuilder: widget.itemBuilder,
              );
            },
          );
        },
        close: _closeOverlay,
      ),
    );

    setState(() {
      Overlay.of(context).insert(_overlayEntry!);
    });
  }

  @override
  Widget build(BuildContext context) {
    var decoration = widget.decoration;
    final foregroundDecoration = widget.decorationBuilder?.call(context, widget.selectedEntry);

    if (foregroundDecoration != null) {
      decoration = foregroundDecoration.mergeWith(decoration);
    }

    final oldSuffixIcon = decoration.suffixIcon;

    return FocusScope(
      onFocusChange: (focus) {
        if (!focus && widget.selectedEntry == null) {
          controller.clear();
        }
      },
      child: TextFormField(
        key: key,
        controller: controller,
        validator: widget.validator,
        enabled: widget.enabled,
        readOnly: widget.readOnly,
        onChanged: (value) {
          _debouncer.run(() {
            _fetchData();
            _showOverlay();
          });
        },
        decoration: decoration.copyWith(
          suffixIcon: ListenableBuilder(
            listenable: controller,
            builder: (context, child) {
              return Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (oldSuffixIcon != null) oldSuffixIcon,
                    if (controller.text.isNotEmpty)
                      GestureDetector(
                        onTap: () {
                          widget.onSelected(null);
                          controller.clear();
                        },
                        child: const Icon(
                          Icons.clear,
                          size: 16,
                        ),
                      ),
                    Icon(
                      _overlayEntry == null ? Icons.arrow_downward : Icons.arrow_upward,
                      size: 16,
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        onTap: () {
          _fetchData();
          _showOverlay();
        },
      ),
    );
  }
}

class EntryPickerOverlayWidget<T> extends StatelessWidget {
  const EntryPickerOverlayWidget({
    super.key,
    required this.onSelected,
    required this.close,
    required this.data,
    required this.itemBuilder,
  });

  final void Function(T) onSelected;
  final VoidCallback close;
  final List<T>? data;

  final Widget? Function(BuildContext context, T?) itemBuilder;

  @override
  Widget build(BuildContext context) {
    final side = BorderSide(
      color: context.colorScheme.outline,
    );
    final data = this.data;
    return Material(
      shape: Border(
        right: side,
        bottom: side,
        left: side,
      ),
      child: SizedBox(
        height: (data?.length ?? 0) < 8 ? null : 300,
        child: Builder(
          builder: (context) {
            if (data == null) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(32.0),
                  child: CircularProgressIndicator(),
                ),
              );
            }

            if (data.isEmpty) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(32.0),
                  child: Text('No results'),
                ),
              );
            }

            return ListView.builder(
              itemCount: data.length,
              shrinkWrap: true,
              physics: const AlwaysScrollableScrollPhysics(),
              itemBuilder: (context, index) {
                return Material(
                  color: index.isEven ? context.colorScheme.surface : context.colorScheme.surfaceVariant,
                  child: InkWell(
                    onTap: () {
                      onSelected(data[index]);
                      close();
                    },
                    child: itemBuilder(
                      context,
                      data[index],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
