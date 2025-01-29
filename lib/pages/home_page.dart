import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:google_fonts/google_fonts.dart';

class TextState {
  String id; // Added unique identifier
  String text;
  double fontSize;
  Color fontColor;
  String fontFamily;
  Offset position;
  Color borderColor;
  bool isBold;
  bool isItalic;
  bool isUnderline;
  bool isSelected; // Added selection state

  TextState({
    required this.id,
    required this.text,
    required this.fontSize,
    required this.fontColor,
    required this.fontFamily,
    required this.position,
    required this.borderColor,
    required this.isBold,
    required this.isItalic,
    required this.isUnderline,
    this.isSelected = false,
  });

  TextState copyWith({
    String? id,
    String? text,
    double? fontSize,
    Color? fontColor,
    String? fontFamily,
    Offset? position,
    Color? borderColor,
    bool? isBold,
    bool? isItalic,
    bool? isUnderline,
    bool? isSelected,
  }) {
    return TextState(
      id: id ?? this.id,
      text: text ?? this.text,
      fontSize: fontSize ?? this.fontSize,
      fontColor: fontColor ?? this.fontColor,
      fontFamily: fontFamily ?? this.fontFamily,
      position: position ?? this.position,
      borderColor: borderColor ?? this.borderColor,
      isBold: isBold ?? this.isBold,
      isItalic: isItalic ?? this.isItalic,
      isUnderline: isUnderline ?? this.isUnderline,
      isSelected: isSelected ?? this.isSelected,
    );
  }
}

class PageState {
  List<TextState> texts;
  List<List<TextState>> undoStack;
  List<List<TextState>> redoStack;

  PageState({
    required this.texts,
    required this.undoStack,
    required this.redoStack,
  });
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final Map<String, PageState> _pages = {};
  final List<String> pageIds = List.generate(6, (index) => 'page${index + 1}');
  String _activePageId = 'page1';
  String? _selectedTextId;
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(
      initialPage: 0,
      viewportFraction: 1.0,
    );
    _initializePages();
  }

  void _initializePages() {
    for (var pageId in pageIds) {
      _pages[pageId] = PageState(
        texts: [],
        undoStack: [],
        redoStack: [],
      );
      _addNewText(pageId); // Add initial text
      _saveState(pageId);
    }
  }

  void _addNewText(String pageId) {
    final newText = TextState(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
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

    setState(() {
      _pages[pageId]!.texts.add(newText);
      _selectedTextId = newText.id;
      _saveState(pageId);
    });
  }

  void _saveState(String pageId) {
    final page = _pages[pageId]!;
    final currentTexts = page.texts.map((text) => text.copyWith()).toList();
    
    page.undoStack.add(currentTexts);
    page.redoStack.clear();
  }

   void _undo() {
    var currentPageIndex = pageIds.indexOf(_activePageId);
    var currentPage = _pages[_activePageId]!;

    if (currentPage.undoStack.length > 1) {
      setState(() {
        currentPage.redoStack.add(currentPage.undoStack.removeLast());
        currentPage.texts = currentPage.undoStack.last.map((text) => text.copyWith()).toList();
      });
    } else {
      // Move to previous page if available
      if (currentPageIndex > 0) {
        currentPageIndex--;
        final previousPageId = pageIds[currentPageIndex];
        final previousPage = _pages[previousPageId]!;

        if (previousPage.undoStack.length > 1) {
          setState(() {
            _activePageId = previousPageId;
            _selectedTextId = null;
            _pageController.animateToPage(
              currentPageIndex,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
            );
            
            // Perform undo on the previous page
            previousPage.redoStack.add(previousPage.undoStack.removeLast());
            previousPage.texts = previousPage.undoStack.last.map((text) => text.copyWith()).toList();
          });
        }
      }
    }
  }

  void _redo() {
    var currentPageIndex = pageIds.indexOf(_activePageId);
    var currentPage = _pages[_activePageId]!;

    if (currentPage.redoStack.isNotEmpty) {
      setState(() {
        final nextState = currentPage.redoStack.removeLast();
        currentPage.undoStack.add(nextState);
        currentPage.texts = nextState.map((text) => text.copyWith()).toList();
      });
    } else {
      // Move to next page if available
      if (currentPageIndex < pageIds.length - 1) {
        currentPageIndex++;
        final nextPageId = pageIds[currentPageIndex];
        final nextPage = _pages[nextPageId]!;

        if (nextPage.redoStack.isNotEmpty) {
          setState(() {
            _activePageId = nextPageId;
            _selectedTextId = null;
            _pageController.animateToPage(
              currentPageIndex,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
            );
            
            // Perform redo on the next page
            final nextState = nextPage.redoStack.removeLast();
            nextPage.undoStack.add(nextState);
            nextPage.texts = nextState.map((text) => text.copyWith()).toList();
          });
        }
      }
    }
  }

  // Add these helper methods to check if undo/redo are available
  bool _canUndo() {
    var currentPageIndex = pageIds.indexOf(_activePageId);
    var currentPage = _pages[_activePageId]!;

    // Check current page
    if (currentPage.undoStack.length > 1) return true;

    // Check previous pages
    for (int i = currentPageIndex - 1; i >= 0; i--) {
      final previousPage = _pages[pageIds[i]]!;
      if (previousPage.undoStack.length > 1) return true;
    }
    
    return false;
  }

  bool _canRedo() {
    var currentPageIndex = pageIds.indexOf(_activePageId);
    var currentPage = _pages[_activePageId]!;

    // Check current page
    if (currentPage.redoStack.isNotEmpty) return true;

    // Check next pages
    for (int i = currentPageIndex + 1; i < pageIds.length; i++) {
      final nextPage = _pages[pageIds[i]]!;
      if (nextPage.redoStack.isNotEmpty) return true;
    }
    
    return false;
  }

  void _showEditDialog() {
    if (_selectedTextId == null) return;
    
    final selectedText = _pages[_activePageId]!.texts
        .firstWhere((text) => text.id == _selectedTextId);
    
    showDialog(
      context: context,
      builder: (context) {
        String updatedText = selectedText.text;
        return AlertDialog(
          title: const Text('Edit Text'),
          content: TextField(
            controller: TextEditingController(text: selectedText.text),
            onChanged: (value) {
              updatedText = value;
            },
          ),
          actions: [
            TextButton(
              onPressed: () {
                _updateSelectedText((text) => text.copyWith(text: updatedText));
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
    if (_selectedTextId == null) return;

    final selectedText = _pages[_activePageId]!.texts
        .firstWhere((text) => text.id == _selectedTextId);
    Color tempColor = isFontColor ? selectedText.fontColor : selectedText.borderColor;

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
                _updateSelectedText((text) {
                  if (isFontColor) {
                    return text.copyWith(fontColor: tempColor);
                  } else {
                    return text.copyWith(borderColor: tempColor);
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

  void _updateSelectedText(TextState Function(TextState) update, {bool saveImmediately = true}) {
    if (_selectedTextId == null) return;

    setState(() {
      final page = _pages[_activePageId]!;
      final index = page.texts.indexWhere((text) => text.id == _selectedTextId);
      if (index != -1) {
        final updatedText = update(page.texts[index]);
        page.texts[index] = updatedText;
        
        if (saveImmediately) {
          _saveState(_activePageId);
        }
      }
    });
  }

  void _onPanStart(String textId, DragStartDetails details) {
    setState(() {
      _selectedTextId = textId;
      // Update selection state for all texts
      final page = _pages[_activePageId]!;
      for (var text in page.texts) {
        text.isSelected = text.id == textId;
      }
    });
  }

  void _onPanUpdate(DragUpdateDetails details, BoxConstraints constraints) {
    if (_selectedTextId == null) return;

    _updateSelectedText((text) {
      final containerWidth = constraints.maxWidth;
      final containerHeight = constraints.maxHeight;

      final textStyle = GoogleFonts.getFont(
        text.fontFamily,
        fontSize: text.fontSize,
      );
      final textPainter = TextPainter(
        text: TextSpan(text: text.text, style: textStyle),
        textDirection: TextDirection.ltr,
      )..layout();

      final textWidth = textPainter.width;
      final textHeight = textPainter.height;

      final containerCenterX = containerWidth / 2;
      final containerCenterY = containerHeight / 2;

      Offset newPosition = text.position + details.delta;

      final constrainedX = newPosition.dx.clamp(
        -containerCenterX + textWidth / 2,
        containerCenterX - textWidth / 2,
      );

      final constrainedY = newPosition.dy.clamp(
        -containerCenterY + textHeight / 2,
        containerCenterY - textHeight / 2,
      );

      return text.copyWith(position: Offset(constrainedX, constrainedY));
    }, saveImmediately: false);
  }

  void _onPanEnd(DragEndDetails details) {
    _saveState(_activePageId);
  }

  void _changeFontSize(bool increase) {
    if (_selectedTextId == null) return;

    _updateSelectedText((text) {
      final newSize = text.fontSize + (increase ? 2 : -2);
      return text.copyWith(fontSize: newSize < 8 ? 8 : newSize);
    });
  }

  void _toggleTextStyle(String style) {
    if (_selectedTextId == null) return;

    _updateSelectedText((text) {
      switch (style) {
        case 'bold':
          return text.copyWith(isBold: !text.isBold);
        case 'italic':
          return text.copyWith(isItalic: !text.isItalic);
        case 'underline':
          return text.copyWith(isUnderline: !text.isUnderline);
        default:
          return text;
      }
    });
  }

  void _onPageChanged(int index) {
    setState(() {
      _activePageId = pageIds[index];
      _selectedTextId = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Multi-Text Editor'),
        actions: [
          IconButton(
            icon: const Icon(Icons.undo),
            onPressed: _canUndo() ? _undo : null,
          ),
          IconButton(
            icon: const Icon(Icons.redo),
            onPressed: _canRedo() ? _redo : null,
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _addNewText(_activePageId),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              itemCount: pageIds.length,
              onPageChanged: _onPageChanged,
              itemBuilder: (context, index) {
                final pageId = pageIds[index];
                final page = _pages[pageId]!;

                return LayoutBuilder(
                  builder: (context, constraints) {
                    double containerWidth = constraints.maxWidth * 0.9;
                    double containerHeight = containerWidth * (16 / 9);

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
                            return Stack(
                              children: page.texts.map((textState) {
                                return Positioned.fill(
                                  child: GestureDetector(
                                    onPanStart: (details) => _onPanStart(textState.id, details),
                                    onPanUpdate: (details) => _onPanUpdate(details, constraints),
                                    onPanEnd: _onPanEnd,
                                    child: Stack(
                                      alignment: Alignment.center,
                                      children: [
                                        Transform.translate(
                                          offset: textState.position,
                                          child: Container(
                                            decoration: BoxDecoration(
                                              border: Border.all(
                                                color: textState.isSelected ? Colors.blue : textState.borderColor,
                                                width: textState.isSelected ? 2 : 1,
                                              ),
                                            ),
                                            child: Text(
                                              textState.text,
                                              style: GoogleFonts.getFont(
                                                textState.fontFamily,
                                                fontSize: textState.fontSize,
                                                color: textState.fontColor,
                                                fontWeight: textState.isBold ? FontWeight.bold : FontWeight.normal,
                                                fontStyle: textState.isItalic ? FontStyle.italic : FontStyle.normal,
                                                decoration: textState.isUnderline ? TextDecoration.underline : null,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              }).toList(),
                            );
                          },
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
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
                // IconButton(
                //   icon: const Icon(Icons.border_color),
                //   onPressed: () => _pickColor(false),
                // ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}