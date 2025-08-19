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
                    // Looks like the element is preserved, but doesn't
                    // belong to that component anymore, so we add the component and xid
                    // to the list of components to check after all reactions have been processed
                    componentsToCheck.set(oldXid, oldComponent);
                    oldVNode.reactiveComponent = null;
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
