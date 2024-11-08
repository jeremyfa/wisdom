package wisdom;

#if tracker

import tracker.Autorun.unobserve;
import tracker.Autorun;
import tracker.Observable;

class ReactiveComponent implements Observable {

    public var xid(default, null):Xid;

    public var comp(default, null):(xid:Xid, ctx:ReactiveContext, data:VNodeData, children:Array<VNode>)->Any;

    public var autorun(default, null):Autorun;

    public var rendered(default, null):VNode = null;

    public var reactiveContext(default, null):ReactiveContext = null;

    public var renderComponent(default, null):RenderComponent = null;

    @observe public var data:VNodeData = null;

    @observe public var children:Array<VNode> = null;

    public function new(
        xid:Xid,
        comp:(xid:Xid, ctx:ReactiveContext, data:VNodeData, children:Array<VNode>)->Any,
        data:VNodeData,
        children:Array<VNode>,
        reactiveContext:ReactiveContext,
        renderComponent:RenderComponent
        ) {

        this.xid = xid;
        this.comp = comp;

        this.data = data;
        this.children = children;

        this.reactiveContext = reactiveContext;
        this.renderComponent = renderComponent;

        initAutorun();

    }

    function initAutorun() {

        autorun = new Autorun(() -> {

            final _prevBaseXid = Wisdom.baseXid;
            final _prevRenderComponent = Wisdom.renderComponent;
            final _prevReactiveContext = Reactive.currentReactiveContext;

            if (rendered == null || _prevReactiveContext == reactiveContext) {

                // Rendering from parent node or first render
                var renderedRaw = comp(xid, reactiveContext, data, children);

                unobserve();

                if (renderedRaw is Array) {
                    throw 'A reactive component must return a single node, not an array';
                }

                var renderedNode:VNode = renderedRaw;
                renderedNode.reactiveComponent = this;

                rendered = renderedNode;
            }
            else {

                // Rendering from this autorun
                Wisdom.baseXid = xid;
                Wisdom.renderComponent = renderComponent;
                Reactive.currentReactiveContext = reactiveContext;

                final _prevRendered = rendered;
                var renderedRaw = comp(xid, reactiveContext, data, children);

                Wisdom.baseXid = _prevBaseXid;
                Wisdom.renderComponent = _prevRenderComponent;
                Reactive.currentReactiveContext = _prevReactiveContext;

                unobserve();

                if (renderedRaw is Array) {
                    //renderedRaw = VNode.vnode("", {}, renderedRaw, null, null);
                    throw 'A reactive component must return a single node, not an array';
                }

                var renderedNode:VNode = renderedRaw;
                renderedNode.reactiveComponent = this;

                rendered = reactiveContext.patch(
                    _prevRendered,
                    renderedNode
                );
            }

        });

    }

    public function update(data, children):Void {

        this.data = data;
        this.children = children;

        if (autorun.invalidated) {
            autorun.run();
        }

    }

    public function destroy() {

        if (autorun != null) {
            autorun.destroy();
            autorun = null;
        }

        comp = null;
        data = null;
        children = null;
        rendered = null;

    }

}

#end
