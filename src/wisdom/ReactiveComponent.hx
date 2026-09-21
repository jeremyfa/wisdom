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

    /** True between didMount() and willUnmount() of the component instance. */
    public var mounted(default, null):Bool = false;

    /**
     * Wrapper-override pattern (see ReactiveContext.updateHook): when this
     * component's render() returns another component's root, that inner
     * component still owns the same physical vnode but the vnode only points
     * at us. Kept here so that mount and unmount reach it too.
     */
    public var inner(default, null):ReactiveComponent = null;

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
                claimRoot(renderedNode);
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
                claimRoot(renderedNode);
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

    /**
     * Takes ownership of the rendered root, remembering the component that
     * owned it before us when there is one (wrapper-override pattern).
     */
    function claimRoot(renderedNode:VNode):Void {

        final prevOwner = renderedNode.reactiveComponent;
        if (prevOwner == null) {
            inner = null;
        }
        else if (prevOwner != this) {
            inner = prevOwner;
        }
        // else: the vnode is still ours from a previous render, keep `inner`.
        renderedNode.reactiveComponent = this;

    }

    /** From this component to the innermost one sharing its root. */
    function chain():Array<ReactiveComponent> {

        final result = [];
        var rc = this;
        var guard = 0;
        while (rc != null && guard++ < 64) {
            result.push(rc);
            rc = rc.inner;
        }
        return result;

    }

    /**
     * `root` is the vnode that was just created for this component. It is
     * passed in rather than read from `rendered`: a self re-render assigns
     * `rendered` only after the patch (and this mount) returned.
     */
    @:allow(wisdom.ReactiveContext)
    function mount(root:VNode):Void {

        if (root == null || root.elm == null) return;

        // Innermost first: the inner component is conceptually the child.
        final list = chain();
        var i = list.length - 1;
        while (i >= 0) {
            final rc = list[i];
            if (!rc.mounted) {
                rc.mounted = true;
                if (rc.compInstance != null) {
                    @:privateAccess rc.compInstance.didMount(root.elm);
                }
            }
            i--;
        }

    }

    @:allow(wisdom.ReactiveContext)
    function unmount():Void {

        // Outermost first.
        for (rc in chain()) {
            if (rc.mounted) {
                rc.mounted = false;
                if (rc.compInstance != null) {
                    @:privateAccess rc.compInstance.willUnmount();
                }
            }
        }

    }

    public function update(data, children):Void {

        this.data = data;
        this.children = children;

        if (autorun.invalidated) {
            autorun.run();
        }

    }

    public function destroy() {

        // No DOM hook fires when a whole context goes away or when liveness
        // decides a component is gone: make sure the instance still sees the
        // unmount before it is destroyed.
        unmount();

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
