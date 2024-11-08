package wisdom;

import haxe.Constraints.Function;

abstract class Backend {

    abstract public function createElement(tagName:String, ?options:CreateElementOptions #if wisdom_debug , ?pos:haxe.PosInfos #end):Element;

    abstract public function createElementNS(namespaceUri:String, qualifiedName:String, ?options:CreateElementOptions #if wisdom_debug , ?pos:haxe.PosInfos #end):Element;

    abstract public function createTextNode(text:String #if wisdom_debug , ?pos:haxe.PosInfos #end):Text;

    abstract public function createComment(text:String #if wisdom_debug , ?pos:haxe.PosInfos #end):Comment;

    abstract public function insertBefore(parentNode:Node, newNode:Node, referenceNode:Null<Node> #if wisdom_debug , ?pos:haxe.PosInfos #end):Void;

    abstract public function removeChild(node:Node, child:Node #if wisdom_debug , ?pos:haxe.PosInfos #end):Void;

    abstract public function appendChild(node:Node, child:Node #if wisdom_debug , ?pos:haxe.PosInfos #end):Void;

    abstract public function parentNode(node:Node):Null<Node>;

    abstract public function nextSibling(node:Node):Null<Node>;

    abstract public function tagName(elm:Element):String;

    abstract public function setTextContent(node:Node, text:Null<String> #if wisdom_debug , ?pos:haxe.PosInfos #end):Void;

    abstract public function getTextContent(node:Node):Null<String>;

    abstract public function addClass(elm:Element, name:String #if wisdom_debug , ?pos:haxe.PosInfos #end):Void;

    abstract public function removeClass(elm:Element, name:String #if wisdom_debug , ?pos:haxe.PosInfos #end):Void;

    abstract public function setStyle(elm:Element, name:String, value:Any #if wisdom_debug , ?pos:haxe.PosInfos #end):Void;

    abstract public function removeStyle(elm:Element, name:String #if wisdom_debug , ?pos:haxe.PosInfos #end):Void;

    abstract public function isElement(node:Any):Bool;

    abstract public function isText(node:Node):Bool;

    abstract public function isComment(node:Node):Bool;

    abstract public function elementId(elm:Element):Null<String>;

    abstract public function attribute(elm:Element, attr:String):Null<String>;

    abstract public function setAttribute(elm:Element, attr:String, value:String #if wisdom_debug , ?pos:haxe.PosInfos #end):Void;

    abstract public function removeAttribute(elm:Element, attr:String #if wisdom_debug , ?pos:haxe.PosInfos #end):Void;

    abstract public function isAttribute(sel:String, name:String):Bool;

    abstract public function setProp(elm:Element, name:String, value:Any #if wisdom_debug , ?pos:haxe.PosInfos #end):Void;

    abstract public function elementToNode(elm:Element):Node;

    abstract public function textToNode(text:Text):Node;

    abstract public function commentToNode(comment:Comment):Node;

    abstract public function vnodeDataToCreateElementOptions(data:VNodeData):CreateElementOptions;

    abstract public function addEventListener(elm:Element, event:String, listener:Function #if wisdom_debug , ?pos:haxe.PosInfos #end):Void;

    abstract public function removeEventListener(elm:Element, event:String, listener:Function #if wisdom_debug , ?pos:haxe.PosInfos #end):Void;

}
