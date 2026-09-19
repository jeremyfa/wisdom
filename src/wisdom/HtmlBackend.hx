package wisdom;

import haxe.Constraints.Function;
#if wisdom_html

import js.Browser.document;

class HtmlBackend extends Backend {

    public function new() {}

    /**
     * Element properties that setProp() is allowed to write.
     *
     * Everything else in a vnode's `props` reaches the element through its
     * attribute (see PropsModule), which is what most attributes need anyway.
     * The properties listed here are the ones for which the attribute is not
     * enough: either it only carries the default state (`value`, `checked`,
     * `selected`, `muted`), or there is no attribute at all (`indeterminate`,
     * `scrollTop`, ...). Extend it if your markup drives other live
     * properties, custom element properties for instance.
     */
    public static var validProps:Map<String, Bool> = [
        // The attribute only holds the default state, the property the live one.
        'value' => true, 'checked' => true, 'selected' => true, 'muted' => true,
        // No attribute counterpart.
        'indeterminate' => true, 'selectedIndex' => true,
        'scrollTop' => true, 'scrollLeft' => true,
        'srcObject' => true, 'currentTime' => true, 'volume' => true, 'playbackRate' => true,
        'defaultValue' => true, 'defaultChecked' => true,
        'valueAsNumber' => true, 'valueAsDate' => true
    ];

    public function createElement(tagName:String, ?options:CreateElementOptions #if wisdom_debug , ?pos:haxe.PosInfos #end):Element {

        #if wisdom_debug
        haxe.Log.trace('createElement($tagName, $options)', pos);
        #end

        // Only pass options when there is something in them: `{is: null}`
        // gets coerced to the string "null" by WebIDL and stamps an `is="null"`
        // attribute on every element.
        return cast (options != null
            ? document.createElement(tagName, cast options)
            : document.createElement(tagName));

    }

    public function createElementNS(namespaceUri:String, qualifiedName:String, ?options:CreateElementOptions #if wisdom_debug , ?pos:haxe.PosInfos #end):Element {

        #if wisdom_debug
        haxe.Log.trace('createElementNS($namespaceUri, $tagName, $options)', pos);
        #end

        return cast (options != null
            ? document.createElementNS(namespaceUri, qualifiedName, cast options)
            : document.createElementNS(namespaceUri, qualifiedName));

    }

    public function createTextNode(text:String #if wisdom_debug , ?pos:haxe.PosInfos #end):Text {

        #if wisdom_debug
        haxe.Log.trace('createTextNode($text)', pos);
        #end

        return cast document.createTextNode(text);

    }

    public function createComment(text:String #if wisdom_debug , ?pos:haxe.PosInfos #end):Comment {

        #if wisdom_debug
        haxe.Log.trace('createComment($text)', pos);
        #end

        return cast document.createComment(text);

    }

    public function insertBefore(parentNode:Node, newNode:Node, referenceNode:Null<Node> #if wisdom_debug , ?pos:haxe.PosInfos #end):Void {

        #if wisdom_debug
        haxe.Log.trace('insertBefore($parentNode, $newNode, $referenceNode)', pos);
        #end

        final parentNodeHtml:js.html.Node = cast parentNode;
        cast parentNodeHtml.insertBefore(cast newNode, cast referenceNode);

    }

    public function removeChild(node:Node, child:Node #if wisdom_debug , ?pos:haxe.PosInfos #end):Void {

        #if wisdom_debug
        haxe.Log.trace('removeChild($node, $child)', pos);
        #end

        final nodeHtml:js.html.Node = cast node;
        nodeHtml.removeChild(cast child);

    }

    public function appendChild(node:Node, child:Node #if wisdom_debug , ?pos:haxe.PosInfos #end):Void {

        #if wisdom_debug
        haxe.Log.trace('appendChild($node, $child)', pos);
        #end

        final nodeHtml:js.html.Node = cast node;
        nodeHtml.appendChild(cast child);

    }

    public function parentNode(node:Node):Null<Node> {

        final nodeHtml:js.html.Node = cast node;
        return cast nodeHtml.parentNode;

    }

    public function nextSibling(node:Node):Null<Node> {

        final nodeHtml:js.html.Node = cast node;
        return cast nodeHtml.nextSibling;

    }

    public function tagName(elm:Element):String {

        final elmHtml:js.html.Element = cast elm;
        return elmHtml.tagName;

    }

    public function setTextContent(node:Node, text:Null<String> #if wisdom_debug , ?pos:haxe.PosInfos #end):Void {

        #if wisdom_debug
        haxe.Log.trace('setTextContent($node, $text)', pos);
        #end

        final nodeHtml:js.html.Node = cast node;
        nodeHtml.textContent = text;

    }

    public function getTextContent(node:Node):Null<String> {

        final nodeHtml:js.html.Node = cast node;
        return nodeHtml.textContent;

    }

    public function addClass(elm:Element, name:String #if wisdom_debug , ?pos:haxe.PosInfos #end):Void {

        #if wisdom_debug
        haxe.Log.trace('addClass($elm, $name)', pos);
        #end

        final elmHtml:js.html.Element = cast elm;
        elmHtml.classList.add(name);

    }

    public function removeClass(elm:Element, name:String #if wisdom_debug , ?pos:haxe.PosInfos #end):Void {

        #if wisdom_debug
        haxe.Log.trace('removeClass($elm, $name)', pos);
        #end

        final elmHtml:js.html.Element = cast elm;
        elmHtml.classList.remove(name);

    }

    public function setStyle(elm:Element, name:String, value:Any #if wisdom_debug , ?pos:haxe.PosInfos #end):Void {

        #if wisdom_debug
        haxe.Log.trace('setStyle($elm, $name, $value)', pos);
        #end

        if (value is Int || value is Float) {
            value = value + 'px';
        }

        final elmHtml:js.html.Element = cast elm;
        Reflect.setField(elmHtml.style, name, value);

    }

    public function removeStyle(elm:Element, name:String #if wisdom_debug , ?pos:haxe.PosInfos #end):Void {

        #if wisdom_debug
        haxe.Log.trace('removeStyle($elm, $name)', pos);
        #end

        final elmHtml:js.html.Element = cast elm;
        Reflect.deleteField(elmHtml.style, name);

    }

    public function isElement(node:Any):Bool {

        final nodeHtml:js.html.Node = cast node;
        return nodeHtml.nodeType == 1;

    }

    public function isText(node:Node):Bool {

        final nodeHtml:js.html.Node = cast node;
        return nodeHtml.nodeType == 3;

    }

    public function isComment(node:Node):Bool {

        final nodeHtml:js.html.Node = cast node;
        return nodeHtml.nodeType == 8;

    }

    public function elementId(elm:Element):Null<String> {

        final elmHtml:js.html.Element = cast elm;
        return elmHtml.id;

    }

    public function attribute(elm:Element, attr:String):Null<String> {

        final elmHtml:js.html.Element = cast elm;
        return elmHtml.getAttribute(attr);

    }

    public function setAttribute(elm:Element, attr:String, value:String #if wisdom_debug , ?pos:haxe.PosInfos #end):Void {

        #if wisdom_debug
        haxe.Log.trace('setAttribute($elm, $attr, $value)', pos);
        #end

        final elmHtml:js.html.Element = cast elm;
        elmHtml.setAttribute(attr, value);

    }

    public function removeAttribute(elm:Element, attr:String #if wisdom_debug , ?pos:haxe.PosInfos #end):Void {

        #if wisdom_debug
        haxe.Log.trace('removeAttribute($elm, $attr)', pos);
        #end

        final elmHtml:js.html.Element = cast elm;
        elmHtml.removeAttribute(attr);

    }

    public function setProp(elm:Element, name:String, value:Any #if wisdom_debug , ?pos:haxe.PosInfos #end):Void {

        #if wisdom_debug
        haxe.Log.trace('setProp($elm, $name, $value)', pos);
        #end

        final elmHtml:js.html.Element = cast elm;

        // Only the listed live properties are written as properties. Anything
        // else is served by the attribute path in PropsModule, which also
        // keeps read-only accessors such as `svg.width` or `input.list` from
        // ever being assigned (that throws in strict mode).
        if (!isValidProp(name)) return;

        final defaultValField:String = '_wisdom_def_' + name;
        if (!Reflect.hasField(elmHtml, defaultValField)) {
            Reflect.setField(elmHtml, defaultValField, getProp(elm, name));
        }
        // Bracket access, not `{0}.{1}`: a `{N}` placeholder injects the given
        // expression as-is, so the dot form would compile to a literal `.name`
        // property access instead of a dynamic one.
        js.Syntax.code('{0}[{1}] = {2}', elmHtml, name, value);

    }

    public function resetProp(elm:Element, name:String #if wisdom_debug , ?pos:haxe.PosInfos #end):Void {

        #if wisdom_debug
        haxe.Log.trace('resetProp($elm, $name)', pos);
        #end

        final elmHtml:js.html.Element = cast elm;
        final defaultValField:String = '_wisdom_def_' + name;
        // Nothing to restore if setProp() never wrote this property.
        if (!Reflect.hasField(elmHtml, defaultValField)) return;
        final defVal:Any = Reflect.field(elmHtml, defaultValField);
        js.Syntax.code('{0}[{1}] = {2}', elmHtml, name, defVal);

    }

    public function elementToNode(elm:Element):Node {

        return cast elm;

    }

    public function textToNode(text:Text):Node {

        return cast text;

    }

    public function commentToNode(comment:Comment):Node {

        return cast comment;

    }

    public function vnodeDataToCreateElementOptions(data:VNodeData):CreateElementOptions {

        // `null` (not `{is: null}`) when there is no custom element name, see
        // the note in createElement().
        final isa = data?.isa;
        return isa != null ? cast { 'is': isa } : null;

    }

    public function isAttribute(sel:String, name:String):Bool {

        return HtmlAttributes.isValidAttribute(sel, name) || SvgAttributes.isValidAttribute(sel, name);

    }

    /**
     * Whether `name` is one of the element properties setProp() may write,
     * see `validProps`. Deliberately a fixed list rather than DOM
     * introspection: deterministic, browser-independent, and it only writes
     * the properties that actually need to be properties.
     */
    public function isValidProp(name:String):Bool {

        return validProps.exists(name);

    }

    /**
     * Reciprocal of setProp(): the property when it is a valid one, otherwise
     * the attribute of the same name, which is where PropsModule put the value.
     */
    public function getProp(elm:Element, name:String):Any {

        final elmHtml:js.html.Element = cast elm;
        return isValidProp(name)
            ? js.Syntax.field(elmHtml, name)
            : elmHtml.getAttribute(name);

    }

    public function addEventListener(elm:Element, event:String, listener:Function #if wisdom_debug , ?pos:haxe.PosInfos #end):Void {

        #if wisdom_debug
        haxe.Log.trace('addEventListener($elm, $event, $listener)', pos);
        #end

        final elmHtml:js.html.Element = cast elm;
        elmHtml.addEventListener(event, listener, false);

    }

    public function removeEventListener(elm:Element, event:String, listener:Function #if wisdom_debug , ?pos:haxe.PosInfos #end):Void {

        #if wisdom_debug
        haxe.Log.trace('removeEventListener($elm, $event, $listener)', pos);
        #end

        final elmHtml:js.html.Element = cast elm;
        elmHtml.removeEventListener(event, listener, false);

    }

    public function fallbackComponentVNode(xid:Xid #if wisdom_debug , ?pos:haxe.PosInfos #end):VNode {

        #if wisdom_debug
        haxe.Log.trace('fallbackComponentVNode($xid)', pos);
        #end

        return VNode.vnode(xid, 'div', {}, [], null, null);

    }

    public function didAppendChildren(elm:Element #if wisdom_debug , ?pos:haxe.PosInfos #end):Void {

        final html:js.html.Element = cast elm;
        if (html.tagName == 'SELECT') {
            // Re-assert selectedness on option children from their content
            // attribute now that the <select> has its full option list.
            // Setting option.selected before the option is parented to the
            // select lets the browser's per-insertion "ask for a reset"
            // algorithm leave stale selectedness behind; this final pass
            // runs one more reset with the complete tree in place.
            final options = (cast html:js.html.SelectElement).options;
            for (i in 0...options.length) {
                final opt:js.html.OptionElement = cast options[i];
                opt.selected = opt.hasAttribute('selected');
            }
        }

    }

}

#end
