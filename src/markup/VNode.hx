package markup;

@:structInit
class VNode {
    public var sel:String = null;
    public var data:VNodeData = null;
    public var children:Array<Any> = null;
    public var elm:Node = null;
    public var text:String = null;
    public var key:Key = null;

    public static function vnode(
        sel:String, data:Any, children: Array<Any>, text:String, elm:Node
    ):VNode {
        final key = data != null ? Reflect.getProperty(data, 'key') : null;
        return {
            sel: sel,
            data: data,
            children: children,
            text: text,
            elm: elm,
            key: key
        };
    }
}
