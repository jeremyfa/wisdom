package markup;

import haxe.Json;

using StringTools;

class MarkupToVDomError {

    public var pos:Int;

    public var message:String;

    public function new(pos:Int, message:String) {
        this.pos = pos;
        this.message = message;
    }

}

class MarkupToVDom {

    static final RESERVED_KEYWORDS:Map<String,Bool> = [
        "abstract" => true,
        "break" => true,
        "case" => true,
        "cast" => true,
        "catch" => true,
        "class" => true,
        "continue" => true,
        "default" => true,
        "do" => true,
        "dynamic" => true,
        "else" => true,
        "enum" => true,
        "extends" => true,
        "extern" => true,
        "false" => true,
        "final" => true,
        "for" => true,
        "function" => true,
        "if" => true,
        "implements" => true,
        "import" => true,
        "in" => true,
        "inline" => true,
        "interface" => true,
        "macro" => true,
        "new" => true,
        "null" => true,
        "operator" => true,
        "overload" => true,
        "override" => true,
        "package" => true,
        "private" => true,
        "public" => true,
        "return" => true,
        "static" => true,
        "super" => true,
        "switch" => true,
        "this" => true,
        "throw" => true,
        "true" => true,
        "try" => true,
        "typedef" => true,
        "untyped" => true,
        "using" => true,
        "var" => true,
        "while" => true
    ];

    static final RE_TAG_OPEN = ~/^<([a-zA-Z_][a-zA-Z_0-9]*)/;

    static final RE_TAG_CLOSE = ~/^<\/([a-zA-Z_][a-zA-Z_0-9]*)>/;

    static final RE_ATTR_START = ~/^([a-zA-Z_])/;

    static final RE_IDENTIFIER = ~/^([a-zA-Z_][a-zA-Z_0-9]*)/;

    static final RE_NUMBER = ~/^([0-9]+)$/;

    static final RE_ATTR = ~/^([a-zA-Z_][a-zA-Z_0-9\-]*)(?:\s*( |=)\s*("|\$))?/;

    var i:Int = 0;

    var iOffset:Int = 0;

    var input:String = null;

    var output:StringBuf = null;

    var numNodes:Int = 0;

    var numTags:Int = 0;

    var tagStack:Array<String> = null;

    var tagTernaryStack:Array<Int> = null;

    var parseUntil:Int = -1;

    var currentPath:Array<String> = null;

    var numIter:Int = 0;

    public var componentTagPos(default, null):Array<Int> = null;

    public function new() {}

    public function convert(input:String, i:Int = 0, iOffset:Int = 0, ?componentTagPos:Array<Int>, parseUntil:Int = -1, ?currentPath:Array<String>, numIter:Int = 0):String {

        this.input = input;
        this.output = new StringBuf();
        this.numNodes = 0;
        this.i = i;
        this.iOffset = iOffset;
        this.componentTagPos = componentTagPos ?? [];
        this.tagStack = [];
        this.tagTernaryStack = [];
        this.parseUntil = parseUntil;
        this.currentPath = currentPath ?? [];
        this.numIter = numIter;

        parse();

        return output.toString();

    }

    function parse() {

        while (i < input.length) {

            var c = input.charCodeAt(i);

            if (c == '<'.code) {
                var c1 = input.charCodeAt(i + 1);
                if (c1 == '!'.code) {
                    if (input.substr(i, 4) == '<!--') {
                        var commentI = i;
                        i += 4;
                        c = input.charCodeAt(i);
                        while (i < input.length && c != '-'.code && input.substr(i, 3) != '-->') {
                            i++;
                        }
                        if (i < input.length && input.substr(i, 3) == '-->') {
                            i += 3;
                        }
                        else {
                            throw new MarkupToVDomError(commentI + iOffset, "Unterminated comment (parse)");
                        }

                    }
                    else {
                        throw new MarkupToVDomError(i + iOffset, "Unexpected '" + String.fromCharCode(c) + "' (parse)");
                    }
                }
                else if (c1 != '/'.code) {
                    var autoClosing = parseTagOpen();
                    if (!autoClosing) {
                        numTags++;
                        var markup2vdom = new MarkupToVDom();
                        var content = markup2vdom.convert(input, i, iOffset, componentTagPos, -1, currentPath, numIter);
                        i = markup2vdom.i;
                        numIter = markup2vdom.numIter;
                        iOffset = markup2vdom.iOffset;
                        if (content.trim().length > 0) {
                            output.addChar(','.code);
							output.addChar(' '.code);
                            if (markup2vdom.numNodes > 1) {
                                output.addChar('['.code);
                            }
                            output.add(content);
                            if (markup2vdom.numNodes > 1) {
                                output.addChar(']'.code);
							}
                        }
                    }
                }
                else {
                    numTags--;
                    if (numTags < 0) {
                        return;
                    }
                    parseTagClose();
                }
            }
            else {
                var prevI = i;
                parseText();
                if (numTags == 0 && parseUntil != -1 && parseUntil == input.charCodeAt(i)) {
                    // End of string
                    return;
                }
                if (i == prevI) {
                    throw new MarkupToVDomError(i + iOffset, "Unexpected '" + String.fromCharCode(c) + "' (parse)");
                }
            }

        }

    }

    function parseText():Bool {

        var text:StringBuf = null;

        inline function add(char:Int) {
            if (text == null) text = new StringBuf();
            text.addChar(char);
        }

        while (i < input.length) {

            var c = input.charCodeAt(i);

            if (text != null || !input.isSpace(i)) {
                if (c == '\\'.code) {
                    iOffset++;
                    i++;
                    c = input.charCodeAt(i);
                    add(c);
                }
                else if (numTags == 0 && parseUntil != -1 && parseUntil == c) {
                    return false;
                }
                else if (c == "'".code) {
                    throw new MarkupToVDomError(i + iOffset, "Unexpected '" + String.fromCharCode(c) + "' (parseText)");
                }
                else if (c == "$".code) {
                    i++;
                    var c1 = input.charCodeAt(i);
                    if (c1 == "$".code) {

                    }
                    else {
                        add("'".code);
                        add("+".code);
                        text.add(parseDollarValue());
                        add("+".code);
                        add("'".code);
                    }
                }
                else if (c == '<'.code) {
                    if (text != null) {
                        var resultText = text.toString().trim();
                        if (resultText.length > 0) {

                            if (numNodes++ > 0) {
                                output.add(", ");
                            }

                            if (resultText.startsWith("'+")) {
                                resultText = resultText.substr(2);
                            }
                            else {
                                output.addChar("'".code);
                            }

                            if (resultText.endsWith("+'")) {
                                resultText = resultText.substring(0, resultText.length - 2);
                                output.add(resultText);
                            }
                            else {
                                output.add(resultText);
                                output.addChar("'".code);
                            }

                            return true;
                        }
                        else {
                            return false;
                        }
                    }
                    else {
                        return false;
                    }
                }
                else if (c == '>'.code) {
                    throw new MarkupToVDomError(i + iOffset, "Unexpected '" + String.fromCharCode(c) + "' (parseText)");
                }
                else {
                    add(c);
                    i++;
                }
            }
            else {
                i++;
            }

        }

        return false;

    }

    function parseTagOpen():Bool {

        if (!RE_TAG_OPEN.match(input.substr(i))) {
            throw new MarkupToVDomError(i + iOffset, "Unexpected '<' (parseTagOpen)");
        }

        final tag = RE_TAG_OPEN.matched(1);
        final isComponent = tag.charAt(0).toLowerCase() != tag.charAt(0);

        tagStack.push(tag);
        tagTernaryStack.push(0);

        var isFor = false;
        var forToIterate = null;
        var forItem = null;

        var isKey = false;
        var keyExpr = null;

        if (tag == 'key') {
            isKey = true;
        }

        if (numNodes++ > 0) {
            output.add(", ");
        }

        var prevOutput = output;
        output = new StringBuf();

        if (tag == 'foreach') {
            output.add("{markup_.Markup.iPush(); final foreach_ = [for (iter_ in ");
            isFor = true;
        }

        i += RE_TAG_OPEN.matched(0).length;

        var attrKeys:Array<String> = null;
        var attrValues:Array<Any> = null;

        while (i < input.length) {

            var c = input.charAt(i);

            if (isFor) {

                if (c.isSpace(0)) {
                    i++;
                }
                else if (c == "$") {
                    if (forToIterate == null) {
                        i++;
                        forToIterate = parseDollarValue();
                        output.add(forToIterate);
                        output.add(") (");
                    }
                    else if (forItem == null) {
                        i++;
                        numIter++;

                        currentPath.push(Std.string(numNodes));
                        currentPath.push('markup_.Markup.iStr('+(numIter-1)+')');

                        final prevNumNodes = numNodes;
                        numNodes = 0;
                        forItem = parseDollarValue();
                        numNodes = prevNumNodes;

                        currentPath.pop();
                        currentPath.pop();

                        numIter--;
                        output.add(forItem);
                        output.add(")(markup_.Markup.iIter(), iter_)]; markup_.Markup.iPop(); foreach_; }");
                    }
                    else {
                        throw new MarkupToVDomError(i + iOffset, "Unexpected '" + c + "' in <foreach ... /> (parseTagOpen)");
                    }
                }
                else if (forToIterate != null && forItem != null && (c.charCodeAt(0) == '/'.code && input.charCodeAt(i+1) == '>'.code)) {
                    i += 2;

					var tagOutput = output;
                    output = prevOutput;
                    output.add(tagOutput.toString());

                    return true;
                }
                else {
                    throw new MarkupToVDomError(i + iOffset, "Unexpected '" + c + "' in <foreach ... /> (parseTagOpen)");
                }
            }
            else if (isKey) {

                if (c.isSpace(0)) {
                    i++;
                }
                else if (c == "$") {
                    if (keyExpr == null) {
                        i++;
                        keyExpr = parseDollarValue();
                        output.add('{markup_.Markup.iKey(' + keyExpr + '); null;}');
                    }
                    else {
                        throw new MarkupToVDomError(i + iOffset, "Unexpected '" + c + "' in <key ... /> (parseTagOpen)");
                    }
                }
                else if (keyExpr != null && (c.charCodeAt(0) == '/'.code && input.charCodeAt(i+1) == '>'.code)) {
                    i += 2;

					var tagOutput = output;
                    output = prevOutput;
                    output.add(tagOutput.toString());

                    return true;
                }
                else {
                    throw new MarkupToVDomError(i + iOffset, "Unexpected '" + c + "' in <foreach ... /> (parseTagOpen)");
                }
            }
            else if (RE_ATTR_START.match(c)) {
                if (!RE_ATTR.match(input.substr(i))) {
                    throw new MarkupToVDomError(i + iOffset, "Unexpected '" + c + "' (parseTagOpen)");
                }

                final attr = RE_ATTR.matched(1);

                if (attrKeys == null) {
                    attrKeys = [];
                    attrValues = [];
                }

                final isControlAttr = (attr == 'if' || attr == 'unless');

                if (!isControlAttr && attrKeys.contains(attr)) {
                    throw new MarkupToVDomError(i + iOffset, "Duplicate attribute: '" + attr + "'");
                }

                // if (isControlAttr && RE_ATTR.matched(2) == '=') {
                //     throw new MarkupToVDomError(i + iOffset + attr.length, "Unexpected '='");
                // }
                // else if (!isControlAttr && RE_ATTR.matched(2) == ' ') {
                //     throw new MarkupToVDomError(i + iOffset + attr.length, "Unexpected ' '");
                // }

                if (RE_ATTR.matched(2).trim() == '') {
                    throw new MarkupToVDomError(i + iOffset + attr.length, "Unexpected ' '");
                }

                attrKeys.push(attr);

                i += RE_ATTR.matched(0).length;

                var assignStart = RE_ATTR.matched(3);
                if (assignStart == '"') {
                    i--;
                    attrValues.push(parseAttrStrValue());
                }
                else if (assignStart == "$") {
                    attrValues.push(parseDollarValue());
                }
                else {
                    attrValues.push(attr);
                }
            }
            else if ((c.charCodeAt(0) == '/'.code && input.charCodeAt(i+1) == '>'.code) || c.charCodeAt(0) == '>'.code) {

                var keyIndex = attrKeys != null ? attrKeys.indexOf('key') : -1;
                var xidExpr = (keyIndex != -1 ? attrValues[keyIndex] : Std.string(numNodes));

                currentPath.push(xidExpr);

                if (isComponent) {
                    componentTagPos.push(i);
                    output.add("markup_.Markup.c(");
                    output.add(serializePath(currentPath));
                    output.addChar(",".code);
                    output.addChar(" ".code);
                    var realTag = getRealTag(tag);
                    output.add(realTag);
                }
                else {
                    output.add("markup_.Markup.h(");
                    output.add(serializePath(currentPath));
                    output.addChar(",".code);
                    output.addChar(" ".code);
                    output.addChar("'".code);
                    output.add(tag);
                    output.add("'");
                }

                // End of tag open
                i++;
                var ifConditions = null;
                var unlessConditions = null;
                if (attrKeys != null && attrKeys.length > 0) {
                    output.add(', markup_.Markup.v({ ');
                    var propsOutput:StringBuf = null;
                    var onOutput:StringBuf = null;
                    var isPropsTopLevel = attrKeys.contains('props');
                    var isOnTopLevel = attrKeys.contains('on');
                    var outputEmpty = true;
                    for (n in 0...attrKeys.length) {
                        final key = attrKeys[n];
                        final value = attrValues[n];
                        var topLevelKey = getTopLevelKey(key);
                        if (topLevelKey != null) {
                            if (!outputEmpty) {
                                output.addChar(','.code);
                                output.addChar(' '.code);
                            }
                            else {
                                outputEmpty = false;
                            }
                            output.add(topLevelKey);
                            output.addChar(':'.code);
                            output.addChar(' '.code);
                            output.add(value);
                        }
                        else if (key == 'if') {
                            if (ifConditions == null) ifConditions = [];
                            ifConditions.push(value);
                        }
                        else if (key == 'unless') {
                            if (unlessConditions == null) unlessConditions = [];
                            unlessConditions.push(value);
                        }
                        else if (key.startsWith('on')) {
                            final eventKey = key.substr(2);
                            if (isOnTopLevel) {
                                throw new MarkupToVDomError(-1, 'Cannot have both top level "on" attribute and separate "on*" attributes');
                            }
                            if (onOutput == null) {
                                onOutput = new StringBuf();
                                onOutput.addChar('{'.code);
                                onOutput.addChar(' '.code);
                            }
                            else {
                                onOutput.addChar(','.code);
                                onOutput.addChar(' '.code);
                            }
                            if (shouldEscapeKey(eventKey)) {
                                onOutput.addChar('"'.code);
                                onOutput.add(eventKey);
                                onOutput.addChar('"'.code);
                            }
                            else {
                                onOutput.add(eventKey);
                            }
                            onOutput.addChar(':'.code);
                            onOutput.addChar(' '.code);
                            onOutput.add(value);
                        }
                        else {
                            if (isPropsTopLevel) {
                                throw new MarkupToVDomError(-1, 'Cannot have both top level "props" attribute and separate attributes');
                            }
                            if (propsOutput == null) {
                                propsOutput = new StringBuf();
                                propsOutput.addChar('{'.code);
                                propsOutput.addChar(' '.code);
                            }
                            else {
                                propsOutput.addChar(','.code);
                                propsOutput.addChar(' '.code);
                            }
                            if (shouldEscapeKey(key)) {
                                propsOutput.addChar('"'.code);
                                propsOutput.add(key);
                                propsOutput.addChar('"'.code);
                            }
                            else {
                                propsOutput.add(key);
                            }
                            propsOutput.addChar(':'.code);
                            propsOutput.addChar(' '.code);
                            propsOutput.add(value);
                        }
                    }
                    if (propsOutput != null) {
                        if (!outputEmpty) {
                            output.addChar(','.code);
                            output.addChar(' '.code);
                        }
                        else {
                            outputEmpty = false;
                        }
                        output.add('props: ');
                        propsOutput.addChar(' '.code);
                        propsOutput.addChar('}'.code);
                        output.add(propsOutput.toString());
                    }
                    if (onOutput != null) {
                        if (!outputEmpty) {
                            output.addChar(','.code);
                            output.addChar(' '.code);
                        }
                        else {
                            outputEmpty = false;
                        }
                        output.add('on: ');
                        onOutput.addChar(' '.code);
                        onOutput.addChar('}'.code);
                        output.add(onOutput.toString());
                    }
                    output.add('})');
                }
                var autoClosing = c.charCodeAt(0) == '/'.code;
                if (autoClosing) {
                    tagStack.pop();
                    i++;
                    output.addChar(')'.code);
                    final numTernaryClose = tagTernaryStack.pop();
                    for (_ in 0...numTernaryClose) {
                        output.addChar(' '.code);
                        output.addChar(':'.code);
                        output.addChar(' '.code);
                        output.addChar('n'.code);
                        output.addChar('u'.code);
                        output.addChar('l'.code);
                        output.addChar('l'.code);
                        output.addChar(')'.code);
                    }
                }

                var tagOutput = output;
                output = prevOutput;

                if (ifConditions != null) {
                    for (cond in ifConditions) {
                        tagTernaryStack[tagTernaryStack.length - 1] = tagTernaryStack[tagTernaryStack.length - 1] + 1;
                        output.addChar('('.code);
                        output.addChar('('.code);
                        output.add(cond);
                        output.addChar(')'.code);
                        output.addChar(' '.code);
                        output.addChar('?'.code);
                        output.addChar(' '.code);
                    }
                }

                if (unlessConditions != null) {
                    for (cond in unlessConditions) {
                        tagTernaryStack[tagTernaryStack.length - 1] = tagTernaryStack[tagTernaryStack.length - 1] + 1;
                        output.addChar('('.code);
                        output.addChar('!'.code);
                        output.addChar('('.code);
                        output.add(cond);
                        output.addChar(')'.code);
                        output.addChar(' '.code);
                        output.addChar('?'.code);
                        output.addChar(' '.code);
                    }
                }

                output.add(tagOutput.toString());

                if (autoClosing) {
                    currentPath.pop();
                }

                return autoClosing;
            }
            else if (c.isSpace(0)) {
                i++;
            }
            else {
                throw new MarkupToVDomError(i + iOffset, "Unexpected '" + c + "' (parseTagOpen)");
            }

        }

        throw new MarkupToVDomError(-1, "Unexpected end of tag open");
        return false;

    }

    function serializePath(currentPath:Array<String>):String {

        var result = new StringBuf();
        result.addChar('"'.code);

        for (item in currentPath) {
            if (RE_NUMBER.match(item)) {
                result.addChar('/'.code);
                result.add(item);
            }
            else {
                result.addChar('/'.code);
                result.addChar('"'.code);
                result.addChar('+'.code);
                result.add(item);
                result.addChar('+'.code);
                result.addChar('"'.code);
            }
        }

        result.addChar('"'.code);
        var str = result.toString();

        if (str.endsWith('+""')) {
            str = str.substring(0, str.length - 3);
        }

        return str;

    }

    function parseTagClose() {

        if (!RE_TAG_CLOSE.match(input.substr(i))) {
            throw new MarkupToVDomError(i + iOffset, "Unexpected '<' (parseTagClose)");
        }

        final tag = RE_TAG_CLOSE.matched(1);
        final isComponent = tag.charAt(0).toLowerCase() != tag.charAt(0);

        if (tagStack.length == 0) {
            throw new MarkupToVDomError(i + iOffset, "Unexpected closing tag '</" + tag + ">' (parseTagClose)");
        }
        else {
            final opened = tagStack.pop();
            if (opened != tag) {
                throw new MarkupToVDomError(i + iOffset, "Closing tag '</" + tag + ">' should be '</" + opened + ">' (parseTagClose)");
            }
        }

        output.addChar(')'.code);
        final numTernaryClose = tagTernaryStack.pop();
        for (_ in 0...numTernaryClose) {
            output.addChar(' '.code);
            output.addChar(':'.code);
            output.addChar(' '.code);
            output.addChar('n'.code);
            output.addChar('u'.code);
            output.addChar('l'.code);
            output.addChar('l'.code);
            output.addChar(')'.code);
        }
        if (isComponent) {
            componentTagPos.push(i + 1);
        }
        i += RE_TAG_CLOSE.matched(0).length;

        currentPath.pop();

    }

    function getRealTag(tag:String):String {

        return tag;

    }

    function getTopLevelKey(key:String):String {

        if (key == 'style')
            return 'style';
        if (key == 'class' || key == 'className' || key == 'classes')
            return 'classes';
        if (key == 'on')
            return 'on';
        if (key == 'props')
            return 'props';

        return null;

    }

    function shouldEscapeKey(key:String):Bool {

        if (key.indexOf('-') != -1 || RESERVED_KEYWORDS.exists(key))
            return true;

        return false;

    }

    function parseAttrStrValue() {

        var prevOutput = output;
        output = new StringBuf();
        parseDoubleQuotedString();
        var str = output.toString();
        output = prevOutput;

        return str;

    }

    function parseDollarValue() {

        var c = input.charCodeAt(i);

        if (c == '{'.code) {
            i++;
            var prevOutput = output;
            output = new StringBuf();
            parseAsIsUntil('}'.code);
            final value = output.toString();
            output = prevOutput;
            return value;
        }
        else {
            if (!RE_IDENTIFIER.match(input.substr(i))) {
                throw new MarkupToVDomError(i + iOffset, "Unexpected '" + String.fromCharCode(c) + "' (parseDollarValue)");
            }
            final value = RE_IDENTIFIER.matched(0);
            i += value.length;
            return value;
        }

    }

    function parseAsIsUntil(until:Int) {

        var openBraces:Int = 0;
        var openParens:Int = 0;
        var openBrackets:Int = 0;

        while (i < input.length) {

            var c = input.charCodeAt(i);

            if (openBraces <= 0 && openParens <= 0 && openBrackets <= 0) {
                if (c == until) {
                    i++;
                    break;
                }
            }

            if (c == '{'.code) {
                output.addChar(c);
                openBraces++;
                i++;
            }
            else if (c == '}'.code) {
                output.addChar(c);
                openBraces--;
                i++;
            }
            else if (c == '('.code) {
                output.addChar(c);
                openParens++;
                i++;
            }
            else if (c == ')'.code) {
                output.addChar(c);
                openParens--;
                i++;
            }
            else if (c == '['.code) {
                output.addChar(c);
                openBrackets++;
                i++;
            }
            else if (c == ']'.code) {
                output.addChar(c);
                openBrackets--;
                i++;
            }
            else if (c == '"'.code) {
                parseDoubleQuotedString();
            }
            else if (c == '\''.code) {
                final strStart = input.substr(i + 1, 2);
                if (strStart == "<>") {
                    var markup2vdom = new MarkupToVDom();
                    i += 3;
                    var content = markup2vdom.convert(input, i, iOffset, componentTagPos, "'".code, currentPath, numIter);
                    if (markup2vdom.numNodes > 1) {
                        output.addChar('['.code);
                    }
                    output.add(content);
                    if (markup2vdom.numNodes > 1) {
                        output.addChar(']'.code);
                    }
                    i = markup2vdom.i + 1;
                    numIter = markup2vdom.numIter;
                    iOffset = markup2vdom.iOffset;
                }
                else {
                    parseSingleQuotedString();
                }
            }
            else {
                var c1 = input.charCodeAt(i);
                output.addChar(c1);
                i++;
                if (c1 == '\\'.code) {
                    iOffset++;
                }
            }
        }

    }

    function parseDoubleQuotedString() {

        output.addChar('"'.code);
        i++; // Skip opening quote

        while (i < input.length) {

            var c = input.charCodeAt(i);

            if (c == '\\'.code) {
                // Handle escape sequences
                output.addChar(c);
                i++;
                iOffset++;
                if (i < input.length) {
                    var c1 = input.charCodeAt(i);
                    output.addChar(c1);
                    i++;
                    if (c1 == '\\'.code) {
                        iOffset++;
                    }
                }
            }
            else if (c == "$".code) {
                if (i + 1 < input.length) {
                    final c1 = input.charCodeAt(i + 1);
                    if (c1 == '{'.code) {
                        // Handle string interpolation
                        // (supported because double-quoted string wrapped into a single-quoted one)
                        output.addChar('"'.code);
                        output.addChar('+'.code);
                        output.addChar('('.code);
                        i++;
                        output.add(parseDollarValue());
                        output.addChar(')'.code);
                        output.addChar('+'.code);
                        output.addChar('"'.code);
                    }
                    else if (c1 == "$".code) {
                        // Escaped dollar
                        i += 2;
                        output.addChar("$".code);
                    }
                    else if (RE_IDENTIFIER.match(input.substr(i + 1))) {
                        final value = RE_IDENTIFIER.matched(0);
                        output.addChar('"'.code);
                        output.addChar('+'.code);
                        output.add(value);
                        output.addChar('+'.code);
                        output.addChar('"'.code);
                        i += 1 + value.length;
                    }
                    else {
                        throw new MarkupToVDomError(i + iOffset, "Unexpected '" + String.fromCharCode(c) + "' (parseDoubleQuotedString)");
                    }
                }
                else {
                    throw new MarkupToVDomError(i + iOffset, "Unexpected '" + String.fromCharCode(c) + "' (parseDoubleQuotedString)");
                }
            }
            else if (c == '"'.code) {
                // End of string
                output.addChar(c);
                i++;
                break;
            }
            else {
                output.addChar(c);
                i++;
            }
        }

    }

    function parseSingleQuotedString() {

        output.addChar('\''.code);
        i++; // Skip opening quote

        while (i < input.length) {
            var c = input.charCodeAt(i);

            if (c == '\\'.code) {
                // Handle escape sequences
                output.addChar(c);
                i++;
                iOffset++;
                if (i < input.length) {
                    var c1 = input.charCodeAt(i);
                    output.addChar(c1);
                    i++;
                    if (c1 == '\\'.code) {
                        iOffset++;
                    }
                }
            }
            else if (c == "$".code) {
                if (i + 1 < input.length) {
                    final c1 = input.charCodeAt(i + 1);
                    if (c1 == '{'.code) {
                        // Handle string interpolation
                        output.addChar(c);
                        output.addChar('{'.code);
                        i += 2;
                        parseAsIsUntil('}'.code);
                        output.addChar('}'.code);
                    }
                    else if (c1 == "$".code) {
                        // Escaped dollar
                        i += 2;
                        output.addChar("$".code);
                        output.addChar("$".code);
                    }
                    else if (RE_IDENTIFIER.match(input.substr(i + 1))) {
                        final value = RE_IDENTIFIER.matched(0);
                        output.addChar(c);
                        output.add(value);
                        i += 1 + value.length;
                    }
                    else {
                        throw new MarkupToVDomError(i + iOffset, "Unexpected '" + String.fromCharCode(c) + "' (parseSingleQuotedString)");
                    }
                }
                else {
                    throw new MarkupToVDomError(i + iOffset, "Unexpected '" + String.fromCharCode(c) + "' (parseSingleQuotedString)");
                }
            }
            else if (c == '\''.code) {
                // End of string (only if we're not inside interpolation)
                output.addChar(c);
                i++;
                break;
            }
            else {
                output.addChar(input.charCodeAt(i));
                i++;
            }
        }

    }

}
