import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:google_fonts/google_fonts.dart';

class TextState {
  final String text;
  final double fontSize;
  final Color fontColor;
  final String fontFamily;
  final Offset position; // Add position to the state

  TextState({
    required this.text,
    required this.fontSize,
    required this.fontColor,
    required this.fontFamily,
    required this.position, // Initialize position in the constructor
  });
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
  Offset _position = Offset(0, 0); // Position for the draggable text
  Offset _initialPosition = Offset(0, 0); // Initial touch position

  @override
  void initState() {
    super.initState();
    _saveState(); // Save initial state
  }

  void _saveState() {
    // Save state only if it differs from the last saved state
    if (_undoStack.isEmpty ||
        _undoStack.last.text != currentText ||
        _undoStack.last.fontSize != fontSize ||
        _undoStack.last.fontColor != _fontColor ||
        _undoStack.last.fontFamily != _fontFamily ||
        _undoStack.last.position != _position) { // Check for position change
      _undoStack.add(TextState(
        text: currentText,
        fontSize: fontSize,
        fontColor: _fontColor,
        fontFamily: _fontFamily,
        position: _position, // Save the position
      ));
      _redoStack.clear(); // Clear redo stack on any new action
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
        _position = lastState.position; // Restore position
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
        position: _position, // Include position in the saved state
      ));

      setState(() {
        currentText = nextState.text;
        fontSize = nextState.fontSize;
        _fontColor = nextState.fontColor;
        _fontFamily = nextState.fontFamily;
        _position = nextState.position; // Restore position
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

  // Dragging gesture handler
  void _onPanStart(DragStartDetails details) {
    // Capture the initial touch position when dragging starts
    _initialPosition = details.localPosition;
  }

  void _onPanUpdate(DragUpdateDetails details) {
    setState(() {
      // Calculate the difference in the drag position from the initial position
      _position = _position + details.localPosition - _initialPosition;
      // Update the initial position to the current position to track the movement
      _initialPosition = details.localPosition;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text(
          'Redo Undo',
          style: TextStyle(fontSize: 32, color: Colors.white),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Center(
                child: Transform.translate(
                  offset: _position,
                  child: GestureDetector(
                    onPanStart: _onPanStart, // Handle drag start
                    onPanUpdate: _onPanUpdate, // Handle drag update
                    onPanEnd: (value)=>{
                      _saveState()
                    },
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
                        style: GoogleFonts.getFont(
                          _fontFamily,
                          color: _fontColor,
                          fontSize: fontSize,
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
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        onPressed: _undoStack.isEmpty ? null : _undo,
                        icon: Icon(
                          Icons.undo,
                          color: _undoStack.length <= 1 ? Colors.grey[800] : Colors.white,
                        ),
                      ),
                      IconButton(
                        onPressed: _redoStack.isEmpty ? null : _redo,
                        icon: Icon(
                          Icons.redo,
                          color: _redoStack.isEmpty ? Colors.grey[800] : Colors.white,
                        ),
                      ),
                    ],
                  ),
                  Slider(
                    value: fontSize,
                    min: 12,
                    max: 48,
                    onChanged: (value) {
                      setState(() {
                        fontSize = value;
                      });
                    },
                    onChangeEnd: (value) => _saveState(), // Save on slider change end
                  ),
                  SizedBox(width: 12),
                  DropdownButton<String>(
                    value: _fontFamily,
                    dropdownColor: Colors.black,
                    items: const [
                      DropdownMenuItem(value: 'Roboto', child: Text('Roboto', style: TextStyle(color: Colors.white))),
                      DropdownMenuItem(value: 'Open Sans', child: Text('Open Sans', style: TextStyle(color: Colors.white))),
                      DropdownMenuItem(value: 'Lobster', child: Text('Lobster', style: TextStyle(color: Colors.white))),
                      DropdownMenuItem(value: 'Oswald', child: Text('Oswald', style: TextStyle(color: Colors.white))),
                      DropdownMenuItem(value: 'Merriweather', child: Text('Merriweather', style: TextStyle(color: Colors.white))),
                      DropdownMenuItem(value: 'Pacifico', child: Text('Pacifico', style: TextStyle(color: Colors.white))),
                      DropdownMenuItem(value: 'Playfair Display', child: Text('Playfair Display', style: TextStyle(color: Colors.white))),
                      DropdownMenuItem(value: 'Raleway', child: Text('Raleway', style: TextStyle(color: Colors.white))),
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
            ),
          ],
        ),
      ),
    );
  }
}
