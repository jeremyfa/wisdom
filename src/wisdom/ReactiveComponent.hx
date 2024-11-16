package wisdom;

#if tracker

import tracker.Autorun.unobserve;
import tracker.Autorun;
import tracker.Observable;

class ReactiveComponent implements Observable {

    public var xid(default, null):Xid;

    public var compFunc(default, null):(xid:Xid, ctx:ReactiveContext, data:VNodeData, children:Array<VNode>)->Any;

    public var compInstance(default, null):Component;

    public var autorun(default, null):Autorun;

    public var rendered(default, null):VNode = null;

    public var reactiveContext(default, null):ReactiveContext = null;

    public var renderComponent(default, null):RenderComponent = null;

    @observe public var data:VNodeData = null;

    @observe public var children:Array<VNode> = null;

    public function new(
        xid:Xid,
        comp:Any,
        data:VNodeData,
        children:Array<VNode>,
        reactiveContext:ReactiveContext,
        renderComponent:RenderComponent
        ) {

        this.xid = xid;

        if (Reflect.isFunction(comp)) {
            this.compFunc = comp;
            this.compInstance = null;
        }
        else {
            this.compFunc = null;
            this.compInstance = Type.createInstance(
                comp,
                @:privateAccess Wisdom.EMPTY_ARRAY
            );
        }

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
                var renderedRaw = null;
                if (compFunc != null) {
                    renderedRaw = compFunc(xid, reactiveContext, data, children);
                }
                else {
                    @:privateAccess compInstance.update(xid, reactiveContext, data, children);
                    renderedRaw =  @:privateAccess compInstance.render();
                }

                unobserve();

                if (renderedRaw == null) {
                    renderedRaw = reactiveContext.wisdom.backend.fallbackComponentVNode(xid);
                }

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

                var renderedRaw = null;
                if (compFunc != null) {
                    renderedRaw = compFunc(xid, reactiveContext, data, children);
                }
                else {
                    @:privateAccess compInstance.update(xid, reactiveContext, data, children);
                    renderedRaw =  @:privateAccess compInstance.render();
                }

                Wisdom.baseXid = _prevBaseXid;
                Wisdom.renderComponent = _prevRenderComponent;
                Reactive.currentReactiveContext = _prevReactiveContext;

                unobserve();

                if (renderedRaw == null) {
                    renderedRaw = reactiveContext.wisdom.backend.fallbackComponentVNode(xid);
                }

                if (renderedRaw is Array) {
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

        if (compInstance != null) {
            compInstance.destroy();
            compInstance = null;
        }

        compFunc = null;
        data = null;
        children = null;
        rendered = null;

    }

}

#end
