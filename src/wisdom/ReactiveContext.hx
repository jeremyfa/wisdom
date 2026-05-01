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

    public function new(wisdom:Wisdom, container:Any) {

        this.wisdom = wisdom;
        this.container = container;

        hooks = {
            update: updateHook,
            remove: removeHook,
            destroy: destroyHook
        };

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

    }

    function checkRemovedNodeComponent(node:VNode) {

        if (node != null && node.reactiveComponent != null && components.exists(node.reactiveComponent.xid)) {
            var reactiveComponent = node.reactiveComponent;
            componentsToCheck.set(reactiveComponent.xid, reactiveComponent);
            node.reactiveComponent = null;
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
                    comp.destroy();
                }
            }
            componentsToCheck.clear();
        }

    }

    function collectVNodeComponents(vnode:VNode, usedComponents:Map<Xid,ReactiveComponent>):Void {

        if (vnode != null) {
            final component = vnode.reactiveComponent;
            if (component != null) {
                usedComponents.set(component.xid, component);
                final compChildren = component.children;
                if (compChildren != null) {
                    for (j in 0...compChildren.length) {
                        final compChild = compChildren[j];
                        collectVNodeComponents(compChild, usedComponents);
                    }
                }
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
