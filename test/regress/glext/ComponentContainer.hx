package glext;

extern class ComponentContainer {
    var element(default, never):js.html.Element;
    var initialState(default, never):Dynamic;
    var state(default, never):Dynamic;
    var title(default, never):String;
    var componentType(default, never):Dynamic;
    var visible(default, never):Bool;
    function setTitle(title:String):Void;
    function close():Void;
    function focus(?suppressEvent:Bool):Void;
}
