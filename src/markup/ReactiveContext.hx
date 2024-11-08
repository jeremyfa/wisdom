package markup;

#if tracker

import tracker.Autorun;
import tracker.Tracker;

class ReactiveContext {

    public var markup(default, null):Markup = null;

    @:allow(markup.Reactive)
    public var container(default, null):Any = null;

    @:allow(markup.Reactive)
    public var autorun(default, null):Autorun = null;

    @:allow(markup.Reactive)
    public var components(default, null):Map<Xid,ReactiveComponent> = new Map();

    @:allow(markup.Reactive)
    public var states(default, null):Map<Xid,State> = new Map();

    public var hooks(default, null):Module = null;

    public function new(markup:Markup, container:Any) {

        this.markup = markup;
        this.container = container;

        hooks = {
            remove: removeHook,
            destroy: destroyHook
        };

    }

    function removeHook(markup:Markup, node:VNode, removeCallback:()->Void) {

        checkRemovedNodeComponent(node);
        removeCallback();

    }

    function destroyHook(markup:Markup, node:VNode) {

        checkRemovedNodeComponent(node);

    }

    function checkRemovedNodeComponent(node:VNode) {

        if (node != null && node.reactiveComponent != null && components.exists(node.reactiveComponent.xid)) {
            var reactiveComponent = node.reactiveComponent;
            components.remove(reactiveComponent.xid);
            reactiveComponent.destroy();
            node.reactiveComponent = null;
        }

    }

    public function patch(prevRendered:VNode, renderedRaw:Any) {

        final isRoot = (container == prevRendered);

        final rendered = markup.patch(
            prevRendered,
            renderedRaw
        );

        if (!isRoot && rendered != prevRendered) {
            if (container is VNode && prevRendered is VNode && rendered is VNode) {
                replaceVNode(container, prevRendered, rendered);
            }
        }

        return rendered;

    }

    function replaceVNode(vnode:VNode, toReplace:VNode, replacement:VNode):Bool {

        if (vnode != null) {
            final children = vnode.children;
            if (children != null) {
                for (i in 0...children.length) {
                    final child = children[i];
                    if (child == toReplace) {
                        children[i] = replacement;
                        return true;
                    }
                    else {
                        if (replaceVNode(child, toReplace, replacement)) {
                            return true;
                        }
                    }
                }
            }
        }

        return false;

    }

    public function destroy() {

        markup.removeModule(hooks);

        if (autorun != null) {
            autorun.destroy();
            autorun = null;
        }

        for (reactiveComponent in components) {
            reactiveComponent.destroy();
        }
        components = null;

        container = null;

    }

    public function getState(xid:Xid):State {

        return states.get(xid);

    }

    public function initState(xid:Xid):State {

        final state:State = {};
        states.set(xid, state);
        return state;

    }

}

#else

typedef ReactiveContext = Any;

#end
