package wisdom;

#if !macro
@:autoBuild(wisdom.ComponentMacro.build())
#end
abstract class Component implements X #if tracker implements tracker.Observable extends #if tracker_ceramic ceramic.Entity #else tracker.Entity #end #end {

    public var xid(default, null):Xid;

    public var ctx(default, null):ReactiveContext;

    public var data(default, null):VNodeData;

    public var children(default, null):Array<VNode>;

    public function new() {
        #if tracker
        super();
        #end
    }

    function update(xid:Xid, ctx:ReactiveContext, data:VNodeData, children:Array<VNode>):Void {

        this.xid = xid;
        this.ctx = ctx;
        this.data = data;
        this.children = children;

    }

    abstract function render():VNode;

    #if tracker
    override function destroy() {
        super.destroy();
    }
    #else
    function destroy() {}
    #end

}
