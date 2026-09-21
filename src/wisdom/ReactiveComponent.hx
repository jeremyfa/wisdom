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

    var didCallInit:Bool = false;

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

            reactiveContext.beginReaction();

            final _prevBaseXid = Wisdom.baseXid;
            final _prevRenderComponent = Wisdom.renderComponent;
            final _prevReactiveContext = Reactive.currentReactiveContext;

            if (rendered == null || _prevReactiveContext == reactiveContext) {

                // Use correct base xid for sub-components
                Wisdom.baseXid = xid;

                // Rendering from parent node or first render
                final renderChildren = freshChildren(children);
                var renderedRaw = null;
                if (compFunc != null) {
                    renderedRaw = compFunc(xid, reactiveContext, data, renderChildren);
                }
                else {
                    @:privateAccess compInstance.update(xid, reactiveContext, data, renderChildren);
                    if (!didCallInit) {
                        didCallInit = true;
                        final init = Reflect.field(compInstance, 'init');
                        if (init != null && Reflect.isFunction(init)) {
                            Reflect.callMethod(compInstance, init, @:privateAccess Wisdom.EMPTY_ARRAY);
                        }
                    }
                    renderedRaw =  @:privateAccess compInstance.render();
                }

                // Restore base xid
                Wisdom.baseXid = _prevBaseXid;

                unobserve();

                if (renderedRaw == null) {
                    renderedRaw = reactiveContext.wisdom.backend.fallbackComponentVNode(xid);
                }

                if (renderedRaw is Array) {
                    throw 'A reactive component must return a single node, not an array';
                }

                var renderedNode:VNode = renderedRaw;
                renderedNode.reactiveComponent = this;
                if (renderedNode.key == null) renderedNode.key = xid;

                rendered = renderedNode;
            }
            else {

                // Rendering from this autorun
                Wisdom.baseXid = xid;
                Wisdom.renderComponent = renderComponent;
                Reactive.currentReactiveContext = reactiveContext;

                final _prevRendered = rendered;

                final renderChildren = freshChildren(children);
                var renderedRaw = null;
                if (compFunc != null) {
                    renderedRaw = compFunc(xid, reactiveContext, data, renderChildren);
                }
                else {
                    @:privateAccess compInstance.update(xid, reactiveContext, data, renderChildren);
                    if (!didCallInit) {
                        didCallInit = true;
                        final init = Reflect.field(compInstance, 'init');
                        if (init != null && Reflect.isFunction(init)) {
                            Reflect.callMethod(compInstance, init, @:privateAccess Wisdom.EMPTY_ARRAY);
                        }
                    }
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
                if (renderedNode.key == null) renderedNode.key = xid;

                rendered = reactiveContext.patch(
                    _prevRendered,
                    renderedNode
                );
            }

            reactiveContext.endReaction();

        });

    }

    /**
     * Fresh copies of the children handed by the parent, for one render.
     *
     * The patch algorithm mutates vnodes in place (`elm` above all), so the
     * previous rendered tree and the new one must never share a vnode. When a
     * component re-renders from its own state the parent has not rendered
     * again, and `children` still holds the very objects sitting in the
     * previous tree: emitting them as is corrupts the diff as soon as a
     * sibling appears or disappears next to them. Two keyless `div`s get
     * paired positionally, the shared vnode's `elm` is rewritten to the
     * sibling's element, and the removal that follows takes the wrong node
     * out of the DOM.
     *
     * Component roots are the one exception. They are shared by identity on
     * purpose (see Reactive.renderReactiveComponent) and carry a unique key,
     * so the diff always pairs them with themselves. For those we return the
     * component's CURRENT root rather than the reference the parent captured,
     * which is stale if the nested component re-rendered on its own since.
     *
     * `data` is shared, not copied: the modules never mutate it, and they
     * short-circuit on identity, which makes patching unchanged content free.
     */
    static function freshChildren(children:Array<VNode>):Array<VNode> {

        if (children == null) return null;
        final result = [];
        for (i in 0...children.length) {
            result.push(fresh(children[i]));
        }
        return result;

    }

    static function fresh(vnode:VNode):VNode {

        if (vnode == null) return null;

        final component = vnode.reactiveComponent;
        if (component != null) {
            return component.rendered ?? vnode;
        }

        final copy = VNode.vnode(
            vnode.xid,
            vnode.sel,
            vnode.data,
            freshChildren(vnode.children),
            vnode.text,
            null
        );
        copy.key = vnode.key;
        return copy;

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
