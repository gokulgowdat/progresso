import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/system_controller.dart';
import '../models/system_data.dart';

// ---------------------------------------------------------------------------
// StickyNotesOverlay — the main overlay
// ---------------------------------------------------------------------------
class StickyNotesOverlay extends StatefulWidget {
  final VoidCallback onClose;
  const StickyNotesOverlay({super.key, required this.onClose});

  @override
  State<StickyNotesOverlay> createState() => _StickyNotesOverlayState();
}

class _StickyNotesOverlayState extends State<StickyNotesOverlay> {
  String? activeGroupId;
  final TextEditingController groupController = TextEditingController();

  void _confirmDeleteGroup(SystemController system, NoteGroup group) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF2C2C2C),
        title: const Text("Delete Category?",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: Text(
          "Are you sure you want to delete '${group.name}' and permanently erase all the sticky notes inside it?",
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("CANCEL", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              system.deleteNoteGroup(group.id);
              setState(() {
                if (system.systemData.noteGroups.isNotEmpty) {
                  activeGroupId = system.systemData.noteGroups.first.id;
                } else {
                  activeGroupId = null;
                }
              });
              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF5555),
              foregroundColor: Colors.white,
            ),
            child: const Text("DESTROY GROUP",
                style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final system = context.watch<SystemController>();

    if (activeGroupId == null && system.systemData.noteGroups.isNotEmpty) {
      activeGroupId = system.systemData.noteGroups.first.id;
    }

    final activeNotes = activeGroupId == null
        ? <StickyNote>[]
        : system.systemData.stickyNotes
            .where((n) => n.groupId == activeGroupId)
            .toList();

    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20.0, sigmaY: 20.0),
        child: Container(
          color: Colors.black.withOpacity(0.65),
          child: Column(
            children: [
              // --- HEADER: TABS AND CLOSE BUTTON ---
              Container(
                height: 60,
                decoration: const BoxDecoration(
                  border: Border(bottom: BorderSide(color: Colors.white24)),
                ),
                child: Row(
                  children: [
                    const SizedBox(width: 20),
                    const Icon(Icons.sticky_note_2, color: Color(0xFFEBFB7E)),
                    const SizedBox(width: 10),
                    const Text("SCRATCHPAD",
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 2)),
                    const SizedBox(width: 30),
                    Expanded(
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: system.systemData.noteGroups.length + 1,
                        itemBuilder: (context, index) {
                          if (index == system.systemData.noteGroups.length) {
                            return IconButton(
                              icon: const Icon(Icons.add, color: Colors.white54),
                              onPressed: () {
                                showDialog(
                                  context: context,
                                  builder: (ctx) => AlertDialog(
                                    backgroundColor: const Color(0xFF2C2C2C),
                                    title: const Text("New Category",
                                        style: TextStyle(color: Colors.white)),
                                    content: TextField(
                                      controller: groupController,
                                      style: const TextStyle(color: Colors.white),
                                      autofocus: true,
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () {
                                          String name = groupController.text.trim();
                                          if (name.isEmpty) name = 'Untitled';
                                          system.addNoteGroup(name);
                                          groupController.clear();
                                          Navigator.pop(ctx);
                                        },
                                        child: const Text("ADD",
                                            style: TextStyle(
                                                color: Color(0xFFEBFB7E))),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            );
                          }

                          var group = system.systemData.noteGroups[index];
                          bool isActive = group.id == activeGroupId;
                          return InkWell(
                            onTap: () =>
                                setState(() => activeGroupId = group.id),
                            child: Container(
                              padding: EdgeInsets.only(
                                  left: 20, right: isActive ? 5 : 20),
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                border: Border(
                                  bottom: BorderSide(
                                    color: isActive
                                        ? const Color(0xFFEBFB7E)
                                        : Colors.transparent,
                                    width: 3,
                                  ),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    group.name,
                                    style: TextStyle(
                                      color:
                                          isActive ? Colors.white : Colors.white54,
                                      fontWeight: isActive
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                    ),
                                  ),
                                  if (isActive &&
                                      system.systemData.noteGroups.length > 1)
                                    IconButton(
                                      icon: const Icon(Icons.close,
                                          size: 16, color: Colors.white54),
                                      onPressed: () =>
                                          _confirmDeleteGroup(system, group),
                                    ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white, size: 30),
                      onPressed: widget.onClose,
                    ),
                    const SizedBox(width: 20),
                  ],
                ),
              ),

              // --- CANVAS AREA ---
              Expanded(
                child: Stack(
                  children: [
                    SingleChildScrollView(
                      child: SizedBox(
                        width: MediaQuery.of(context).size.width,
                        height: 5000,
                        child: Stack(
                          children: activeNotes
                              .map((note) => InteractiveStickyNote(
                                    key: ValueKey(note.id),
                                    note: note,
                                  ))
                              .toList(),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 40,
                      right: 40,
                      child: FloatingActionButton(
                        backgroundColor: const Color(0xFFEBFB7E),
                        foregroundColor: Colors.black,
                        child: const Icon(Icons.add),
                        onPressed: () {
                          if (activeGroupId != null) {
                            final random = Random();
                            system.addStickyNote(
                              activeGroupId!,
                              x: 150 + random.nextDouble() * 200,
                              y: 100 + random.nextDouble() * 150,
                            );
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// InteractiveStickyNote — the movable, resizable, styled note
// ---------------------------------------------------------------------------
class InteractiveStickyNote extends StatefulWidget {
  final StickyNote note;
  const InteractiveStickyNote({super.key, required this.note});

  @override
  State<InteractiveStickyNote> createState() => _InteractiveStickyNoteState();
}

class _InteractiveStickyNoteState extends State<InteractiveStickyNote> {
  late double localX;
  late double localY;
  late double localWidth;
  late double localHeight;
  late String localColorHex;

  late RichNoteController textCtrl;
  late TextEditingController titleCtrl;
  final FocusNode _focusNode = FocusNode();

  final List<String> mintColors = [
    '0xFFFFF59D',
    '0xFFA5D6A7',
    '0xFF90CAF9',
    '0xFFCE93D8',
    '0xFFFFAB91',
    '0xFFBCAAA4',
    '0xFFEEEEEE',
  ];

  Color _parseColor(String hex) {
    if (hex.startsWith('0x') || hex.startsWith('0X')) {
      return Color(int.parse(hex.substring(2), radix: 16));
    }
    return Color(int.parse(hex));
  }

  @override
  void initState() {
    super.initState();
    localX = widget.note.x;
    localY = widget.note.y;
    localWidth = widget.note.width;
    localHeight = widget.note.height;
    localColorHex = widget.note.colorHex;
    textCtrl = RichNoteController(text: widget.note.text);
    titleCtrl = TextEditingController(text: widget.note.title);
  }

  @override
  void dispose() {
    textCtrl.dispose();
    titleCtrl.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _formatSelection(String prefix, String suffix) {
    final system = context.read<SystemController>();
    final text = textCtrl.text;
    final selection = textCtrl.selection;

    if (selection.isValid && !selection.isCollapsed) {
      final start = selection.start;
      final end = selection.end;
      final selectedText = text.substring(start, end);

      final newText =
          text.replaceRange(start, end, '$prefix$selectedText$suffix');
      textCtrl.value = TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(
            offset: end + prefix.length + suffix.length),
      );
    } else {
      int cursorPosition =
          selection.isValid ? selection.start : text.length;
      if (cursorPosition == -1) cursorPosition = text.length;

      final newText = text.replaceRange(
          cursorPosition, cursorPosition, '$prefix$suffix');
      textCtrl.value = TextEditingValue(
        text: newText,
        selection:
            TextSelection.collapsed(offset: cursorPosition + prefix.length),
      );
    }

    system.updateStickyNoteSilent(widget.note.id, text: textCtrl.text);
    system.saveNotesToVault();
    _focusNode.requestFocus();
  }

void _applyHeading(int level) {
    final system = context.read<SystemController>();
    final text = textCtrl.text;
    final selection = textCtrl.selection;

    int cursorPosition = selection.isValid ? selection.start : text.length;
    if (cursorPosition == -1) cursorPosition = text.length;

    // FIX 1: Prevent the RangeError crash when cursor is at index 0
    int lineStart = 0;
    if (cursorPosition > 0) {
      lineStart = text.lastIndexOf('\n', cursorPosition - 1) + 1;
    }

    int lineEnd = text.indexOf('\n', cursorPosition);
    if (lineEnd == -1) lineEnd = text.length;

    String line = text.substring(lineStart, lineEnd);
    String newText;
    int newCursorPos;

    final match = RegExp(r'^#{1,6}\s').firstMatch(line);
    
    // FIX 2: Handle "Normal Text" (Level 0) to strip the heading entirely
    if (level == 0) {
      if (match != null) {
        String oldPrefix = match.group(0)!;
        newText = text.replaceRange(lineStart, lineStart + oldPrefix.length, '');
        newCursorPos = cursorPosition - oldPrefix.length;
      } else {
        newText = text;
        newCursorPos = cursorPosition;
      }
    } else {
      String prefix = '${'#' * level} ';
      if (match != null) {
        String oldPrefix = match.group(0)!;
        newText = text.replaceRange(lineStart, lineStart + oldPrefix.length, prefix);
        newCursorPos = cursorPosition - oldPrefix.length + prefix.length;
      } else {
        newText = text.replaceRange(lineStart, lineStart, prefix);
        newCursorPos = cursorPosition + prefix.length;
      }
    }

    // Safety bound check so the cursor never crashes the selection index
    if (newCursorPos < 0) newCursorPos = 0;
    if (newCursorPos > newText.length) newCursorPos = newText.length;

    textCtrl.value = TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(offset: newCursorPos));
    
    system.updateStickyNoteSilent(widget.note.id, text: textCtrl.text);
    system.saveNotesToVault();
    _focusNode.requestFocus();
  }

  void _cycleColor() {
    final system = context.read<SystemController>();
    int currentIndex = mintColors.indexOf(localColorHex);
    int nextIndex = (currentIndex + 1) % mintColors.length;
    setState(() {
      localColorHex = mintColors[nextIndex];
    });
    system.updateStickyNoteSilent(widget.note.id, colorHex: localColorHex);
    system.saveNotesToVault();
  }

  @override
  Widget build(BuildContext context) {
    final system = context.read<SystemController>();
    final noteBg = _parseColor(localColorHex);

    final selectionColor = noteBg.computeLuminance() > 0.5
        ? Colors.blue.withOpacity(0.4)
        : Colors.blueAccent.withOpacity(0.6);

    return Positioned(
      left: localX,
      top: localY,
      child: Container(
        width: localWidth,
        height: localHeight,
        decoration: BoxDecoration(
          color: noteBg,
          borderRadius: BorderRadius.circular(4),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 10,
                offset: const Offset(4, 4))
          ],
        ),
        child: Stack(
          children: [
            Column(
              children: [
                // -- DRAGGABLE HEADER WITH TITLE --
                MouseRegion(
                  cursor: SystemMouseCursors.move,
                  child: GestureDetector(
                    onPanUpdate: (details) {
                      setState(() {
                        localX += details.delta.dx;
                        localY += details.delta.dy;
                      });
                      system.updateStickyNoteSilent(widget.note.id,
                          x: localX, y: localY);
                    },
                    onPanEnd: (_) => system.saveNotesToVault(),
                    child: Container(
                      height: 30,
                      color: Colors.black.withOpacity(0.08),
                      child: Row(
                        children: [
                          InkWell(
                            onTap: _cycleColor,
                            child: Container(
                              width: 14,
                              height: 14,
                              margin: const EdgeInsets.only(left: 10),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: noteBg,
                                border: Border.all(color: Colors.black45),
                              ),
                            ),
                          ),
                          Expanded(
                            child: Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 8),
                              child: TextField(
                                controller: titleCtrl,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    color: Colors.black87),
                                decoration: const InputDecoration(
                                  border: InputBorder.none,
                                  isDense: true,
                                  hintText: 'Title',
                                  hintStyle:
                                      TextStyle(color: Colors.black45),
                                ),
                                onChanged: (val) {
                                  system.updateStickyNoteSilent(
                                      widget.note.id, title: val);
                                  system.saveNotesToVault();
                                },
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close,
                                size: 16, color: Colors.black54),
                            onPressed: () =>
                                system.deleteStickyNote(widget.note.id),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // -- FORMATTING TOOLBAR --
                Container(
                  height: 35,
                  color: Colors.black.withOpacity(0.05),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.format_bold,
                            size: 18, color: Colors.black87),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        onPressed: () => _formatSelection('**', '**'),
                      ),
                      IconButton(
                        icon: const Icon(Icons.format_italic,
                            size: 18, color: Colors.black87),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        onPressed: () => _formatSelection('_', '_'),
                      ),
                      IconButton(
                        icon: const Icon(Icons.format_underlined,
                            size: 18, color: Colors.black87),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        onPressed: () => _formatSelection('__', '__'),
                      ),
                      PopupMenuButton<int>(
                        icon: const Icon(Icons.title,
                            size: 18, color: Colors.black87),
                        padding: EdgeInsets.zero,
                        tooltip: "Headings",
                        color: Colors.white,
                        onSelected: _applyHeading,
                        itemBuilder: (context) => [
                          const PopupMenuItem(
                            value: 1,
                            child: Text("Heading 1",
                                style: TextStyle(
                                    color: Colors.black,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 20)),
                          ),
                          const PopupMenuItem(
                            value: 2,
                            child: Text("Heading 2",
                                style: TextStyle(
                                    color: Colors.black,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18)),
                          ),
                          const PopupMenuItem(
                            value: 3,
                            child: Text("Heading 3",
                                style: TextStyle(
                                    color: Colors.black,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16)),
                          ),
                          const PopupMenuItem(
                            value: 0,
                            child: Text("Normal Text",
                                style: TextStyle(color: Colors.black)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // -- TEXT AREA --
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 5),
                    child: Theme(
                      data: Theme.of(context).copyWith(
                        textSelectionTheme: TextSelectionThemeData(
                          selectionColor: selectionColor,
                          selectionHandleColor: Colors.blue,
                        ),
                      ),
                      child: TextField(
                        controller: textCtrl,
                        focusNode: _focusNode,
                        maxLines: null,
                        expands: true,
                        cursorColor: Colors.black,
                        style: const TextStyle(
                            color: Colors.black87, fontSize: 16),
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                        ),
                        onChanged: (val) {
                          system.updateStickyNoteSilent(
                              widget.note.id, text: val);
                          system.saveNotesToVault();
                        },
                      ),
                    ),
                  ),
                ),
              ],
            ),

            // -- RESIZE HANDLE --
            Positioned(
              bottom: 0,
              right: 0,
              child: MouseRegion(
                cursor: SystemMouseCursors.resizeDownRight,
                child: GestureDetector(
                  onPanUpdate: (details) {
                    setState(() {
                      localWidth += details.delta.dx;
                      localHeight += details.delta.dy;
                      if (localWidth < 200) localWidth = 200;
                      if (localHeight < 200) localHeight = 200;
                    });
                    system.updateStickyNoteSilent(widget.note.id,
                        width: localWidth, height: localHeight);
                  },
                  onPanEnd: (_) => system.saveNotesToVault(),
                  child: Container(
                    width: 20,
                    height: 20,
                    color: Colors.transparent,
                    child: const Icon(Icons.signal_cellular_4_bar,
                        size: 14, color: Colors.black26),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// RichNoteController — zero‑width ghost syntax engine
// ---------------------------------------------------------------------------
class RichNoteController extends TextEditingController {
  RichNoteController({super.text});

  @override
  TextSpan buildTextSpan(
      {required BuildContext context,
      TextStyle? style,
      required bool withComposing}) {
    final TextStyle baseStyle =
        style ?? const TextStyle(color: Colors.black87, fontSize: 16);

    final TextStyle hiddenStyle = baseStyle.copyWith(
      color: Colors.transparent,
      fontSize: 0.1,
      letterSpacing: -1,
      height: 0,
    );

    List<TextSpan> spans = [];

    final pattern = RegExp(
      r'(^#{1,6}\s+.*$)|(\*\*.*?\*\*)|(__.*?__)|(_.*?_)',
      multiLine: true,
    );

    int lastMatchEnd = 0;
    for (final match in pattern.allMatches(text)) {
      if (match.start > lastMatchEnd) {
        spans.add(TextSpan(
            text: text.substring(lastMatchEnd, match.start),
            style: baseStyle));
      }

      String m = match[0]!;

      if (m.startsWith('#')) {
        int spaceIndex = m.indexOf(' ');
        if (spaceIndex != -1) {
          String symbols = m.substring(0, spaceIndex + 1);
          String content = m.substring(spaceIndex + 1);
          double size = 16.0;
          if (symbols.startsWith('# ')) size = 28.0;
          if (symbols.startsWith('## ')) size = 24.0;
          if (symbols.startsWith('### ')) size = 20.0;
          if (symbols.startsWith('#### ')) size = 18.0;

          spans.add(TextSpan(text: symbols, style: hiddenStyle));
          spans.add(TextSpan(
              text: content,
              style: baseStyle.copyWith(
                  color: Colors.black,
                  fontSize: size,
                  fontWeight: FontWeight.bold)));
        }
      }
      else if (m.startsWith('**') && m.endsWith('**') && m.length >= 4) {
        spans.add(TextSpan(text: '**', style: hiddenStyle));
        spans.add(TextSpan(
            text: m.substring(2, m.length - 2),
            style: baseStyle.copyWith(
                fontWeight: FontWeight.bold, color: Colors.black)));
        spans.add(TextSpan(text: '**', style: hiddenStyle));
      }
      else if (m.startsWith('__') && m.endsWith('__') && m.length >= 4) {
        spans.add(TextSpan(text: '__', style: hiddenStyle));
        spans.add(TextSpan(
            text: m.substring(2, m.length - 2),
            style: baseStyle.copyWith(
                decoration: TextDecoration.underline,
                decorationColor: Colors.black,
                decorationThickness: 2,
                color: Colors.black)));
        spans.add(TextSpan(text: '__', style: hiddenStyle));
      }
      else if (m.startsWith('_') && m.endsWith('_') && m.length >= 2) {
        spans.add(TextSpan(text: '_', style: hiddenStyle));
        spans.add(TextSpan(
            text: m.substring(1, m.length - 1),
            style: baseStyle.copyWith(
                fontStyle: FontStyle.italic, color: Colors.black)));
        spans.add(TextSpan(text: '_', style: hiddenStyle));
      }

      lastMatchEnd = match.end;
    }

    if (lastMatchEnd < text.length) {
      spans.add(
          TextSpan(text: text.substring(lastMatchEnd), style: baseStyle));
    }

    return TextSpan(style: baseStyle, children: spans);
  }
}