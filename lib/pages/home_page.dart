import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:google_fonts/google_fonts.dart';

class TextState {
  final String text;
  final double fontSize;
  final Color fontColor;
  final String fontFamily;
  final Offset position;
  final Color borderColor;
  final bool isBold;
  final bool isItalic;
  final bool isUnderline;

  TextState(
      {required this.text,
      required this.fontSize,
      required this.fontColor,
      required this.fontFamily,
      required this.position,
      required this.borderColor,
      required this.isBold,
      required this.isItalic,
      required this.isUnderline});
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final List<TextState> _undoStack = [];
  final List<TextState> _redoStack = [];
  String _fontFamily = 'Roboto';
  double fontSize = 16;
  Color _fontColor = Colors.black;
  String currentText = 'Change Me';
  Offset _position = Offset(0, 0);
  Offset _initialPosition = Offset(0, 0);
  Color _borderColor = Colors.black;
  bool _isBold = false;
  bool _isItalic = false;
  bool _isUnderline = false;

  @override
  void initState() {
    super.initState();
    _saveState();
  }

  void _saveState() {
    if (_undoStack.isEmpty ||
        _undoStack.last.text != currentText ||
        _undoStack.last.fontSize != fontSize ||
        _undoStack.last.fontColor != _fontColor ||
        _undoStack.last.fontFamily != _fontFamily ||
        _undoStack.last.position != _position ||
        _undoStack.last.isBold != _isBold ||
        _undoStack.last.isItalic != _isItalic ||
        _undoStack.last.isUnderline != _isUnderline) {
      _undoStack.add(TextState(
          text: currentText,
          fontSize: fontSize,
          fontColor: _fontColor,
          fontFamily: _fontFamily,
          position: _position,
          borderColor: _borderColor,
          isBold: _isBold,
          isItalic: _isItalic,
          isUnderline: _isUnderline));
      _redoStack.clear();
    }
  }

  void _undo() {
    if (_undoStack.length > 1) {
      final previousState = _undoStack.removeLast();
      _redoStack.add(previousState);
      final lastState = _undoStack.last;

      setState(() {
        currentText = lastState.text;
        fontSize = lastState.fontSize;
        _fontColor = lastState.fontColor;
        _fontFamily = lastState.fontFamily;
        _position = lastState.position;
        _borderColor = lastState.borderColor;
        _isBold = lastState.isBold;
        _isItalic = lastState.isItalic;
        _isUnderline = lastState.isBold;
      });
    }
  }

  void _redo() {
    if (_redoStack.isNotEmpty) {
      final nextState = _redoStack.removeLast();
      _undoStack.add(TextState(
          text: currentText,
          fontSize: fontSize,
          fontColor: _fontColor,
          fontFamily: _fontFamily,
          position: _position,
          borderColor: _borderColor,
          isBold: _isBold,
          isItalic: _isItalic,
          isUnderline: _isUnderline));

      setState(() {
        currentText = nextState.text;
        fontSize = nextState.fontSize;
        _fontColor = nextState.fontColor;
        _fontFamily = nextState.fontFamily;
        _position = nextState.position;
        _borderColor = nextState.borderColor;
        _isBold = nextState.isBold;
        _isItalic = nextState.isItalic;
        _isUnderline = nextState.isUnderline;
      });
    }
  }

  void _changeFontColor() {
    Color tempColor = _fontColor;
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Choose Font Color"),
          content: SingleChildScrollView(
            child: ColorPicker(
              pickerColor: _fontColor,
              onColorChanged: (color) {
                setState(() {
                  tempColor = color;
                });
              },
              labelTypes: [],
              pickerAreaHeightPercent: 0.8,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                setState(() {
                  _fontColor = tempColor;
                });
                _saveState();
                Navigator.of(context).pop();
              },
              child: const Text("OK"),
            ),
          ],
        );
      },
    );
  }

  void _onPanStart(DragStartDetails details) {
    _initialPosition = details.localPosition;
  }

  void _onPanUpdate(DragUpdateDetails details) {
    setState(() {
      _position = _position + details.localPosition - _initialPosition;
      _initialPosition = details.localPosition;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Responsive font size based on screen width
    double screenWidth = MediaQuery.of(context).size.width;
    double scaledFontSize =
        screenWidth * 0.05; // Scaled font size based on screen width

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text(
          'Redo Undo',
          style: TextStyle(fontSize: scaledFontSize, color: Colors.white),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return Column(
              children: [
                Expanded(
                  child: Center(
                    child: Transform.translate(
                      offset: _position,
                      child: GestureDetector(
                        onPanStart: _onPanStart,
                        onPanUpdate: _onPanUpdate,
                        onPanEnd: (value) => _saveState(),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: _fontColor,
                              width: 2,
                            ),
                          ),
                          child: Text(
                            currentText,
                            style: GoogleFonts.getFont(_fontFamily,
                                color: _fontColor,
                                fontSize: fontSize,
                                decoration:_isUnderline? TextDecoration.underline:TextDecoration.none,
                                fontWeight: _isBold
                                    ? FontWeight.bold
                                    : FontWeight
                                        .normal,
                                fontStyle:_isItalic? FontStyle.italic:FontStyle.normal
                                // Use responsive font size
                                ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Container(
                  color: Colors.black,
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          IconButton(
                            onPressed: _undoStack.isEmpty ? null : _undo,
                            icon: Icon(
                              Icons.undo,
                              color: _undoStack.length <= 1
                                  ? Colors.grey[800]
                                  : Colors.white,
                            ),
                          ),
                          IconButton(
                            onPressed: _redoStack.isEmpty ? null : _redo,
                            icon: Icon(
                              Icons.redo,
                              color: _redoStack.isEmpty
                                  ? Colors.grey[800]
                                  : Colors.white,
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              setState(() {
                                _isBold = !_isBold;
                              });
                              _saveState();
                            },
                            child: Text(
                              'B',
                              style: TextStyle(
                                  color: _isBold ? Colors.blue : Colors.white,
                                  fontSize: 21),
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              setState(() {
                                _isItalic = !_isItalic;
                              });
                              _saveState();
                            },
                            child: Text(
                              'I',
                              style: TextStyle(
                                  color: _isItalic ? Colors.blue : Colors.white,
                                  fontSize: 21),
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              setState(() {
                                _isUnderline = !_isUnderline;
                              });
                              _saveState();
                            },
                            child: Text(
                              'U',
                              style: TextStyle(
                                  color: _isUnderline ? Colors.blue : Colors.white,
                                  fontSize: 21),
                            ),
                          ),
                        ],
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Slider(
                            value: fontSize,
                            min: 12,
                            max: 48,
                            onChanged: (value) {
                              setState(() {
                                fontSize = value;
                              });
                            },
                            onChangeEnd: (value) => _saveState(),
                          ),
                          SizedBox(width: 12),
                          DropdownButton<String>(
                            value: _fontFamily,
                            dropdownColor: Colors.black,
                            items: const [
                              DropdownMenuItem(
                                  value: 'Roboto',
                                  child: Text('Roboto',
                                      style: TextStyle(color: Colors.white))),
                              DropdownMenuItem(
                                  value: 'Open Sans',
                                  child: Text('Open Sans',
                                      style: TextStyle(color: Colors.white))),
                              DropdownMenuItem(
                                  value: 'Lobster',
                                  child: Text('Lobster',
                                      style: TextStyle(color: Colors.white))),
                              DropdownMenuItem(
                                  value: 'Oswald',
                                  child: Text('Oswald',
                                      style: TextStyle(color: Colors.white))),
                              DropdownMenuItem(
                                  value: 'Merriweather',
                                  child: Text('Merriweather',
                                      style: TextStyle(color: Colors.white))),
                              DropdownMenuItem(
                                  value: 'Pacifico',
                                  child: Text('Pacifico',
                                      style: TextStyle(color: Colors.white))),
                              DropdownMenuItem(
                                  value: 'Playfair Display',
                                  child: Text('Playfair Display',
                                      style: TextStyle(color: Colors.white))),
                              DropdownMenuItem(
                                  value: 'Raleway',
                                  child: Text('Raleway',
                                      style: TextStyle(color: Colors.white))),
                            ],
                            onChanged: (newValue) {
                              setState(() {
                                _fontFamily = newValue!;
                              });
                              _saveState();
                            },
                          ),
                          SizedBox(width: 12),
                          IconButton(
                            onPressed: _changeFontColor,
                            icon: const Icon(
                              Icons.palette,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
