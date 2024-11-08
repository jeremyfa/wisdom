package markup;

import haxe.DynamicAccess;
import haxe.Int64;

using StringTools;

#if macro
import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.ExprTools;
import haxe.macro.PositionTools;
#end

#if tracker
@:using(markup.Reactive)
#end
class Markup implements X {

    #if !macro

    static final EMPTY_NODE = VNode.vnode(null, "", {}, [], null, null);

    static final SVG_NS = "http://www.w3.org/2000/svg";

    final cbs = new ModuleHooks();

    public static var renderComponent:RenderComponent = null;

    public static var baseXid:Xid = null;

    public var backend(default, null):Backend;

    public function new(modules:Array<Module>, backend:Backend) {

        this.backend = backend;

        for (module in modules) {
            if (module.create != null) {
                cbs.create.push(module.create);
            }
            if (module.update != null) {
                cbs.update.push(module.update);
            }
            if (module.remove != null) {
                cbs.remove.push(module.remove);
            }
            if (module.destroy != null) {
                cbs.destroy.push(module.destroy);
            }
            if (module.pre != null) {
                cbs.pre.push(module.pre);
            }
            if (module.post != null) {
                cbs.post.push(module.post);
            }
        }

    }

    public function addModule(module:Module) {

        if (module.create != null) {
            cbs.create.push(module.create);
        }
        if (module.update != null) {
            cbs.update.push(module.update);
        }
        if (module.remove != null) {
            cbs.remove.push(module.remove);
        }
        if (module.destroy != null) {
            cbs.destroy.push(module.destroy);
        }
        if (module.pre != null) {
            cbs.pre.push(module.pre);
        }
        if (module.post != null) {
            cbs.post.push(module.post);
        }

    }

    public function removeModule(module:Module) {

        if (module.create != null) {
            cbs.create.remove(module.create);
        }
        if (module.update != null) {
            cbs.update.remove(module.update);
        }
        if (module.remove != null) {
            cbs.remove.remove(module.remove);
        }
        if (module.destroy != null) {
            cbs.destroy.remove(module.destroy);
        }
        if (module.pre != null) {
            cbs.pre.remove(module.pre);
        }
        if (module.post != null) {
            cbs.post.remove(module.post);
        }

    }

    function createKeyToOldIdx(
        children:Array<VNode>,
        beginIdx:Int,
        endIdx:Int
    ):KeyToIndexMap {

        final map:KeyToIndexMap = {};
        var i = beginIdx;
        while (i <= endIdx) {
            final child = children[i];
            final key = child?.key;
            if (key != null) {
                map.set(key, i);
            }
            i++;
        }
        return map;

    }

    function sameVnode(vnode1:VNode, vnode2:VNode):Bool {

        final isSameKey = vnode1.key == vnode2.key;
        final isSameIs = vnode1.data?.isa == vnode2.data?.isa;
        final isSameSel = vnode1.sel == vnode2.sel;
        final isSameTextOrFragment =
            Is.emptyStringOrNull(vnode1.sel) && vnode1.sel == vnode2.sel
            ? (vnode1.text is String && vnode2.text is String) || (Type.getClass(vnode1.text) == Type.getClass(vnode2.text)) // TODO not sure about that
            : true;

        return isSameSel && isSameKey && isSameIs && isSameTextOrFragment;

    }

    function emptyNodeAt(elm:Element):VNode {

        var elementId = backend.elementId(elm);
        final id = elementId != null && elementId.length > 0 ? "#" + elementId : "";

        // elm.className doesn't return a string when elm is an SVG element inside a shadowRoot.
        // https://stackoverflow.com/questions/29454340/detecting-classname-of-svganimatedstring
        final classes:Null<String> = backend.attribute(elm, "class");

        final c:String = classes != null ? "." + classes.split(" ").join(".") : "";
        return VNode.vnode(
            null,
            backend.tagName(elm).toLowerCase() + id + c,
            {},
            [],
            null,
            backend.elementToNode(elm)
        );

    }

    function createRmCb(childElm:Node, listeners:Int):()->Void {

        return function() {
            if (--listeners == 0) {
                final parent:Null<Node> = backend.parentNode(childElm);
                if (parent != null) {
                    backend.removeChild(parent, childElm);
                }
            }
        };

    }

    function createElm(vnode:VNode, insertedVnodeQueue:VNodeQueue):Node {

        final data = vnode.data;
        final hook = data?.hook;
        final init = hook?.init;
        if (init != null) {
            init(this, vnode);
        }
        final children = vnode.children;
        final sel = vnode.sel;
        if (sel == "!") {
            if (vnode.text == null) vnode.text = "";
            vnode.elm = backend.commentToNode(backend.createComment(vnode.text));
        }
        else if (sel == "") {
            // textNode has no selector
            vnode.elm = backend.textToNode(backend.createTextNode(vnode.text));
        }
        else if (sel != null) {
            // Parse selector
            final hashIdx = sel.indexOf("#");
            final dotIdx = sel.indexOf(".", hashIdx);
            final hash = hashIdx > 0 ? hashIdx : sel.length;
            final dot = dotIdx > 0 ? dotIdx : sel.length;
            final tag =
                hashIdx != -1 || dotIdx != -1
                    ? sel.substring(0, (hash < dot ? hash : dot))
                    : sel;
            final ns = data?.ns;
            final elm =
                ns == null
                    ? backend.createElement(tag, backend.vnodeDataToCreateElementOptions(data))
                    : backend.createElementNS(ns, tag, backend.vnodeDataToCreateElementOptions(data));
            vnode.elm = backend.elementToNode(elm);
            if (hash < dot) backend.setAttribute(elm, "id", sel.substring(hash + 1, dot));
            if (dotIdx > 0)
                backend.setAttribute(elm, "class", sel.substring(dot + 1).replace(".", " "));
            for (i in 0...cbs.create.length) cbs.create[i](this, EMPTY_NODE, vnode);
            if (
                Is.primitive(vnode.text) &&
                (!Is.array(children) || children.length == 0)
            ) {
                // allow h1 and similar nodes to be created w/ text and empty child list
                backend.appendChild(backend.elementToNode(elm), backend.textToNode(backend.createTextNode(vnode.text)));
            }
            if (Is.array(children)) {
                for (i in 0...children.length) {
                    final ch = children[i];
                    if (ch != null) {
                        backend.appendChild(backend.elementToNode(elm), createElm(ch, insertedVnodeQueue));
                    }
                }
            }
            if (hook != null) {
                final create = hook.create;
                if (create != null)
                    create(this, EMPTY_NODE, vnode);
                if (hook.insert != null) {
                    insertedVnodeQueue.push(vnode);
                }
            }
        }
        else {
            vnode.elm = backend.textToNode(backend.createTextNode(vnode.text));
        }

        return vnode.elm;

    }

    function addVnodes(
        parentElm:Node,
        before:Null<Node>,
        vnodes:Array<VNode>,
        startIdx:Int,
        endIdx:Int,
        insertedVnodeQueue:VNodeQueue
    ):Void {

        while (startIdx <= endIdx) {
            final ch = vnodes[startIdx];
            if (ch != null) {
                backend.insertBefore(parentElm, createElm(ch, insertedVnodeQueue), before);
            }
            startIdx++;
        }

    }

    function invokeDestroyHook(vnode:VNode):Void {

        final data = vnode.data;
        if (data != null) {
            final destroy = data?.hook?.destroy;
            if (destroy != null)
                destroy(this, vnode);
            for (i in 0...cbs.destroy.length) cbs.destroy[i](this, vnode);
            if (vnode.children != null) {
                for (j in 0...vnode.children.length) {
                    final child = vnode.children[j];
                    if (child != null && !(child is String)) {
                        invokeDestroyHook(child);
                    }
                }
            }
        }

    }

    function removeVnodes(
        parentElm:Node,
        vnodes:Array<VNode>,
        startIdx:Int,
        endIdx:Int
    ):Void {
        while (startIdx <= endIdx) {
            var listeners:Int = 0;
            final ch = vnodes[startIdx];
            if (ch != null) {
                if (ch.sel != null) {
                    invokeDestroyHook(ch);
                    listeners = cbs.remove.length + 1;
                    final rm = createRmCb(ch.elm, listeners);
                    for (i in 0...cbs.remove.length) cbs.remove[i](this, ch, rm);
                    final removeHook = ch?.data?.hook?.remove;
                    if (removeHook != null) {
                        removeHook(this, ch, rm);
                    } else {
                        rm();
                    }
                }
                else if (ch.children != null && ch.children.length > 0) {
                    // Fragment node
                    invokeDestroyHook(ch);
                    removeVnodes(
                        parentElm,
                        cast ch.children,
                        0,
                        ch.children.length - 1
                    );
                } else {
                    // Text node
                    backend.removeChild(parentElm, ch.elm);
                }
            }
            startIdx++;
        }

    }

    function updateChildren(
        parentElm:Node,
        oldCh:Array<VNode>,
        newCh:Array<VNode>,
        insertedVnodeQueue:VNodeQueue
    ):Void {

        var oldStartIdx:Int = 0;
        var newStartIdx:Int = 0;
        var oldEndIdx:Int = oldCh.length - 1;
        var oldStartVnode:VNode = oldCh[0];
        var oldEndVnode:VNode = oldCh[oldEndIdx];
        var newEndIdx:Int = newCh.length - 1;
        var newStartVnode = newCh[0];
        var newEndVnode = newCh[newEndIdx];
        var oldKeyToIdx:Null<KeyToIndexMap> = null;
        var idxInOld:Int;
        var elmToMove:VNode = null;
        var before:Any;

        while (oldStartIdx <= oldEndIdx && newStartIdx <= newEndIdx) {
            if (oldStartVnode == null) {
                oldStartVnode = oldCh[++oldStartIdx]; // Vnode might have been moved left
            }
            else if (oldEndVnode == null) {
                oldEndVnode = oldCh[--oldEndIdx];
            }
            else if (newStartVnode == null) {
                newStartVnode = newCh[++newStartIdx];
            }
            else if (newEndVnode == null) {
                newEndVnode = newCh[--newEndIdx];
            }
            else if (sameVnode(oldStartVnode, newStartVnode)) {
                patchVnode(oldStartVnode, newStartVnode, insertedVnodeQueue);
                oldStartVnode = oldCh[++oldStartIdx];
                newStartVnode = newCh[++newStartIdx];
            }
            else if (sameVnode(oldEndVnode, newEndVnode)) {
                patchVnode(oldEndVnode, newEndVnode, insertedVnodeQueue);
                oldEndVnode = oldCh[--oldEndIdx];
                newEndVnode = newCh[--newEndIdx];
            }
            else if (sameVnode(oldStartVnode, newEndVnode)) {
                // Vnode moved right
                patchVnode(oldStartVnode, newEndVnode, insertedVnodeQueue);
                backend.insertBefore(
                    parentElm,
                    oldStartVnode.elm,
                    backend.nextSibling(oldEndVnode.elm)
                );
                oldStartVnode = oldCh[++oldStartIdx];
                newEndVnode = newCh[--newEndIdx];
            }
            else if (sameVnode(oldEndVnode, newStartVnode)) {
                // Vnode moved left
                patchVnode(oldEndVnode, newStartVnode, insertedVnodeQueue);
                backend.insertBefore(parentElm, oldEndVnode.elm, oldStartVnode.elm);
                oldEndVnode = oldCh[--oldEndIdx];
                newStartVnode = newCh[++newStartIdx];
            }
            else {
                if (oldKeyToIdx == null) {
                    oldKeyToIdx = createKeyToOldIdx(oldCh, oldStartIdx, oldEndIdx);
                }
                idxInOld = oldKeyToIdx.get(newStartVnode.key);
                if (idxInOld == null) {
                    // `newStartVnode` is new, create and insert it in beginning
                    backend.insertBefore(
                        parentElm,
                        createElm(newStartVnode, insertedVnodeQueue),
                        oldStartVnode.elm
                    );
                    newStartVnode = newCh[++newStartIdx];
                }
                else if (oldKeyToIdx.get(newEndVnode.key) == null) {
                    // `newEndVnode` is new, create and insert it in the end
                    backend.insertBefore(
                        parentElm,
                        createElm(newEndVnode, insertedVnodeQueue),
                        backend.nextSibling(oldEndVnode.elm)
                    );
                    newEndVnode = newCh[--newEndIdx];
                }
                else {
                    // Neither of the new endpoints are new vnodes, so we make progress by
                    // moving `newStartVnode` into position
                    elmToMove = oldCh[idxInOld];
                    if (elmToMove.sel != newStartVnode.sel) {
                        backend.insertBefore(
                            parentElm,
                            createElm(newStartVnode, insertedVnodeQueue),
                            oldStartVnode.elm
                        );
                    }
                    else {
                        patchVnode(elmToMove, newStartVnode, insertedVnodeQueue);
                        oldCh[idxInOld] = null;
                        backend.insertBefore(parentElm, elmToMove.elm, oldStartVnode.elm);
                    }
                    newStartVnode = newCh[++newStartIdx];
                }
            }
        }

        if (newStartIdx <= newEndIdx) {
            before = newCh[newEndIdx + 1] == null ? null : newCh[newEndIdx + 1].elm;
            addVnodes(
                parentElm,
                before,
                newCh,
                newStartIdx,
                newEndIdx,
                insertedVnodeQueue
            );
        }
        if (oldStartIdx <= oldEndIdx) {
            removeVnodes(parentElm, oldCh, oldStartIdx, oldEndIdx);
        }
    }

    function patchVnode(
        oldVnode:VNode,
        vnode:VNode,
        insertedVnodeQueue:VNodeQueue
    ):Void {

        final hook = vnode.data?.hook;
        final prepatch = hook?.prepatch;
        if (prepatch != null)
            prepatch(this, oldVnode, vnode);
        vnode.elm = oldVnode.elm;
        final elm = vnode.elm;
        if (oldVnode == vnode) return;
        if (
            vnode.data != null ||
            (vnode.text != null && vnode.text != oldVnode.text)
        ) {
            if (vnode.data == null) vnode.data = {};
            if (oldVnode.data == null) oldVnode.data = {};
            for (i in 0...cbs.update.length)
                cbs.update[i](this, oldVnode, vnode);
            final update = vnode.data?.hook?.update;
            if (update != null)
                update(this, oldVnode, vnode);
        }
        final oldCh:Array<VNode> = cast oldVnode.children;
        final ch:Array<VNode> = cast vnode.children;
        if (vnode.text == null) {
            if (oldCh != null && ch != null) {
                if (oldCh != ch) updateChildren(elm, oldCh, ch, insertedVnodeQueue);
            }
            else if (ch != null) {
                if (oldVnode.text != null) backend.setTextContent(elm, "");
                addVnodes(elm, null, ch, 0, ch.length - 1, insertedVnodeQueue);
            }
            else if (oldCh != null) {
                removeVnodes(elm, oldCh, 0, oldCh.length - 1);
            }
            else if (oldVnode.text != null) {
                backend.setTextContent(elm, "");
            }
        }
        else if (oldVnode.text != vnode.text) {
            if (oldCh != null) {
                removeVnodes(elm, oldCh, 0, oldCh.length - 1);
            }
            backend.setTextContent(elm, vnode.text);
        }
        final postpatch = hook?.postpatch;
        if (postpatch != null)
            postpatch(this, oldVnode, vnode);

    }

    #if completion

    public function patch(
        oldVnode:Any,
        vnode:Any
    ):VNode {
        return null;
    }

    #else

    #if markup_html

    public extern inline overload function patch(
        oldVnode:js.html.Element,
        vnode:VNode
    ):VNode {
        return _patch(oldVnode, vnode);
    }

    #end

    public extern inline overload function patch(
        oldVnode:VNode,
        vnode:VNode
    ):VNode {
        return _patch(oldVnode, vnode);
    }

    public extern inline overload function patch(
        oldVnode:Element,
        vnode:VNode
    ):VNode {
        return _patch(oldVnode, vnode);
    }

    public extern inline overload function patch(
        oldVnode:Any,
        vnode:VNode
    ):VNode {
        return _patch(oldVnode, vnode);
    }

    function _patch(
        oldVnodeRaw:Any,
        vnode:VNode
    ):VNode {

        var oldVnode:VNode;
        var elm:Node;
        var parent:Node;

        final insertedVnodeQueue:VNodeQueue = [];
        for (i in 0...cbs.pre.length) cbs.pre[i](this);

        if (backend.isElement(oldVnodeRaw)) {
            oldVnode = emptyNodeAt(oldVnodeRaw);
        }
        else {
            oldVnode = oldVnodeRaw;
        }

        if (sameVnode(oldVnode, vnode)) {
            patchVnode(oldVnode, vnode, insertedVnodeQueue);
        }
        else {
            elm = oldVnode.elm;
            parent = backend.parentNode(elm);

            createElm(vnode, insertedVnodeQueue);

            if (parent != null) {
                backend.insertBefore(parent, vnode.elm, backend.nextSibling(elm));
                removeVnodes(parent, [oldVnode], 0, 0);
            }
        }

        for (i in 0...insertedVnodeQueue.length) {
            insertedVnodeQueue[i].data.hook.insert(this, insertedVnodeQueue[i]);
        }
        for (i in 0...cbs.post.length) cbs.post[i](this);

        return vnode;

    }

    #end

    static var iteratorStack:Array<Array<Int>> = [];

    static var currentIterator:Array<Int> = null;

    static var iteratorKeysStack:Array<Array<String>> = [];

    static var currentIteratorKeys:Array<String> = null;

    public static function begin():Void {

        currentIterator = [];
        currentIteratorKeys = [];
        iteratorStack.push(currentIterator);
        iteratorKeysStack.push(currentIteratorKeys);

    }

    public static function end():Void {

        iteratorStack.pop();
        iteratorKeysStack.pop();
        final len = iteratorStack.length;
        if (len > 0) {
            currentIterator = iteratorStack[len-1];
            currentIteratorKeys = iteratorKeysStack[len-1];
        }
        else {
            currentIterator = null;
            currentIteratorKeys = null;
        }

    }

    public static function iPush():Void {

        currentIterator.push(-1);
        currentIteratorKeys.push(null);

    }

    public static function iIter():Int {

        final index = currentIterator.length - 1;
        final n = currentIterator[index];
        final i = (n + 1);
        currentIterator[index] = i;
        currentIteratorKeys[index] = null;
        return i;

    }

    public static function iKey(key:String):Void {

        final index = currentIteratorKeys.length - 1;
        currentIteratorKeys[index] = key;

    }

    public static function iStr(index:Int):String {

        var key = currentIteratorKeys[index];
        return key ?? '#'+currentIterator[index];

    }

    public static function iPop():Void {

        currentIterator.pop();
        currentIteratorKeys.pop();

    }

    #if completion

    public static function c(xid:Xid, comp:Any, ?b:Any, ?c:Any):Any {

        return null;
    }

    #else

    public static function c(xid:Xid, comp:Any, ?b:Any, ?c:Any):Any {

        var data:VNodeData = null;
        var children:Any = null;
        var text:Any = null;

        if (c != null) {

            if (b != null) {
                data = b;
            }

            if (Is.array(c)) {
                children = c;
            }
            else if (Is.primitive(c)) {
                text = Std.string(c);
            }
            else if (c != null && (c is VNodeData || c is VNode)) {
                children = [c];
            }
        }
        else if (b != null) {
            if (Is.array(b)) {
                children = b;
            }
            else if (Is.primitive(b)) {
                text = Std.string(b);
            }
            else {
                data = b;
            }
        }

        if ((children == null || (children:Array<Any>).length == 0) && text != null) {
            children = [
                VNode.vnode(
                    null,
                    null,
                    null,
                    null,
                    text,
                    null
                )
            ];
        }
        else if (children != null) {
            children = cleanChildren(children);
            final childrenArray:Array<Any> = children;
            for (i in 0...childrenArray.length) {
                if (Is.primitive(childrenArray[i]))
                    childrenArray[i] = VNode.vnode(
                        null,
                        null,
                        null,
                        null,
                        childrenArray[i],
                        null
                    );
            }
        }

        var computedXid = xid;
        if (baseXid != null) {
            computedXid = baseXid + xid;
        }

        if (renderComponent != null) {
            return renderComponent(comp, computedXid, data, children);
        }
        else {
            final _comp:(xid:Xid, ctx:ReactiveContext, data:VNodeData, children:Array<VNode>)->Any = comp;
            return _comp(computedXid, null, data, children);
        }
    }

    #end

    public extern inline static overload function h(xid:Xid, sel:Any, ?b:Any, ?c:Any):Any {
        return _h(xid, sel, b, c);
    }

    static function _h(xid:Xid, sel:Any, ?b:Any, ?c:Any):Any {

        var data:VNodeData = null;
        var children:Any = null;
        var text:Any = null;
        if (c != null) {
            if (b != null) {
                data = b;
            }
            if (Is.array(c)) {
                children = c;
            }
            else if (Is.primitive(c)) {
                text = Std.string(c);
            }
            else if (c != null && (c is VNodeData || c is VNode)) {
                children = [c];
            }
        }
        else if (b != null) {
            if (Is.array(b)) {
                children = b;
            }
            else if (Is.primitive(b)) {
                text = Std.string(b);
            }
            // else if (b is VNodeData || b is VNode) {
            //     children = [b];
            // }
            else {
                data = b;
            }
        }
        if (data == null) {
            data = {};
        }
        if (children != null) {
            children = cleanChildren(children);
            final childrenArray:Array<Any> = children;
            for (i in 0...childrenArray.length) {
                if (Is.primitive(childrenArray[i]))
                    childrenArray[i] = VNode.vnode(
                        null,
                        null,
                        null,
                        null,
                        childrenArray[i],
                        null
                    );
            }
        }

        if (
            (sel:String).startsWith("svg") &&
            ((sel:String).length == 3 || (sel:String).charCodeAt(3) == '.'.code || (sel:String).charCodeAt(3) == '#'.code)
        ) {
            addNS(data, children, sel, SVG_NS);
        }

        var computedXid = xid;
        if (baseXid != null) {
            computedXid = baseXid + xid;
        }

        return VNode.vnode(computedXid, sel, data, children, text, null);

    }

    static function cleanChildren(arr:Array<Any>):Array<Any> {

        // First pass: check if cleaning is needed
        var needsCleanup = false;
        for (i in 0...arr.length) {
            final item = arr[i];
            if (item == null || item is Array) {
                needsCleanup = true;
                break;
            }
        }

        // If no cleaning needed, return original array
        if (!needsCleanup) {
            return cast arr;
        }

        // Second pass: perform cleanup
        var result = [];
        for (i in 0...arr.length) {
            var item = arr[i];
            if (item == null) {
                // Skip null items
            }
            else if (item is Array) {
                item = cleanChildren(item);
                var subArray:Array<Any> = cast item;
                for (j in 0...subArray.length) {
                    result.push(subArray[j]);
                }
            }
            else {
                result.push(item);
            }
        }

        return cast result;

    }

    static function addNS(
        data:VNodeData,
        children:Null<Array<Any>>,
        sel:Null<String>,
        ns:String
    ):Void {

        data.ns = ns;

        if (sel != "foreignObject" && children != null) {
            for (i in 0...children.length) {
                final child = children[i];
                if (!(child is VNode)) continue;
                final childNode:VNode = child;
                final childData = childNode.data;
                if (childData != null) {
                    addNS(childData, childNode.children, childNode.sel, ns);
                }
            }
        }

    }

    public inline static function v(data:VNodeData):VNodeData {

        return data;

    }

    #end

}
