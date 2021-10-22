import 'dart:async';
import 'dart:math';

import 'package:editor/flutter_quill.dart';
import 'package:flowy_infra/image.dart';
import 'package:flutter/material.dart';
import 'check_button.dart';
import 'image_button.dart';
import 'link_button.dart';
import 'toggle_button.dart';

class EditorToolbar extends StatelessWidget implements PreferredSizeWidget {
  final List<Widget> children;
  final double toolBarHeight;
  final Color? color;

  const EditorToolbar({
    required this.children,
    this.toolBarHeight = 36,
    this.color,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).canvasColor,
      constraints: BoxConstraints.tightFor(height: preferredSize.height),
      child: ToolbarButtonList(buttons: children),
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(toolBarHeight);

  factory EditorToolbar.basic({
    required QuillController controller,
    double toolbarIconSize = kDefaultIconSize,
    OnImagePickCallback? onImagePickCallback,
    OnVideoPickCallback? onVideoPickCallback,
    MediaPickSettingSelector? mediaPickSettingSelector,
    FilePickImpl? filePickImpl,
    WebImagePickImpl? webImagePickImpl,
    WebVideoPickImpl? webVideoPickImpl,
    Key? key,
  }) {
    return EditorToolbar(
      key: key,
      toolBarHeight: toolbarIconSize * 2,
      children: [
        HistoryButton(
          icon: Icons.undo_outlined,
          iconSize: toolbarIconSize,
          controller: controller,
          undo: true,
        ),
        HistoryButton(
          icon: Icons.redo_outlined,
          iconSize: toolbarIconSize,
          controller: controller,
          undo: false,
        ),
        FlowyToggleStyleButton(
          attribute: Attribute.bold,
          icon: svg('editor/bold'),
          iconSize: toolbarIconSize,
          controller: controller,
        ),
        FlowyToggleStyleButton(
          attribute: Attribute.italic,
          icon: svg("editor/restore"),
          iconSize: toolbarIconSize,
          controller: controller,
        ),
        FlowyToggleStyleButton(
          attribute: Attribute.underline,
          icon: svg('editor/underline'),
          iconSize: toolbarIconSize,
          controller: controller,
        ),
        FlowyToggleStyleButton(
          attribute: Attribute.strikeThrough,
          icon: svg('editor/strikethrough'),
          iconSize: toolbarIconSize,
          controller: controller,
        ),
        ColorButton(
          icon: Icons.format_color_fill,
          iconSize: toolbarIconSize,
          controller: controller,
          background: true,
        ),
        FlowyImageButton(
          iconSize: toolbarIconSize,
          controller: controller,
          onImagePickCallback: onImagePickCallback,
          filePickImpl: filePickImpl,
          webImagePickImpl: webImagePickImpl,
          mediaPickSettingSelector: mediaPickSettingSelector,
        ),
        SelectHeaderStyleButton(
          controller: controller,
          iconSize: toolbarIconSize,
        ),
        FlowyToggleStyleButton(
          attribute: Attribute.ol,
          controller: controller,
          icon: svg('editor/numbers'),
          iconSize: toolbarIconSize,
        ),
        FlowyToggleStyleButton(
          attribute: Attribute.ul,
          controller: controller,
          icon: svg('editor/bullet_list'),
          iconSize: toolbarIconSize,
        ),
        FlowyCheckListButton(
          attribute: Attribute.unchecked,
          controller: controller,
          iconSize: toolbarIconSize,
        ),
        FlowyToggleStyleButton(
          attribute: Attribute.inlineCode,
          controller: controller,
          icon: svg('editor/inline_block'),
          iconSize: toolbarIconSize,
        ),
        FlowyToggleStyleButton(
          attribute: Attribute.blockQuote,
          controller: controller,
          icon: svg('editor/quote'),
          iconSize: toolbarIconSize,
        ),
        FlowyToggleStyleButton(
          attribute: Attribute.blockQuote,
          controller: controller,
          icon: svg('editor/quote'),
          iconSize: toolbarIconSize,
        ),
        FlowyToggleStyleButton(
          attribute: Attribute.blockQuote,
          controller: controller,
          icon: svg('editor/quote'),
          iconSize: toolbarIconSize,
        ),
        FlowyToggleStyleButton(
          attribute: Attribute.blockQuote,
          controller: controller,
          icon: svg('editor/quote'),
          iconSize: toolbarIconSize,
        ),
        FlowyLinkStyleButton(
          controller: controller,
          iconSize: toolbarIconSize,
        ),
      ],
    );
  }
}

class ToolbarButtonList extends StatefulWidget {
  const ToolbarButtonList({required this.buttons, Key? key}) : super(key: key);

  final List<Widget> buttons;

  @override
  _ToolbarButtonListState createState() => _ToolbarButtonListState();
}

class _ToolbarButtonListState extends State<ToolbarButtonList> with WidgetsBindingObserver {
  final ScrollController _controller = ScrollController();
  bool _showLeftArrow = false;
  bool _showRightArrow = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_handleScroll);

    // Listening to the WidgetsBinding instance is necessary so that we can
    // hide the arrows when the window gets a new size and thus the toolbar
    // becomes scrollable/unscrollable.
    WidgetsBinding.instance!.addObserver(this);

    // Workaround to allow the scroll controller attach to our ListView so that
    // we can detect if overflow arrows need to be shown on init.
    Timer.run(_handleScroll);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        return SizedBox(
          width: min(constraints.maxWidth, (widget.buttons.length + 3) * kDefaultIconSize * kIconButtonFactor + 16),
          child: Row(
            children: <Widget>[
              _buildLeftArrow(),
              _buildScrollableList(constraints),
              _buildRightColor(),
            ],
          ),
        );
      },
    );
  }

  @override
  void didChangeMetrics() => _handleScroll();

  @override
  void dispose() {
    _controller.dispose();
    WidgetsBinding.instance!.removeObserver(this);
    super.dispose();
  }

  void _handleScroll() {
    if (!mounted) return;
    setState(() {
      _showLeftArrow = _controller.position.minScrollExtent != _controller.position.pixels;
      _showRightArrow = _controller.position.maxScrollExtent != _controller.position.pixels;
    });
  }

  Widget _buildLeftArrow() {
    return SizedBox(
      width: 8,
      child: Transform.translate(
        // Move the icon a few pixels to center it
        offset: const Offset(-5, 0),
        child: _showLeftArrow ? const Icon(Icons.arrow_left, size: 18) : null,
      ),
    );
  }

  Widget _buildScrollableList(BoxConstraints constraints) {
    return ScrollConfiguration(
      // Remove the glowing effect, as we already have the arrow indicators
      behavior: _NoGlowBehavior(),
      // The CustomScrollView is necessary so that the children are not
      // stretched to the height of the toolbar, https://bit.ly/3uC3bjI
      child: Expanded(
        child: CustomScrollView(
          scrollDirection: Axis.horizontal,
          controller: _controller,
          physics: const ClampingScrollPhysics(),
          slivers: [
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (BuildContext context, int index) {
                  return widget.buttons[index];
                },
                childCount: widget.buttons.length,
                addAutomaticKeepAlives: false,
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildRightColor() {
    return SizedBox(
      width: 8,
      child: Transform.translate(
        // Move the icon a few pixels to center it
        offset: const Offset(-5, 0),
        child: _showRightArrow ? const Icon(Icons.arrow_right, size: 18) : null,
      ),
    );
  }
}

/// ScrollBehavior without the Material glow effect.
class _NoGlowBehavior extends ScrollBehavior {
  @override
  Widget buildViewportChrome(BuildContext _, Widget child, AxisDirection __) {
    return child;
  }
}
