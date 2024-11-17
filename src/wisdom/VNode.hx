package wisdom;

abstract VNode(VNodeImpl) from VNodeImpl to VNodeImpl {

    public var xid(get,set):Xid;
    inline function get_xid():Xid {
        return this.xid;
    }
    inline function set_xid(xid:Xid):Xid {
        return this.xid = xid;
    }

    public var sel(get,set):String;
    inline function get_sel():String {
        return this.sel;
    }
    inline function set_sel(sel:String):String {
        return this.sel = sel;
    }

    public var data(get,set):VNodeData;
    inline function get_data():VNodeData {
        return this.data;
    }
    inline function set_data(data:VNodeData):VNodeData {
        return this.data = data;
    }

    public var children(get,set):Array<VNode>;
    inline function get_children():Array<VNode> {
        return this.children;
    }
    inline function set_children(children:Array<VNode>):Array<VNode> {
        return this.children = children;
    }

    public var elm(get,set):Node;
    inline function get_elm():Node {
        return this.elm;
    }
    inline function set_elm(elm:Node):Node {
        return this.elm = elm;
    }

    public var text(get,set):String;
    inline function get_text():String {
        return this.text;
    }
    inline function set_text(text:String):String {
        return this.text = text;
    }

    public var key(get,set):Key;
    inline function get_key():Key {
        return this.key;
    }
    inline function set_key(key:Key):Key {
        return this.key = key;
    }

    #if tracker
    public var reactiveComponent(get,set):ReactiveComponent;
    inline function get_reactiveComponent():ReactiveComponent {
        return this.reactiveComponent;
    }
    inline function set_reactiveComponent(reactiveComponent:ReactiveComponent):ReactiveComponent {
        return this.reactiveComponent = reactiveComponent;
    }
    #end

    @:noCompletion @:from public static function fromString(str:String):VNode {
        // Mostly for not breaking code completion
        return null;
    }

    public inline static function isVNode(obj:Any):Bool {
        return obj is VNodeImpl;
    }

    public static function vnode(
        xid:Xid, sel:String, data:VNodeData, children: Array<VNode>, text:String, elm:Node
    ):VNode {
        final key = data != null ? Reflect.getProperty(data, 'key') : null;
        final vnodeImpl:VNodeImpl = {
            xid: xid,
            sel: sel,
            data: data,
            children: children,
            text: text,
            elm: elm,
            key: key
        };
        return vnodeImpl;
    }

}

@:allow(wisdom.VNode)
@:structInit
private class VNodeImpl {

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

}
