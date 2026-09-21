package wisdom;

@:structInit
class VNodeData {
    public var props:VNodeProps = null;
    public var attrs:Attrs = null;
    public var classes:Classes = null;
    public var style:Style = null;
    public var on:On = null;
    public var attachData:AttachData = null;
    public var hook:Hooks = null;
    public var key:Key = null;
    public var ns:String = null; // for SVGs
    public var isa:String = null; // for custom elements v1
    /** When true, Wisdom creates and updates this element (classes, style, attributes,
        listeners) but never creates, diffs or removes its DOM children: a third party owns
        the inside. Such a vnode must have no children and no text. */
    public var unmanaged:Bool = false;
    /** Host element for a `portal` vnode (sel == "portal"): the children are rendered in
        this element instead of the vnode's own position. Backend element type
        (js.html.Element with HtmlBackend). */
    public var portal:Any = null;
    /** Called with the element once it is attached (end of the patch that created it), and
        with null when the vnode is destroyed. Element-lifetime semantics: changing the
        callback between renders does not call anything. */
    public var ref:(elm:Any)->Void = null;
}
