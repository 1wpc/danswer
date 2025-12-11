import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_math_fork/flutter_math.dart';
import 'package:markdown/markdown.dart' as md;

class LatexElementBuilder extends MarkdownElementBuilder {
  @override
  Widget visitElementAfter(md.Element element, TextStyle? preferredStyle) {
    final textContent = element.textContent;
    if (textContent.isEmpty) return const SizedBox();

    final isDisplayMode = element.attributes['displayMode'] == 'true';

    try {
      final mathWidget = Math.tex(
        textContent,
        textStyle: preferredStyle,
        mathStyle: isDisplayMode ? MathStyle.display : MathStyle.text,
      );
      
      // Wrap in Stack with transparent Text to enable text selection
      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Stack(
          alignment: Alignment.center,
          children: [
            mathWidget,
            Positioned.fill(
              child: Opacity(
                opacity: 0, // Fully transparent but present in tree
                child: Text(
                  textContent,
                  style: preferredStyle?.copyWith(color: Colors.transparent),
                ),
              ),
            ),
          ],
        ),
      );
    } catch (e) {
      return Text(textContent, style: preferredStyle);
    }
  }
}

// Custom syntax to match $...$ and $$...$$
class LatexSyntax extends md.InlineSyntax {
  LatexSyntax() : super(r'(\$\$)([\s\S]*?)(\$\$)|(\$)([\s\S]*?)(\$)');

  @override
  bool onMatch(md.InlineParser parser, Match match) {
    final doubleDollar = match.group(1) == '\$\$';
    final content = doubleDollar ? match.group(2) : match.group(5);
    
    if (content == null) return false;

    md.Element el = md.Element('latex', [md.Text(content)]);
    if (doubleDollar) {
      el.attributes['displayMode'] = 'true';
    }
    parser.addNode(el);
    return true;
  }
}
