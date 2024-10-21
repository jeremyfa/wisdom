package markup;

using StringTools;

class Markup {

    static final EMPTY_NODE = VNode.vnode("", {}, [], null, null);

    static final SVG_NS = "http://www.w3.org/2000/svg";

    final cbs = new ModuleHooks();

    public var api(default, null):DomApi;

    public function new(modules:Array<Module>, api:DomApi) {

        this.api = api;

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

        var elementId = api.elementId(elm);
        final id = elementId != null && elementId.length > 0 ? "#" + elementId : "";

        // elm.className doesn't return a string when elm is an SVG element inside a shadowRoot.
        // https://stackoverflow.com/questions/29454340/detecting-classname-of-svganimatedstring
        final classes:Null<String> = api.elementAttribute(elm, "class");

        final c:String = classes != null ? "." + classes.split(" ").join(".") : "";
        return VNode.vnode(
            api.tagName(elm).toLowerCase() + id + c,
            {},
            [],
            null,
            api.elementToNode(elm)
        );

    }

    function createRmCb(childElm:Node, listeners:Int):()->Void {

        return function() {
            if (--listeners == 0) {
                final parent:Null<Node> = api.parentNode(childElm);
                if (parent != null) {
                    api.removeChild(parent, childElm);
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
            vnode.elm = api.commentToNode(api.createComment(vnode.text));
        }
        else if (sel == "") {
            // textNode has no selector
            vnode.elm = api.textToNode(api.createTextNode(vnode.text));
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
                    ? api.createElement(tag, api.vnodeDataToCreateElementOptions(data))
                    : api.createElementNS(ns, tag, api.vnodeDataToCreateElementOptions(data));
            vnode.elm = api.elementToNode(elm);
            if (hash < dot) api.elementSetAttribute(elm, "id", sel.substring(hash + 1, dot));
            if (dotIdx > 0)
                api.elementSetAttribute(elm, "class", sel.substring(dot + 1).replace(".", " "));
            for (i in 0...cbs.create.length) cbs.create[i](this, EMPTY_NODE, vnode);
            if (
                Is.primitive(vnode.text) &&
                (!Is.array(children) || children.length == 0)
            ) {
                // allow h1 and similar nodes to be created w/ text and empty child list
                api.appendChild(api.elementToNode(elm), api.textToNode(api.createTextNode(vnode.text)));
            }
            if (Is.array(children)) {
                for (i in 0...children.length) {
                    final ch = children[i];
                    if (ch != null) {
                        api.appendChild(api.elementToNode(elm), createElm(ch, insertedVnodeQueue));
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
            vnode.elm = api.textToNode(api.createTextNode(vnode.text));
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
                api.insertBefore(parentElm, createElm(ch, insertedVnodeQueue), before);
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
                    api.removeChild(parentElm, ch.elm);
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
                api.insertBefore(
                    parentElm,
                    oldStartVnode.elm,
                    api.nextSibling(oldEndVnode.elm)
                );
                oldStartVnode = oldCh[++oldStartIdx];
                newEndVnode = newCh[--newEndIdx];
            }
            else if (sameVnode(oldEndVnode, newStartVnode)) {
                // Vnode moved left
                patchVnode(oldEndVnode, newStartVnode, insertedVnodeQueue);
                api.insertBefore(parentElm, oldEndVnode.elm, oldStartVnode.elm);
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
                    api.insertBefore(
                        parentElm,
                        createElm(newStartVnode, insertedVnodeQueue),
                        oldStartVnode.elm
                    );
                    newStartVnode = newCh[++newStartIdx];
                }
                else if (oldKeyToIdx.get(newEndVnode.key) == null) {
                    // `newEndVnode` is new, create and insert it in the end
                    api.insertBefore(
                        parentElm,
                        createElm(newEndVnode, insertedVnodeQueue),
                        api.nextSibling(oldEndVnode.elm)
                    );
                    newEndVnode = newCh[--newEndIdx];
                }
                else {
                    // Neither of the new endpoints are new vnodes, so we make progress by
                    // moving `newStartVnode` into position
                    elmToMove = oldCh[idxInOld];
                    if (elmToMove.sel != newStartVnode.sel) {
                        api.insertBefore(
                            parentElm,
                            createElm(newStartVnode, insertedVnodeQueue),
                            oldStartVnode.elm
                        );
                    }
                    else {
                        patchVnode(elmToMove, newStartVnode, insertedVnodeQueue);
                        oldCh[idxInOld] = null;
                        api.insertBefore(parentElm, elmToMove.elm, oldStartVnode.elm);
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
                if (oldVnode.text != null) api.setTextContent(elm, "");
                addVnodes(elm, null, ch, 0, ch.length - 1, insertedVnodeQueue);
            }
            else if (oldCh != null) {
                removeVnodes(elm, oldCh, 0, oldCh.length - 1);
            }
            else if (oldVnode.text != null) {
                api.setTextContent(elm, "");
            }
        }
        else if (oldVnode.text != vnode.text) {
            if (oldCh != null) {
                removeVnodes(elm, oldCh, 0, oldCh.length - 1);
            }
            api.setTextContent(elm, vnode.text);
        }
        final postpatch = hook?.postpatch;
        if (postpatch != null)
            postpatch(this, oldVnode, vnode);

    }

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

        if (api.isElement(oldVnodeRaw)) {
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
            parent = api.parentNode(elm);

            createElm(vnode, insertedVnodeQueue);

            if (parent != null) {
                api.insertBefore(parent, vnode.elm, api.nextSibling(elm));
                removeVnodes(parent, [oldVnode], 0, 0);
            }
        }

        for (i in 0...insertedVnodeQueue.length) {
            insertedVnodeQueue[i].data.hook.insert(this, insertedVnodeQueue[i]);
        }
        for (i in 0...cbs.post.length) cbs.post[i](this);

        return vnode;

    }

    public extern inline static overload function h(sel:Any, ?b:Any, ?c:Any):VNode {
        return _h(sel, b, c);
    }

    static function _h(sel:Any, ?b:Any, ?c:Any):VNode {

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
            else if (c != null && c is VNodeData) {
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
            else if (b is VNodeData || b is VNode) {
                children = [b];
            }
            else {
                data = b;
            }
        }
        if (data == null) {
            data = {};
        }
        if (children != null) {
            final childrenArray:Array<Any> = children;
            for (i in 0...childrenArray.length) {
                if (Is.primitive(childrenArray[i]))
                    childrenArray[i] = VNode.vnode(
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

        return VNode.vnode(sel, data, children, text, null);

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

}
