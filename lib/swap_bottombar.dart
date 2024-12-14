import 'dart:ui';

import 'package:flutter/material.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: Colors.grey[900],
        body: Center(
          child: Dock(
            items: const [
              Icons.person,
              Icons.message,
              Icons.call,
              Icons.camera,
              Icons.photo,
            ],
            labels: const [
              'Profile',
              'Messages',
              'Calls',
              'Camera',
              'Photos',
            ],
            builder: (e) {
              return HoverItem(
                child: Container(
                  constraints: const BoxConstraints(minWidth: 48),
                  height: 48,
                  margin: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    color:
                        Colors.primaries[e.hashCode % Colors.primaries.length],
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Icon(
                      e,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class Dock<T> extends StatefulWidget {
  const Dock({
    super.key,
    this.items = const [],
    this.labels = const [],
    required this.builder,
  });

  final List<T> items;
  final List<String> labels;
  final Widget Function(T) builder;

  @override
  State<Dock<T>> createState() => _DockState<T>();
}

class _DockState<T> extends State<Dock<T>> with SingleTickerProviderStateMixin {
  late final List<T> _items = widget.items.toList();
  String _infoText = '';
  int? _draggingIndex;
  int? _targetIndex;
  int? _hoveredIndex;
  int? _selectedIndex;
  bool _hoveringTaskbar = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedOpacity(
          opacity: _infoText.isNotEmpty ? 1.0 : 0.0,
          duration: const Duration(milliseconds: 300),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.3),
                  ),
                ),
                child: Text(
                  _infoText,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: Colors.white.withOpacity(0.7)),
          padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 10),
          child: MouseRegion(
            onEnter: (_) {
              setState(() {
                _hoveringTaskbar = true;
              });
            },
            onExit: (_) {
              setState(() {
                _hoveringTaskbar = false;
              });
            },
            child: Column(
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: _items.asMap().entries.map(
                    (entry) {
                      int index = entry.key;
                      T item = entry.value;
                      double archHeight = _hoveringTaskbar
                          ? -5.0 *
                              (1.0 -
                                  (index - (_items.length - 1) / 2).abs() /
                                      (_items.length / 2))
                          : 0.0;
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: MouseRegion(
                          onEnter: (_) {
                            setState(() {
                              _hoveredIndex = index;
                              _infoText = widget.labels[index];
                            });
                          },
                          onExit: (_) {
                            setState(() {
                              _hoveredIndex = null;
                              _infoText = '';
                            });
                          },
                          child: DragTarget<int>(
                            onAcceptWithDetails: (details) {
                              setState(() {
                                final draggedItem =
                                    _items.removeAt(details.data);
                                _items.insert(index, draggedItem);
                                _draggingIndex = null;
                                _targetIndex = null;
                                _infoText = widget.labels[index];
                              });
                            },
                            onWillAcceptWithDetails: (details) {
                              setState(() {
                                _targetIndex = index;
                                _infoText = ' ${widget.labels[index]}';
                              });
                              return true;
                            },
                            onLeave: (_) {
                              setState(() {
                                _targetIndex = null;
                                _infoText = '';
                              });
                            },
                            builder: (context, candidateData, rejectedData) {
                              double scale = 1.0;
                              if (_hoveredIndex == index) {
                                scale = 1.2;
                              } else if (_hoveredIndex != null) {
                                scale = 0.9;
                              }

                              return AnimatedContainer(
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeInOut,
                                transform: (_draggingIndex != null &&
                                        _targetIndex != null &&
                                        _targetIndex == index &&
                                        _draggingIndex != index)
                                    ? Matrix4.translationValues(
                                        20.0 *
                                            ((_draggingIndex! < index)
                                                ? -1
                                                : 1),
                                        0,
                                        0,
                                      )
                                    : Matrix4.translationValues(
                                        0,
                                        archHeight,
                                        0,
                                      ),
                                child: Transform.scale(
                                  scale: scale,
                                  child: BounceOnClick(
                                    index: index,
                                    onSelected: () {
                                      setState(() {
                                        _selectedIndex = index;
                                      });
                                    },
                                    child: Draggable<int>(
                                      data: index,
                                      feedback: Material(
                                        color: Colors.transparent,
                                        child: widget.builder(item),
                                      ),
                                      childWhenDragging:
                                          const SizedBox.shrink(),
                                      onDragStarted: () {
                                        setState(() {
                                          _draggingIndex = index;
                                          _infoText =
                                              ' ${widget.labels[index]}';
                                        });
                                      },
                                      onDragCompleted: () {
                                        setState(() {
                                          _draggingIndex = null;
                                          _targetIndex = null;
                                          _infoText = '';
                                        });
                                      },
                                      onDraggableCanceled: (_, __) {
                                        setState(() {
                                          _draggingIndex = null;
                                          _targetIndex = null;
                                          _infoText = '';
                                        });
                                      },
                                      child: _draggingIndex == index
                                          ? Opacity(
                                              opacity: 0.5,
                                              child: widget.builder(item),
                                            )
                                          : widget.builder(item),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      );
                    },
                  ).toList(),
                ),
                if (_selectedIndex != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      height: 50,
                      width: 200,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Center(
                        child: Text(
                          'Taskbar: ${widget.labels[_selectedIndex!]}',
                          style: const TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class HoverItem extends StatefulWidget {
  const HoverItem({super.key, required this.child});

  final Widget child;

  @override
  State<HoverItem> createState() => _HoverItemState();
}

class _HoverItemState extends State<HoverItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scale = Tween<double>(begin: 1.0, end: 1.1).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => _controller.forward(),
      onExit: (_) => _controller.reverse(),
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Transform.scale(
            scale: _scale.value,
            child: child,
          );
        },
        child: widget.child,
      ),
    );
  }
}

class BounceOnClick extends StatefulWidget {
  const BounceOnClick({
    super.key,
    required this.child,
    required this.onSelected,
    required this.index,
  });

  final Widget child;
  final VoidCallback onSelected;
  final int index;

  @override
  State<BounceOnClick> createState() => _BounceOnClickState();
}

class _BounceOnClickState extends State<BounceOnClick>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _bounce;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _bounce = Tween<double>(begin: 1.0, end: 1.3).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      child: AnimatedBuilder(
        animation: _bounce,
        builder: (context, child) {
          return Transform.scale(
            scale: _bounce.value,
            child: child,
          );
        },
        child: widget.child,
      ),
    );
  }
}
