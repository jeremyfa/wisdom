package markup;

abstract class DomApi {

    abstract public function createElement(tagName:String, ?options:CreateElementOptions #if markup_debug , ?pos:haxe.PosInfos #end):Element;

    abstract public function createElementNS(namespaceUri:String, qualifiedName:String, ?options:CreateElementOptions #if markup_debug , ?pos:haxe.PosInfos #end):Element;

    abstract public function createTextNode(text:String #if markup_debug , ?pos:haxe.PosInfos #end):Text;

    abstract public function createComment(text:String #if markup_debug , ?pos:haxe.PosInfos #end):Comment;

    abstract public function insertBefore(parentNode:Node, newNode:Node, referenceNode:Null<Node> #if markup_debug , ?pos:haxe.PosInfos #end):Void;

    abstract public function removeChild(node:Node, child:Node #if markup_debug , ?pos:haxe.PosInfos #end):Void;

    abstract public function appendChild(node:Node, child:Node #if markup_debug , ?pos:haxe.PosInfos #end):Void;

    abstract public function parentNode(node:Node):Null<Node>;

    abstract public function nextSibling(node:Node):Null<Node>;

    abstract public function tagName(elm:Element):String;

    abstract public function setTextContent(node:Node, text:Null<String> #if markup_debug , ?pos:haxe.PosInfos #end):Void;

    abstract public function getTextContent(node:Node):Null<String>;

    abstract public function addClass(elm:Element, name:String #if markup_debug , ?pos:haxe.PosInfos #end):Void;

    abstract public function removeClass(elm:Element, name:String #if markup_debug , ?pos:haxe.PosInfos #end):Void;

    abstract public function setStyle(elm:Element, name:String, value:Any #if markup_debug , ?pos:haxe.PosInfos #end):Void;

    abstract public function removeStyle(elm:Element, name:String #if markup_debug , ?pos:haxe.PosInfos #end):Void;

    abstract public function isElement(node:Any):Bool;

    abstract public function isText(node:Node):Bool;

    abstract public function isComment(node:Node):Bool;

    abstract public function elementId(elm:Element):Null<String>;

    abstract public function elementAttribute(elm:Element, attr:String):Null<String>;

    abstract public function elementSetAttribute(elm:Element, attr:String, value:String #if markup_debug , ?pos:haxe.PosInfos #end):Void;

    abstract public function elementToNode(elm:Element):Node;

    abstract public function textToNode(text:Text):Node;

    abstract public function commentToNode(comment:Comment):Node;

    abstract public function vnodeDataToCreateElementOptions(data:VNodeData):CreateElementOptions;

}
