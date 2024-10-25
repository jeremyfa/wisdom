package markup;

@:structInit
class VNodeData {
    public var props:VNodeProps = null;
    public var attrs:Attrs = null;
    public var classes:Classes = null;
    public var style:Style = null;
    public var on:On = null;
    public var attachData:AttachData = null;
    public var hook:Hooks = null;
    public var key:Key = null;
    public var ns:String = null; // for SVGs
    public var fn:()->VNode = null; // for thunks
    public var args:Array<Any> = null; // for thunks
    public var isa:String = null; // for custom elements v1
}
