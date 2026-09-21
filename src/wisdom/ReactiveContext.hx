package wisdom;

#if tracker

import tracker.Autorun;
import tracker.Immediate;
import tracker.Tracker;

class ReactiveContext {

    public var wisdom(default, null):Wisdom = null;

    @:allow(wisdom.Reactive)
    public var container(default, null):Any = null;

    @:allow(wisdom.Reactive)
    public var autorun(default, null):Autorun = null;

    @:allow(wisdom.Reactive)
    public var components(default, null):Map<Xid,ReactiveComponent> = new Map();

    @:allow(wisdom.Reactive)
    public var states(default, null):Map<Xid,State> = new Map();

    public var hooks(default, null):Module = null;

    public var immediate(default, null):Immediate = new Immediate();

    var numReactions:Int = 0;

    var componentsToCheck:Map<Xid,ReactiveComponent> = new Map();

    /** Component roots created by the current patch, mounted once it is over. */
    var pendingMounts:Array<VNode> = [];

    public function new(wisdom:Wisdom, container:Any) {

        this.wisdom = wisdom;
        this.container = container;

        hooks = {
            create: createHook,
            update: updateHook,
            remove: removeHook,
            destroy: destroyHook
        };

    }

    /**
     * A component root was just created (createElm). It is not attached yet:
     * mounting happens in flushMounts(), once the patch is over and this
     * context's bookkeeping (container, replaceVNode) is consistent, so that
     * user code in didMount() may read the tree or write observables safely.
     */
    function createHook(wisdom:Wisdom, emptyVNode:VNode, vNode:VNode) {

        final rc = vNode.reactiveComponent;
        if (rc != null && components.get(rc.xid) == rc) {
            pendingMounts.push(vNode);
        }

    }

    function updateHook(wisdom:Wisdom, oldVNode:VNode, vNode:VNode) {

        if (oldVNode != null && oldVNode.reactiveComponent != null) {
            final oldXid = oldVNode.reactiveComponent.xid;
            if (components.exists(oldXid)) {
                final oldComponent = components.get(oldXid);
                final newXid = vNode?.reactiveComponent?.xid;
                if (newXid != oldXid) {
                    if (newXid != null && StringTools.startsWith(newXid, oldXid)) {
                        // Wrapper-override pattern.
                        //
                        // Some components render only another component as
                        // their entire output, e.g.
                        //
                        //     class SettingsPopup {
                        //         function render() '<><Popup>...</Popup></>';
                        //     }
                        //
                        // When SettingsPopup runs, the value its render()
                        // returns is whatever Wisdom.c(...) gave back for the
                        // <Popup> call -- that's literally Popup_RC.rendered
                        // (the popup's div vnode). There is only ONE physical
                        // vnode object at that position. Wisdom lets the
                        // outer wrapper claim ownership by overwriting that
                        // shared vnode's `reactiveComponent` field with the
                        // outer component (see ReactiveComponent.hx where we
                        // do `renderedNode.reactiveComponent = this`).
                        //
                        // Xids are concatenated paths (baseXid + xid in
                        // Wisdom.c), so a child component's xid always
                        // begins with its rendering parent's xid:
                        //   SettingsPopup_RC.xid = "/3~1/1~8"
                        //   Popup_RC.xid         = "/3~1/1~8/1~19"
                        // The prefix relationship `startsWith(newXid, oldXid)`
                        // is therefore a structural check that this old/new
                        // pair came from a wrapper/inner relationship -- not
                        // a coincidence.
                        //
                        // What goes wrong without this branch: the inner
                        // component's autorun can re-render standalone (its
                        // own observed field changed), patch its own old/new
                        // rendered, and updateHook fires here with
                        //   oldVNode.reactiveComponent = wrapper (overridden)
                        //   vNode.reactiveComponent    = inner  (just claimed)
                        // The default branch below would then queue the
                        // wrapper for cleanup, postAllReactions wouldn't find
                        // it (the new vnode in the container tree now points
                        // at the inner), and the wrapper would get destroyed
                        // mid-life along with all its subscriptions.
                        //
                        // Fix: transfer the wrapper's claim to the new vnode
                        // here, on the patch boundary. The wrapper survives
                        // postAllReactions because its xid stays reachable
                        // via the new vnode in the container tree.
                        vNode.reactiveComponent = oldComponent;
                    }
                    else {
                        #if wisdom_debug_reactions
                        trace('queue (updateHook): ' + oldXid + ' (' + Type.getClassName(Type.getClass(oldComponent.compInstance)) + ') — newXid was ' + newXid);
                        #end
                        // Looks like the element is preserved, but doesn't
                        // belong to that component anymore, so we add the component and xid
                        // to the list of components to check after all reactions have been processed
                        componentsToCheck.set(oldXid, oldComponent);
                        oldVNode.reactiveComponent = null;
                    }
                }
            }
        }

    }

    function removeHook(wisdom:Wisdom, node:VNode, removeCallback:()->Void) {

        checkRemovedNodeComponent(node);
        removeCallback();

    }

    function destroyHook(wisdom:Wisdom, node:VNode) {

        checkRemovedNodeComponent(node);

        final rc = node?.reactiveComponent;
        if (rc != null && components.get(rc.xid) == rc) {
            // Created and removed within the same patch: never mounted,
            // nothing to mount.
            while (pendingMounts.remove(node)) {}
            // The element is still attached here (destroy runs before the DOM
            // removal). If the component survives because its root is
            // re-created elsewhere in this patch, createHook has queued or will
            // queue the new root and didMount() follows.
            rc.unmount();
        }

    }

    function flushMounts():Void {

        if (pendingMounts.length == 0) return;
        final list = pendingMounts;
        pendingMounts = [];
        for (i in 0...list.length) {
            final vnode = list[i];
            final rc = vnode.reactiveComponent;
            if (rc != null && components.get(rc.xid) == rc && rc.rendered == vnode) {
                rc.mount();
            }
        }

    }

    /** Patch of the whole tree by Reactive.reactive(): store the result, then mount. */
    public function patchRoot(renderedRaw:Any):Void {

        container = wisdom.patch(container, renderedRaw);
        flushMounts();

    }

    /**
     * A vnode carrying a component was removed from the DOM. That does not
     * mean the component is gone: component roots are shared by identity
     * between the previous tree and the new one, and when a keyless ancestor
     * gets paired with a different sibling the same root is created again in
     * its new place while its old place is removed. So we only queue the
     * component here, and `postAllReactions` decides by looking at the
     * rendered tree once every reaction has settled. The pointer stays on the
     * vnode until then, or the tree walk could not find it.
     */
    function checkRemovedNodeComponent(node:VNode) {

        if (node != null && node.reactiveComponent != null && components.exists(node.reactiveComponent.xid)) {
            var reactiveComponent = node.reactiveComponent;
            componentsToCheck.set(reactiveComponent.xid, reactiveComponent);
        }

    }

    public function patch(prevRendered:VNode, renderedRaw:Any) {

        final isRoot = (container == prevRendered);

        final rendered = wisdom.patch(
            prevRendered,
            renderedRaw
        );

        if (!isRoot && rendered != prevRendered) {
            if (VNode.isVNode(container) && VNode.isVNode(prevRendered) && VNode.isVNode(rendered)) {
                replaceVNode(container, prevRendered, rendered);
            }
        }

        flushMounts();

        return rendered;

    }

    function replaceVNode(vnode:VNode, toReplace:VNode, replacement:VNode):Bool {

        var replaced = false;
        if (vnode != null) {
            final compChildren = vnode.reactiveComponent?.children;
            if (compChildren != null) {
                for (j in 0...compChildren.length) {
                    final compChild = compChildren[j];
                    if (compChild == toReplace) {
                        compChildren[j] = replacement;
                        replaced = true;
                        break;
                    }
                }
            }
            final children = vnode.children;
            if (children != null) {
                for (i in 0...children.length) {
                    final child = children[i];
                    if (child == toReplace) {
                        children[i] = replacement;
                        replaced = true;
                        break;
                    }
                    else {
                        if (replaceVNode(child, toReplace, replacement)) {
                            replaced = true;
                            break;
                        }
                    }
                }
            }
        }

        return replaced;

    }

    public function destroy() {

        wisdom.removeModule(hooks);

        if (autorun != null) {
            autorun.destroy();
            autorun = null;
        }

        for (reactiveComponent in components) {
            reactiveComponent.destroy();
        }
        components = null;
        pendingMounts = [];

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

    public function beginReaction():Void {

        #if wisdom_debug_reactions
        if (numReactions == 0) {
            trace('- begin reactions -');
        }
        #end

        numReactions++;

    }

    public function endReaction():Void {

        immediate.oncePostFlushImmediate(handleEndOfReaction);

    }

    function handleEndOfReaction():Void {

        numReactions--;
        if (numReactions == 0) {
            postAllReactions();
        }

    }

    function postAllReactions():Void {

        #if wisdom_debug_reactions
        trace('- end reactions -');
        #end

        if (VNode.isVNode(container)) {
            var usedComponents = new Map<Xid,ReactiveComponent>();
            collectVNodeComponents(container, usedComponents);
            for (xid => comp in componentsToCheck) {
                if (!usedComponents.exists(xid)) {
                    #if wisdom_debug_reactions
                    trace('cleanup: ' + xid + ' (' + Type.getClassName(Type.getClass(comp.compInstance)) + ')');
                    #end
                    components.remove(xid);
                    // The root may still be referenced by a parent's
                    // `children`. Detach it from the dead component so
                    // that a later render treats it as plain markup.
                    final root = comp.rendered;
                    if (root != null && root.reactiveComponent == comp) {
                        root.reactiveComponent = null;
                    }
                    comp.destroy();
                }
            }
            componentsToCheck.clear();
        }

    }

    /**
     * A component is alive when its root is in the rendered tree, and only
     * then. The `children` a parent hands to a component are not walked:
     * they describe what the parent offers, and a component that hides its
     * slot has removed those children from the tree, which destroys them
     * exactly as an `<if>` around a component does anywhere else.
     */
    function collectVNodeComponents(vnode:VNode, usedComponents:Map<Xid,ReactiveComponent>):Void {

        if (vnode != null) {
            final component = vnode.reactiveComponent;
            if (component != null) {
                usedComponents.set(component.xid, component);
            }
            final children = vnode.children;
            if (children != null) {
                for (i in 0...children.length) {
                    final child = children[i];
                    collectVNodeComponents(child, usedComponents);
                }
            }
        }

    }

}

#else

typedef ReactiveContext = Any;

#end
