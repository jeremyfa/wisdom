package glext;

import js.html.Element;

/**
 * Minimal externs for golden-layout 2.6.0 (dist/cjs), limited to what a
 * Wisdom integration needs. Prefer bindComponentEvent/unbindComponentEvent
 * over the deprecated getComponentEvent/releaseComponentEvent, and never mix
 * them with the register* functions.
 */
@:jsRequire("golden-layout", "GoldenLayout")
extern class GoldenLayout {
    function new(?container:Element,
        ?bindComponentEventHandler:(container:ComponentContainer, itemConfig:Dynamic)->BindableComponent,
        ?unbindComponentEventHandler:(container:ComponentContainer)->Void);
    var bindComponentEvent:(container:ComponentContainer, itemConfig:Dynamic)->BindableComponent;
    var unbindComponentEvent:(container:ComponentContainer)->Void;
    var resizeWithContainerAutomatically:Bool;
    var rootItem(default, never):ContentItem;
    var container(default, never):Element;
    function loadLayout(config:Dynamic):Void;
    function saveLayout():Dynamic;
    function clear():Void;
    function destroy():Void;
    function setSize(width:Float, height:Float):Void;
    function updateRootSize(?force:Bool):Void;
    function addComponentAtLocation(componentType:Dynamic, ?componentState:Dynamic, ?title:String, ?locationSelectors:Array<Dynamic>):Dynamic;
    function on(eventName:String, callback:Dynamic):Void;
    function off(eventName:String, callback:Dynamic):Void;
}
