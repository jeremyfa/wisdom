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

    /**
     * Called once the component's root element is attached to the document, at
     * the end of the patch that created it. Called again, after `willUnmount()`,
     * when the root element is re-created (root selector changed, or the root was
     * moved by a structural change in the parent). `elm` is the backend element
     * (js.html.Element with HtmlBackend); for a component whose root is a
     * <portal> it is the placeholder comment node. Only components rendered
     * through `wisdom.reactive()` get this lifecycle.
     */
    function didMount(elm:Any):Void {}

    /**
     * Called right before the root element leaves the DOM (the element is still
     * attached), and before `destroy()` when the component is destroyed. Never
     * called twice without a `didMount()` in between.
     */
    function willUnmount():Void {}

    #if tracker
    override function destroy() {
        super.destroy();
    }
    #else
    function destroy() {}
    #end

}
