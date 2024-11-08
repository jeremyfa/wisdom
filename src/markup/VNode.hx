package markup;

@:structInit
class VNode {

    public var xid:Xid = null;
    public var sel:String = null;
    public var data:VNodeData = null;
    public var children:Array<VNode> = null;
    public var elm:Node = null;
    public var text:String = null;
    public var key:Key = null;

    #if tracker
    public var reactiveComponent:ReactiveComponent = null;
    #end

    public static function vnode(
        xid:Xid, sel:String, data:VNodeData, children: Array<VNode>, text:String, elm:Node
    ):VNode {
        final key = data != null ? Reflect.getProperty(data, 'key') : null;
        return {
            xid: xid,
            sel: sel,
            data: data,
            children: children,
            text: text,
            elm: elm,
            key: key
        };
    }

}
