import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:google_fonts/google_fonts.dart';

class TextState {
   String text;
   double fontSize;
   Color fontColor;
   String fontFamily;
   Offset position;
   Color borderColor;
   bool isBold;
   bool isItalic;
   bool isUnderline;

  TextState({
    required this.text,
    required this.fontSize,
    required this.fontColor,
    required this.fontFamily,
    required this.position,
    required this.borderColor,
    required this.isBold,
    required this.isItalic,
    required this.isUnderline,
  });
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final Map<String, List<TextState>> _undoStacks = {};
  final Map<String, List<TextState>> _redoStacks = {};
  final Map<String, TextState> _currentTextStates = {};
  final List<String> pageIds = List.generate(6, (index) => 'page${index + 1}');
  String _activePageId = 'page1';
  late PageController _pageController;
  Offset _initialPosition = Offset.zero;

   @override
  void initState() {
    super.initState();
    _pageController = PageController(
      initialPage: 0,
      viewportFraction: 1.0, // Full page view
    );
    for (var pageId in pageIds) {
      _undoStacks[pageId] = [];
      _redoStacks[pageId] = [];
      _currentTextStates[pageId] = TextState(
        text: 'Edit Me',
        fontSize: 16,
        fontColor: Colors.black,
        fontFamily: 'Roboto',
        position: Offset.zero,
        borderColor: Colors.black,
        isBold: false,
        isItalic: false,
        isUnderline: false,
      );
      _saveState(pageId);
    }
  }

  void _saveState(String pageId) {
    final currentStack = _undoStacks[pageId]!;
    final lastState = currentStack.isEmpty ? null : currentStack.last;
    final currentState = _currentTextStates[pageId]!;

    if (lastState == null ||
        lastState.text != currentState.text ||
        lastState.fontSize != currentState.fontSize ||
        lastState.fontColor != currentState.fontColor ||
        lastState.fontFamily != currentState.fontFamily ||
        lastState.position != currentState.position ||
        lastState.borderColor != currentState.borderColor ||
        lastState.isBold != currentState.isBold ||
        lastState.isItalic != currentState.isItalic ||
        lastState.isUnderline != currentState.isUnderline) {
      currentStack.add(TextState(
        text: currentState.text,
        fontSize: currentState.fontSize,
        fontColor: currentState.fontColor,
        fontFamily: currentState.fontFamily,
        position: currentState.position,
        borderColor: currentState.borderColor,
        isBold: currentState.isBold,
        isItalic: currentState.isItalic,
        isUnderline: currentState.isUnderline,
      ));
      _redoStacks[pageId]!.clear();
    }
  }

  void _undo() {
  final currentStack = _undoStacks[_activePageId]!;
  final redoStack = _redoStacks[_activePageId]!;

  if (currentStack.length > 1) {
    redoStack.add(currentStack.removeLast());
    final lastState = currentStack.last;

    setState(() {
      _currentTextStates[_activePageId] = lastState;
    });
  } else {
    // Find the previous page with undo history
    for (int i = pageIds.indexOf(_activePageId) - 1; i >= 0; i--) {
      final prevPageId = pageIds[i];
      final prevStack = _undoStacks[prevPageId]!;
      
      if (prevStack.length > 1) {
        // Animate to this page
        _pageController.animateToPage(
          i, 
          duration: const Duration(milliseconds: 300), 
          curve: Curves.easeInOut,
        );
        _activePageId = prevPageId;

        // Perform undo
        final redoStack = _redoStacks[prevPageId]!;
        redoStack.add(prevStack.removeLast());
        final lastState = prevStack.last;

        setState(() {
          _currentTextStates[prevPageId] = lastState;
        });
        break;
      }
    }
  }
}

void _redo() {
  final currentStack = _undoStacks[_activePageId]!;
  final redoStack = _redoStacks[_activePageId]!;

  if (redoStack.isNotEmpty) {
    currentStack.add(redoStack.removeLast());
    final nextState = currentStack.last;

    setState(() {
      _currentTextStates[_activePageId] = nextState;
    });
  } else {
    // Find the next page with redo history
    for (int i = pageIds.indexOf(_activePageId) + 1; i < pageIds.length; i++) {
      final nextPageId = pageIds[i];
      final nextRedoStack = _redoStacks[nextPageId]!;
      
      if (nextRedoStack.isNotEmpty) {
        // Animate to this page
        _pageController.animateToPage(
          i, 
          duration: const Duration(milliseconds: 300), 
          curve: Curves.easeInOut,
        );
        _activePageId = nextPageId;

        // Perform redo
        final currentStack = _undoStacks[nextPageId]!;
        currentStack.add(nextRedoStack.removeLast());
        final nextState = currentStack.last;

        setState(() {
          _currentTextStates[nextPageId] = nextState;
        });
        break;
      }
    }
  }
}

  void _showEditDialog() {
    final currentState = _currentTextStates[_activePageId]!;
    showDialog(
      context: context,
      builder: (context) {
        String updatedText = currentState.text;
        return AlertDialog(
          title: const Text('Edit Text'),
          content: TextField(
            controller: TextEditingController(text: currentState.text),
            onChanged: (value) {
              updatedText = value;
            },
          ),
          actions: [
            TextButton(
              onPressed: () {
                _updateCurrentState((state) => state.text = updatedText);
                Navigator.of(context).pop();
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  void _pickColor(bool isFontColor) {
    final currentState = _currentTextStates[_activePageId]!;
    Color tempColor = isFontColor ? currentState.fontColor : currentState.borderColor;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Pick a Color'),
          content: SingleChildScrollView(
            child: ColorPicker(
              pickerColor: tempColor,
              onColorChanged: (color) {
                tempColor = color;
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                _updateCurrentState((state) {
                  if (isFontColor) {
                    state.fontColor = tempColor;
                  } else {
                    state.borderColor = tempColor;
                  }
                });
                Navigator.of(context).pop();
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  void _onPanStart(DragStartDetails details) {
  _initialPosition = _currentTextStates[_activePageId]!.position;
}

void _onPanUpdate(DragUpdateDetails details, BoxConstraints constraints) {
  _updateCurrentState((state) {
    // Get the container size
    final containerWidth = constraints.maxWidth;
    final containerHeight = constraints.maxHeight;

    // Calculate text size (approximate)
    final textStyle = GoogleFonts.getFont(
      state.fontFamily,
      fontSize: state.fontSize,
    );
    final textPainter = TextPainter(
      text: TextSpan(text: state.text, style: textStyle),
      textDirection: TextDirection.ltr,
    )..layout();

    final textWidth = textPainter.width;
    final textHeight = textPainter.height;

    // Get center of the container
    final containerCenterX = containerWidth / 2;
    final containerCenterY = containerHeight / 2;

    // Calculate new position relative to the center
    Offset newPosition = state.position + details.delta;

    // Constrain movement horizontally (relative to center)
    final constrainedX = (newPosition.dx).clamp(
      -containerCenterX + textWidth / 2,
      containerCenterX - textWidth / 2,
    );

    // Constrain movement vertically (relative to center)
    final constrainedY = (newPosition.dy).clamp(
      -containerCenterY + textHeight / 2,
      containerCenterY - textHeight / 2,
    );

    state.position = Offset(constrainedX, constrainedY);
  }, saveImmediately: false);
}



void _onPanEnd(DragEndDetails details) {
  final currentState = _currentTextStates[_activePageId]!;
  if ((_initialPosition - currentState.position).distance > 10) {
    _saveState(_activePageId);
  }
}


  void _onPageChanged(int index) {
    setState(() {
      _activePageId = pageIds[index];
    });
  }

  void _updateCurrentState(void Function(TextState) update, {bool saveImmediately = true}) {
  setState(() {
    final currentState = _currentTextStates[_activePageId]!;
    final updatedState = TextState(
      text: currentState.text,
      fontSize: currentState.fontSize,
      fontColor: currentState.fontColor,
      fontFamily: currentState.fontFamily,
      position: currentState.position,
      borderColor: currentState.borderColor,
      isBold: currentState.isBold,
      isItalic: currentState.isItalic,
      isUnderline: currentState.isUnderline,
    );
    update(updatedState);
    _currentTextStates[_activePageId] = updatedState;
    
    if (saveImmediately) {
      _saveState(_activePageId);
    }
  });
}

  void _changeFontSize(bool increase) {
    _updateCurrentState((state) {
      state.fontSize += increase ? 2 : -2;
      state.fontSize = state.fontSize < 8 ? 8 : state.fontSize;
    });
  }

  void _toggleTextStyle(String style) {
    _updateCurrentState((state) {
      switch (style) {
        case 'bold':
          state.isBold = !state.isBold;
          break;
        case 'italic':
          state.isItalic = !state.isItalic;
          break;
        case 'underline':
          state.isUnderline = !state.isUnderline;
          break;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Redo Undo Functionality'),
        actions: [
          IconButton(
            icon: const Icon(Icons.undo),
            onPressed: _undo,
          ),
          IconButton(
            icon: const Icon(Icons.redo),
            onPressed: _redo,
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              itemCount: pageIds.length,
              pageSnapping: true,
              physics: const PageScrollPhysics(),
              onPageChanged: _onPageChanged,
              itemBuilder: (context, index) {
                final currentState = _currentTextStates[pageIds[index]]!;

                return LayoutBuilder(
                  builder: (context, constraints) {
                    // Calculate the container size maintaining 9:16 aspect ratio
                    double containerWidth = constraints.maxWidth * 0.9;
                    double containerHeight = containerWidth * (16 / 9);

                    // If the height exceeds the available height, adjust width
                    if (containerHeight > constraints.maxHeight * 0.8) {
                      containerHeight = constraints.maxHeight * 0.8;
                      containerWidth = containerHeight * (9 / 16);
                    }

                    return Center(
                      child: Container(
                        width: containerWidth,
                        height: containerHeight,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border.all(color: Colors.black, width: 2),
                        ),
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            return GestureDetector(
                              onPanStart: _onPanStart,
                              onPanUpdate: (details) => _onPanUpdate(details, constraints),
                              onPanEnd: _onPanEnd,
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  Transform.translate(
                                    offset: currentState.position,
                                    child: Container(
                                      decoration: BoxDecoration(
                                        border: Border.all(color: currentState.borderColor),
                                      ),
                                      child: Text(
                                        currentState.text,
                                        style: GoogleFonts.getFont(
                                          currentState.fontFamily,
                                          fontSize: currentState.fontSize,
                                          color: currentState.fontColor,
                                          fontWeight: currentState.isBold ? FontWeight.bold : FontWeight.normal,
                                          fontStyle: currentState.isItalic ? FontStyle.italic : FontStyle.normal,
                                          decoration: currentState.isUnderline ? TextDecoration.underline : null,
                                         ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                      ),
                      )
                    );
                  },
                );
              },
            ),
          ),
          // Buttons moved outside the container
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: _showEditDialog,
                ),
                IconButton(
                  icon: const Icon(Icons.remove),
                  onPressed: () => _changeFontSize(false),
                ),
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: () => _changeFontSize(true),
                ),
                IconButton(
                  icon: const Icon(Icons.format_bold),
                  onPressed: () => _toggleTextStyle('bold'),
                ),
                IconButton(
                  icon: const Icon(Icons.format_italic),
                  onPressed: () => _toggleTextStyle('italic'),
                ),
                IconButton(
                  icon: const Icon(Icons.format_underline),
                  onPressed: () => _toggleTextStyle('underline'),
                ),
                IconButton(
                  icon: const Icon(Icons.color_lens),
                  onPressed: () => _pickColor(true),
                ),
                IconButton(
                  icon: const Icon(Icons.border_color),
                  onPressed: () => _pickColor(false),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
