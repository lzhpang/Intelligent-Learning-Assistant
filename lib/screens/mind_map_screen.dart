import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:ui' as ui;
import 'dart:math' as Math;
import 'package:flutter/scheduler.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'dart:ui';
import 'package:share_plus/share_plus.dart';
import '../config/anime_theme.dart';

// 节点类
class MindNode {
  final String id;
  String text;
  Offset position;
  final bool isRoot;

  MindNode({
    required this.id,
    required this.text,
    required this.position,
    this.isRoot = false,
  });
}

// 连接类
class MindConnection {
  final String from;
  final String to;

  MindConnection({required this.from, required this.to});
}

class MindMapScreen extends StatefulWidget {
  const MindMapScreen({super.key});

  @override
  _MindMapScreenState createState() => _MindMapScreenState();
}

class _MindMapScreenState extends State<MindMapScreen> {
  List<MindNode> nodes = [
    MindNode(
      id: '1',
      text: '中心主题',
      position: const Offset(200, 300),
      isRoot: true,
    ),
  ];

  List<MindConnection> connections = [];
  List<Map<String, dynamic>> savedMindMaps = [];
  String currentMindMapId = '';

  MindNode? _selectedNode;
  MindNode? _draggedNode;
  double _scale = 1.0;
  double _previousScale = 1.0;
  DateTime _lastTapTime = DateTime.now();
  MindNode? _lastTappedNode;
  Offset _panStart = Offset.zero;
  Offset _previousPan = Offset.zero;
  Offset _dragStart = Offset.zero;

  // 添加模式变量：true为自由拖动模式，false为树状结构模式
  bool _isFreeMode = true;
  // 添加强制重绘变量，用于优化节点拖拽性能
  bool _forceRepaint = false;
  
  // 添加历史记录相关变量，用于撤回功能
  List<Map<String, dynamic>> _history = []; // 存储历史状态
  int _historyIndex = -1; // 当前历史记录索引

  // 手势识别相关
  late double _canvasScale;

  void _addNode() {
    if (_selectedNode != null) {
      final newNode = MindNode(
        id: DateTime.now().toString(),
        text: '新节点',
        position: Offset(
          _selectedNode!.position.dx + 100,
          _selectedNode!.position.dy + 50,
        ),
      );

      setState(() {
        nodes.add(newNode);
        connections.add(MindConnection(
          from: _selectedNode!.id,
          to: newNode.id,
        ));
        _selectedNode = newNode;
      });
      
      // 保存历史状态
      _saveToHistory();
    } else {
      // 如果没有选中节点，则添加到根节点
      final centerNode = nodes.firstWhere((node) => node.isRoot);
      final newNode = MindNode(
        id: DateTime.now().toString(),
        text: '新节点',
        position: Offset(
          centerNode.position.dx + 100,
          centerNode.position.dy + 50,
        ),
      );

      setState(() {
        nodes.add(newNode);
        connections.add(MindConnection(
          from: centerNode.id,
          to: newNode.id,
        ));
        _selectedNode = newNode;
      });
      
      // 保存历史状态
      _saveToHistory();
    }
  }

  void _deleteNode() {
    if (_selectedNode != null && !_selectedNode!.isRoot) {
      setState(() {
        // 删除相关连接
        connections.removeWhere((conn) =>
            conn.from == _selectedNode!.id || conn.to == _selectedNode!.id);
        // 删除节点
        nodes.remove(_selectedNode);
        _selectedNode = null;
      });
      
      // 保存历史状态
      _saveToHistory();
    }
  }

  void _editNodeText() {
    if (_selectedNode != null) {
      TextEditingController controller =
          TextEditingController();
      
      // 检查节点文本是否为默认值"新节点"
      if (_selectedNode!.text == '新节点') {
        // 如果是默认值，则全选文本，方便用户直接输入
        controller.text = _selectedNode!.text;
        controller.selection = TextSelection(
          baseOffset: 0,
          extentOffset: controller.text.length,
        );
      } else {
        // 如果不是默认值，则将光标放在文本末尾
        controller.text = _selectedNode!.text;
        controller.selection = TextSelection(
          baseOffset: controller.text.length,
          extentOffset: controller.text.length,
        );
      }

      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text(
              '编辑节点',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: AnimeTheme.textColor,
              ),
            ),
            content: TextField(
              controller: controller,
              autofocus: true, // 自动获取焦点
              decoration: const InputDecoration(
                hintText: '输入节点文本',
                border: OutlineInputBorder(),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: AnimeTheme.primaryColor),
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text('取消'),
              ),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _selectedNode!.text = controller.text;
                  });
                  Navigator.of(context).pop();
                  
                  // 保存历史状态
                  _saveToHistory();
                },
                style: AnimeTheme.animeButtonStyle,
                child: const Text('确定'),
              ),
            ],
          );
        },
      );
    }
  }

  void _handleNodeTap(MindNode node) {
    // 如果刚刚进行了拖拽操作，则不处理点击事件，避免误触
    if (_draggedNode != null) {
      return;
    }
    
    final now = DateTime.now();
    final isDoubleTap = _lastTappedNode?.id == node.id && 
        now.difference(_lastTapTime).inMilliseconds < 300;

    if (isDoubleTap) {
      _handleNodeDoubleTap(node);
    } else {
      // 只在选择节点变化时才触发重绘
      if (_selectedNode?.id != node.id) {
        setState(() {
          _selectedNode = node;
        });
      }
    }

    _lastTappedNode = node;
    _lastTapTime = now;
  }

  void _handleNodeDoubleTap(MindNode node) {
    setState(() {
      _selectedNode = node;
    });
    _editNodeText();
  }

  void _handleNodeLongPress(MindNode node) {
    setState(() {
      _selectedNode = node;
    });
    _editNodeText();
  }

  @override
  void initState() {
    super.initState();
    _loadSavedMindMaps();
    // 初始化时保存第一个历史状态
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _saveToHistory();
    });
  }

  void _handleScaleStart(ScaleStartDetails details) {
    _previousScale = _scale;
    _panStart = details.focalPoint;
    _previousPan = Offset.zero;
  }

  void _handleScaleUpdate(ScaleUpdateDetails details) {
    setState(() {
      if (details.pointerCount == 2) {
        // 双指操作 - 缩放和移动画布
        // 处理缩放
        _scale = (_previousScale * details.scale).clamp(0.5, 3.0);

        // 处理平移（双指平移）
        final panDelta = details.focalPoint - _panStart;
        final adjustedPanDelta = panDelta - _previousPan;
        _previousPan = panDelta;

        // 平移整个画布
        for (var node in nodes) {
          node.position += adjustedPanDelta / _scale;
        }
      } else if (details.pointerCount == 1) {
        // 单指操作 - 移动画布
        final panDelta = details.focalPoint - _panStart;
        final adjustedPanDelta = panDelta - _previousPan;
        _previousPan = panDelta;

        // 平移整个画布
        for (var node in nodes) {
          node.position += adjustedPanDelta / _scale;
        }
      }
    });
  }

  void _handleNodeDragStart(MindNode node, DragStartDetails details) {
    // 不在开始时调用setState，避免不必要的重绘
    _selectedNode = node;
    _draggedNode = node;
    _dragStart = details.globalPosition;
  }

  void _handleNodeDragUpdate(DragUpdateDetails details) {
    if (_draggedNode != null) {
      // 直接更新节点位置，不立即触发重绘以减少延迟
      final delta = details.delta / _scale;
      _draggedNode!.position += delta;
      
      // 设置强制重绘标志
      _forceRepaint = !_forceRepaint;
      
      // 强制重绘画布以显示节点移动
      setState(() {
        // 只更新画布，不更新其他状态
      });
    }
  }

  void _handleNodeDragEnd(DragEndDetails details) {
    // 拖拽结束，清除拖拽状态
    _draggedNode = null;
  }

  void _saveMindMap() async {
    final prefs = await SharedPreferences.getInstance();
    final savedMapsJson = prefs.getStringList('mind_maps') ?? [];

    // 将当前思维导图转换为可保存的格式
    final mindMapData = {
      'id': currentMindMapId.isEmpty
          ? DateTime.now().toString()
          : currentMindMapId,
      'name': '思维导图 ${savedMapsJson.length + 1}',
      'nodes': nodes
          .map((node) => {
                'id': node.id,
                'text': node.text,
                'position': {
                  'dx': node.position.dx,
                  'dy': node.position.dy,
                },
                'isRoot': node.isRoot,
              })
          .toList(),
      'connections': connections
          .map((conn) => {
                'from': conn.from,
                'to': conn.to,
              })
          .toList(),
    };

    // 更新保存的思维导图列表
    final updatedMaps = List<Map<String, dynamic>>.from(savedMapsJson
        .map((jsonStr) => json.decode(jsonStr) as Map<String, dynamic>));
    updatedMaps.removeWhere((map) => map['id'] == mindMapData['id']);
    updatedMaps.add(mindMapData);

    // 保存到SharedPreferences
    final updatedMapsJson = updatedMaps.map((map) => json.encode(map)).toList();
    await prefs.setStringList('mind_maps', updatedMapsJson);

    // 更新当前ID
    setState(() {
      currentMindMapId = mindMapData['id'] as String;
    });

    // 显示保存成功的提示
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          '思维导图已保存',
          style: TextStyle(color: AnimeTheme.textColor),
        ),
        backgroundColor: AnimeTheme.cardColor,
      ),
    );
  }

  void _loadSavedMindMaps() async {
    final prefs = await SharedPreferences.getInstance();
    final savedMapsJson = prefs.getStringList('mind_maps') ?? [];
    setState(() {
      savedMindMaps = savedMapsJson
          .map((jsonStr) => json.decode(jsonStr) as Map<String, dynamic>)
          .toList();
    });
  }

  void _loadMindMap(Map<String, dynamic> mindMapData) {
    setState(() {
      nodes = (mindMapData['nodes'] as List)
          .map((nodeData) => MindNode(
                id: nodeData['id'] as String,
                text: nodeData['text'] as String,
                position: Offset(
                  (nodeData['position']['dx'] as num).toDouble(),
                  (nodeData['position']['dy'] as num).toDouble(),
                ),
                isRoot: nodeData['isRoot'] as bool,
              ))
          .toList();

      connections = (mindMapData['connections'] as List)
          .map((connData) => MindConnection(
                from: connData['from'] as String,
                to: connData['to'] as String,
              ))
          .toList();

      currentMindMapId = mindMapData['id'] as String;
      _selectedNode = null;
    });
  }

  void _showSavedMindMaps() {
    _loadSavedMindMaps();
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text(
            '已保存的思维导图',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: AnimeTheme.textColor,
            ),
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: savedMindMaps.isEmpty
                ? const Text('暂无保存的思维导图')
                : ListView.builder(
                    shrinkWrap: true,
                    itemCount: savedMindMaps.length,
                    itemBuilder: (context, index) {
                      final mindMap = savedMindMaps[index];
                      return Card(
                        color: AnimeTheme.cardColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                          side: BorderSide(
                            color: AnimeTheme.primaryColor.withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                        child: ListTile(
                          title: Text(
                            mindMap['name'] as String,
                            style: const TextStyle(
                              color: AnimeTheme.textColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          onTap: () {
                            _loadMindMap(mindMap);
                            Navigator.of(context).pop();
                          },
                          trailing: IconButton(
                            icon: const Icon(
                              Icons.delete,
                              color: AnimeTheme.accentColor,
                            ),
                            onPressed: () {
                              setState(() {
                                savedMindMaps.removeAt(index);
                              });
                              // 更新SharedPreferences
                              SharedPreferences.getInstance().then((prefs) {
                                final updatedMapsJson = savedMindMaps
                                    .map((map) => json.encode(map))
                                    .toList();
                                prefs.setStringList(
                                    'mind_maps', updatedMapsJson);
                              });
                            },
                          ),
                        ),
                      );
                    },
                  ),
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              style: AnimeTheme.animeButtonStyle,
              child: const Text('关闭'),
            ),
          ],
        );
      },
    );
  }

  void _newMindMap() {
    setState(() {
      nodes = [
        MindNode(
          id: '1',
          text: '中心主题',
          position: const Offset(200, 300),
          isRoot: true,
        ),
      ];
      connections = [];
      currentMindMapId = '';
      _selectedNode = null;
    });
  }

  // 切换模式的方法
  void _toggleMode() {
    setState(() {
      _isFreeMode = !_isFreeMode;
      
      // 切换到树状模式时自动排列节点
      if (!_isFreeMode) {
        _arrangeNodesInTreeStructure();
      }
    });
  }

  // 将节点排列成树状结构
  void _arrangeNodesInTreeStructure() {
    if (nodes.isEmpty) return;
    
    // 找到根节点
    final root = nodes.firstWhere((node) => node.isRoot, orElse: () => nodes.first);
    
    // 设置根节点位置在画布中心偏左
    root.position = const Offset(200, 300);
    
    // 按层级排列子节点
    _positionChildNodes(root, 1);
    
    // 自动调整画布以便显示所有节点
    _fitAllNodesInView();
  }

  // 递归排列子节点，实现经典的树状思维导图形状
  void _positionChildNodes(MindNode parent, int level) {
    // 找到与父节点相连的所有子节点
    final childConnections = connections.where((conn) => conn.from == parent.id).toList();
    
    if (childConnections.isEmpty) return;
    
    // 计算更紧凑的垂直分布范围
    // 进一步减小垂直间距，使节点排列更紧凑
    final verticalSpacing = Math.max(50, 150 ~/ Math.max(1, level)); // 从70减小到50，从200减小到150
    final totalHeight = (childConnections.length - 1) * verticalSpacing;
    final startY = parent.position.dy - totalHeight / 2;
    
    // 计算更紧凑的水平位置
    // 减小水平间距，使节点排列更紧凑
    final horizontalSpacing = 150 + level * 15; // 保持之前的优化
    final x = parent.position.dx + horizontalSpacing;
    
    // 计算每个子节点的位置
    for (int i = 0; i < childConnections.length; i++) {
      try {
        final childNode = nodes.firstWhere((node) => node.id == childConnections[i].to);
        
        // 设置子节点位置
        final y = startY + i * verticalSpacing;
        childNode.position = Offset(x.toDouble(), y.toDouble());
        
        // 递归排列孙子节点
        _positionChildNodes(childNode, level + 1);
      } catch (e) {
        // 节点未找到，跳过
        continue;
      }
    }
  }

  // 自动调整画布以便显示所有节点
  void _fitAllNodesInView() {
    if (nodes.isEmpty) return;

    // 计算所有节点的边界
    double minX = double.infinity;
    double minY = double.infinity;
    double maxX = double.negativeInfinity;
    double maxY = double.negativeInfinity;

    for (var node in nodes) {
      final isRoot = node.isRoot;
      final radius = isRoot ? 60.0 : 50.0;

      minX = Math.min(minX, node.position.dx - radius);
      minY = Math.min(minY, node.position.dy - radius);
      maxX = Math.max(maxX, node.position.dx + radius);
      maxY = Math.max(maxY, node.position.dy + radius);
    }

    // 计算边界尺寸
    final width = maxX - minX;
    final height = maxY - minY;

    // 计算画布中心
    final centerX = (minX + maxX) / 2;
    final centerY = (minY + maxY) / 2;

    // 获取屏幕尺寸（估算）
    final screenWidth = 400.0; // 估算屏幕宽度
    final screenHeight = 600.0; // 估算屏幕高度

    // 计算合适的缩放比例，增加一些缩放以适应更紧凑的布局
    final scaleX = screenWidth / width;
    final scaleY = screenHeight / height;
    final newScale = Math.min(scaleX, scaleY) * 0.9; // 从0.8增加到0.9，减少边距

    // 限制缩放范围，允许更小的缩放以适应更多节点
    _scale = newScale.clamp(0.3, 2.0); // 从0.5减小到0.3，允许更小的缩放

    // 移动画布使所有节点居中显示
    final centerOffsetX = screenWidth / 2 - centerX * _scale;
    final centerOffsetY = screenHeight / 2 - centerY * _scale;

    // 应用偏移到所有节点
    for (var node in nodes) {
      node.position += Offset(centerOffsetX / _scale, centerOffsetY / _scale);
    }

    setState(() {
      // 触发界面更新
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('思维导图'),
        backgroundColor: AnimeTheme.primaryColor,
        foregroundColor: Colors.white,
        elevation: 5,
        shadowColor: AnimeTheme.primaryColor.withOpacity(0.5),
        actions: [
          // 添加撤回按钮
          IconButton(
            icon: const Icon(Icons.undo),
            onPressed: _historyIndex > 0 ? _undo : null, // 如果没有可撤回的操作则禁用按钮
          ),
          IconButton(
            icon: const Icon(Icons.folder_open),
            onPressed: _showSavedMindMaps,
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _newMindMap,
          ),
          // 添加保存为图片的按钮
          IconButton(
            icon: const Icon(Icons.save_alt),
            onPressed: _saveAsImage,
            tooltip: '保存为图片',
          ),
          // 添加自动排列节点的按钮（仅在树状模式下显示）
          if (!_isFreeMode)
            IconButton(
              icon: const Icon(Icons.auto_fix_high),
              onPressed: _arrangeNodesInTreeStructure,
              tooltip: '自动整理节点',
            ),
          IconButton(
            icon: Icon(_isFreeMode ? Icons.account_tree : Icons.open_with),
            onPressed: _toggleMode,
            tooltip: _isFreeMode ? '切换到树状结构模式' : '切换到自由拖动模式',
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/dalian_bridge.jpg'),
            fit: BoxFit.cover,
          ),
        ),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 2.0, sigmaY: 2.0),
          child: Container(
            color: AnimeTheme.backgroundColor.withOpacity(0.7),
            child: Stack(
              children: [
                // 缩放和移动的思维导图画布
                Transform.scale(
                  scale: _scale,
                  child: CustomPaint(
                    painter: MindMapPainter(
                      nodes: nodes,
                      connections: connections,
                      selectedNode: _selectedNode,
                      isTreeMode: !_isFreeMode,
                      forceRepaint: _forceRepaint, // 传递强制重绘参数
                    ),
                    size: Size.infinite,
                  ),
                ),
                // 全屏操作层，用于处理所有手势
                Positioned.fill(
                  child: GestureDetector(
                    onScaleStart: _handleScaleStart,
                    onScaleUpdate: _handleScaleUpdate,
                    child: Stack(
                      children: [
                        // 透明覆盖层，捕获手势
                        Container(
                          color: Colors.transparent,
                        ),
                        // 节点操作区域
                        for (var node in nodes)
                          Positioned(
                            left: node.position.dx - (node.isRoot ? 90.0 : 75.0),
                            top: node.position.dy - (node.isRoot ? 90.0 : 75.0),
                            width: (node.isRoot ? 180.0 : 150.0),
                            height: (node.isRoot ? 180.0 : 150.0),
                            child: GestureDetector(
                              onTap: () => _handleNodeTap(node),
                              onDoubleTap: () => _handleNodeDoubleTap(node),
                              onLongPress: () => _handleNodeLongPress(node),
                              onPanStart: (details) =>
                                  _handleNodeDragStart(node, details),
                              onPanUpdate: _handleNodeDragUpdate,
                              onPanEnd: _handleNodeDragEnd,
                              child: Container(
                                color: Colors.transparent,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: AnimeTheme.primaryColor.withOpacity(0.5),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: FloatingActionButton(
          onPressed: _selectedNode != null ? _addNode : null,
          backgroundColor: AnimeTheme.primaryColor,
          foregroundColor: Colors.white,
          shape: const CircleBorder(
            side: BorderSide(
              color: AnimeTheme.secondaryColor,
              width: 2,
            ),
          ),
          child: const Icon(
            Icons.add,
            size: 30,
          ),
        ),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AnimeTheme.cardColor.withOpacity(0.8),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(25),
            topRight: Radius.circular(25),
          ),
          border: Border.all(
            color: AnimeTheme.primaryColor.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            IconButton(
              icon: const Icon(
                Icons.edit,
                color: AnimeTheme.primaryColor,
              ),
              onPressed: _selectedNode != null ? _editNodeText : null,
            ),
            IconButton(
              icon: const Icon(
                Icons.delete,
                color: AnimeTheme.accentColor,
              ),
              onPressed: _selectedNode != null && !_selectedNode!.isRoot
                  ? _deleteNode
                  : null,
            ),
            IconButton(
              icon: const Icon(
                Icons.save,
                color: AnimeTheme.secondaryColor,
              ),
              onPressed: _saveMindMap,
            ),
          ],
        ),
      ),
    );
  }

  // 保存当前状态到历史记录
  void _saveToHistory() {
    // 创建当前状态的深拷贝
    final nodesCopy = nodes.map((node) => MindNode(
          id: node.id,
          text: node.text,
          position: node.position,
          isRoot: node.isRoot,
        )).toList();
        
    final connectionsCopy = connections.map((conn) => MindConnection(
          from: conn.from,
          to: conn.to,
        )).toList();
    
    final state = {
      'nodes': nodesCopy,
      'connections': connectionsCopy,
      'selectedNodeId': _selectedNode?.id,
    };
    
    // 如果当前不是在历史记录的最新位置，删除之后的历史记录
    if (_historyIndex < _history.length - 1) {
      _history = _history.sublist(0, _historyIndex + 1);
    }
    
    _history.add(state);
    _historyIndex = _history.length - 1;
  }
  
  // 撤回操作
  void _undo() {
    if (_historyIndex > 0) {
      _historyIndex--;
      _restoreFromHistory(_history[_historyIndex]);
    }
  }
  
  // 恢复到指定历史状态
  void _restoreFromHistory(Map<String, dynamic> state) {
    setState(() {
      nodes = List<MindNode>.from(state['nodes']);
      connections = List<MindConnection>.from(state['connections']);
      
      // 恢复选中节点
      final selectedNodeId = state['selectedNodeId'];
      if (selectedNodeId != null) {
        try {
          _selectedNode = nodes.firstWhere((node) => node.id == selectedNodeId);
        } catch (e) {
          _selectedNode = null;
        }
      } else {
        _selectedNode = null;
      }
    });
  }
  
  // 重做操作（如果需要的话）
  void _redo() {
    if (_historyIndex < _history.length - 1) {
      _historyIndex++;
      _restoreFromHistory(_history[_historyIndex]);
    }
  }
  
  // 保存为图片功能
  void _saveAsImage() async {
    try {
      // 计算所有节点的边界以确定图片大小
      double minX = double.infinity;
      double minY = double.infinity;
      double maxX = double.negativeInfinity;
      double maxY = double.negativeInfinity;

      for (var node in nodes) {
        final isRoot = node.isRoot;
        final radius = isRoot ? 60.0 : 50.0;

        minX = Math.min(minX, node.position.dx - radius);
        minY = Math.min(minY, node.position.dy - radius);
        maxX = Math.max(maxX, node.position.dx + radius);
        maxY = Math.max(maxY, node.position.dy + radius);
      }

      // 添加边距
      const margin = 50.0;
      minX -= margin;
      minY -= margin;
      maxX += margin;
      maxY += margin;
      
      final width = maxX - minX;
      final height = maxY - minY;
      
      // 创建自定义画布并绘制思维导图
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      
      // 绘制背景
      final backgroundPaint = Paint()..color = AnimeTheme.backgroundColor;
      canvas.drawRect(Rect.fromLTWH(0, 0, width, height), backgroundPaint);
      
      // 调整节点位置以便绘制
      final adjustedNodes = nodes.map((node) {
        return MindNode(
          id: node.id,
          text: node.text,
          position: Offset(node.position.dx - minX, node.position.dy - minY),
          isRoot: node.isRoot,
        );
      }).toList();
      
      // 创建临时画笔用于绘制
      final painter = MindMapPainter(
        nodes: adjustedNodes,
        connections: connections,
        selectedNode: null,
        isTreeMode: !_isFreeMode,
        forceRepaint: false,
      );
      
      // 绘制思维导图
      painter.paint(canvas, Size(width, height));
      
      // 结束绘制并生成图片
      final picture = recorder.endRecording();
      final image = await picture.toImage(width.toInt(), height.toInt());
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      final pngBytes = byteData!.buffer.asUint8List();
      
      // 使用share_plus插件分享图片
      final directory = await getTemporaryDirectory();
      final fileName = 'mind_map_${DateTime.now().millisecondsSinceEpoch}.png';
      final filePath = '${directory.path}/$fileName';
      
      final file = File(filePath);
      await file.writeAsBytes(pngBytes);
      
      // 分享图片
      await Share.shareXFiles(
        [XFile(filePath)],
        text: '我的思维导图',
      );
    } catch (e) {
      if (context.mounted) {
        // 显示错误提示
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('分享图片失败: $e'),
            backgroundColor: AnimeTheme.accentColor,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }
}

class MindMapPainter extends CustomPainter {
  final List<MindNode> nodes;
  final List<MindConnection> connections;
  final MindNode? selectedNode;
  final bool isTreeMode;
  final bool forceRepaint; // 添加强制重绘参数

  MindMapPainter({
    required this.nodes,
    required this.connections,
    required this.selectedNode,
    required this.isTreeMode,
    this.forceRepaint = false, // 添加强制重绘参数默认值
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    // 绘制连接线
    for (var connection in connections) {
      try {
        final fromNode = nodes.firstWhere((node) => node.id == connection.from);
        final toNode = nodes.firstWhere((node) => node.id == connection.to);

        paint.color = AnimeTheme.primaryColor.withOpacity(0.6);

        if (isTreeMode) {
          // 在树状模式下绘制直线连接
          canvas.drawLine(
            fromNode.position,
            toNode.position,
            paint,
          );
        } else {
          // 在自由模式下绘制贝塞尔曲线连接
          final path = Path();
          path.moveTo(fromNode.position.dx, fromNode.position.dy);

          // 计算控制点，使连线更美观
          final controlPointX = (fromNode.position.dx + toNode.position.dx) / 2;
          final controlPointY =
              (fromNode.position.dy + toNode.position.dy) / 2 - 30;

          path.quadraticBezierTo(
            controlPointX,
            controlPointY,
            toNode.position.dx,
            toNode.position.dy,
          );

          canvas.drawPath(path, paint);
        }
      } catch (e) {
        // 跳过无法找到节点的连接
        continue;
      }
    }

    // 绘制节点
    for (var node in nodes) {
      final isRoot = node.isRoot;
      final isSelected = selectedNode?.id == node.id;
      final radius = isRoot ? 60.0 : 50.0;
      final rect = Rect.fromCenter(
        center: node.position,
        width: radius * 2,
        height: radius * 1.2, // 矩形高度稍小于宽度，看起来更协调
      );

      // 节点阴影
      final shadowPaint = Paint()
        ..color = Colors.black.withOpacity(0.3)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5.0);

      final shadowRect = Rect.fromCenter(
        center: Offset(node.position.dx + 2.0, node.position.dy + 2.0),
        width: radius * 2,
        height: radius * 1.2,
      );

      canvas.drawRRect(
        RRect.fromRectAndRadius(shadowRect, const Radius.circular(10.0)),
        shadowPaint,
      );

      // 节点背景
      final backgroundPaint = Paint()
        ..color = isSelected
            ? AnimeTheme.primaryColor.withOpacity(0.9)
            : AnimeTheme.cardColor.withOpacity(0.9)
        ..style = PaintingStyle.fill;

      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(10.0)),
        backgroundPaint,
      );

      // 节点边框
      final borderPaint = Paint()
        ..color = isSelected
            ? AnimeTheme.secondaryColor
            : AnimeTheme.primaryColor.withOpacity(0.5)
        ..strokeWidth = isSelected ? 4.0 : 2.0
        ..style = PaintingStyle.stroke;

      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(10.0)),
        borderPaint,
      );

      // 绘制文本
      final textPainter = TextPainter(
        text: TextSpan(
          text: node.text,
          style: TextStyle(
            color: isSelected ? Colors.white : AnimeTheme.textColor,
            fontSize: isRoot ? 16.0 : 14.0,
            fontWeight: isRoot ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr,
      );

      textPainter.layout();

      textPainter.paint(
        canvas,
        Offset(
          node.position.dx - textPainter.width / 2,
          node.position.dy - textPainter.height / 2,
        ),
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    // 优化重绘条件，只有当数据发生变化时才重绘
    if (oldDelegate is MindMapPainter) {
      return nodes != oldDelegate.nodes ||
          connections != oldDelegate.connections ||
          selectedNode != oldDelegate.selectedNode ||
          isTreeMode != oldDelegate.isTreeMode ||
          // 添加强制重绘条件，用于节点拖拽时的流畅更新
          forceRepaint != oldDelegate.forceRepaint;
    }
    return true;
  }
}
