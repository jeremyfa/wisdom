package markup;

typedef PreHook = (markup: Markup) -> Void;
typedef InitHook = (markup: Markup, vNode: VNode) -> Void;
typedef CreateHook = (markup: Markup, emptyVNode: VNode, vNode: VNode) -> Void;
typedef InsertHook = (markup: Markup, vNode: VNode) -> Void;
typedef PrePatchHook = (markup: Markup, oldVNode: VNode, vNode: VNode) -> Void;
typedef UpdateHook = (markup: Markup, oldVNode: VNode, vNode: VNode) -> Void;
typedef PostPatchHook = (markup: Markup, oldVNode: VNode, vNode: VNode) -> Void;
typedef DestroyHook = (markup: Markup, vNode: VNode) -> Void;
typedef RemoveHook = (markup: Markup, vNode: VNode, removeCallback: () -> Void) -> Void;
typedef PostHook = (markup: Markup) -> Void;

@:structInit
class Hooks {
    public var pre: PreHook = null;
    public var init: InitHook = null;
    public var create: CreateHook = null;
    public var insert: InsertHook = null;
    public var prepatch: PrePatchHook = null;
    public var update: UpdateHook = null;
    public var postpatch: PostPatchHook = null;
    public var destroy: DestroyHook = null;
    public var remove: RemoveHook = null;
    public var post: PostHook = null;
}