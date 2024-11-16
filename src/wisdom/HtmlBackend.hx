package wisdom;

import haxe.Constraints.Function;
#if wisdom_html

import js.Browser.document;

class HtmlBackend extends Backend {

    public function new() {}

    public function createElement(tagName:String, ?options:CreateElementOptions #if wisdom_debug , ?pos:haxe.PosInfos #end):Element {

        #if wisdom_debug
        haxe.Log.trace('createElement($tagName, $options)', pos);
        #end

        return cast document.createElement(tagName, cast options);

    }

    public function createElementNS(namespaceUri:String, qualifiedName:String, ?options:CreateElementOptions #if wisdom_debug , ?pos:haxe.PosInfos #end):Element {

        #if wisdom_debug
        haxe.Log.trace('createElementNS($namespaceUri, $tagName, $options)', pos);
        #end

        return cast document.createElementNS(namespaceUri, qualifiedName, cast options);

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
        js.Syntax.code('{0}.{1} = {2}', elmHtml, name, value);

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

        return cast {
            'is': data.isa
        };

    }

    public function isAttribute(sel:String, name:String):Bool {

        return HtmlAttributes.isValidAttribute(sel, name) || SvgAttributes.isValidAttribute(sel, name);

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

    public function fallbackComponentVNode(xid:Xid, #if wisdom_debug , ?pos:haxe.PosInfos #end):VNode {

        #if wisdom_debug
        haxe.Log.trace('fallbackComponentVNode($xid)', pos);
        #end

        return VNode.vnode(xid, 'div', {}, [], null, null);

    }

}

#end
