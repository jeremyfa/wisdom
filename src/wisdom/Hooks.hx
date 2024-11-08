package wisdom;

typedef PreHook = (wisdom: Wisdom) -> Void;
typedef InitHook = (wisdom: Wisdom, vNode: VNode) -> Void;
typedef CreateHook = (wisdom: Wisdom, emptyVNode: VNode, vNode: VNode) -> Void;
typedef InsertHook = (wisdom: Wisdom, vNode: VNode) -> Void;
typedef PrePatchHook = (wisdom: Wisdom, oldVNode: VNode, vNode: VNode) -> Void;
typedef UpdateHook = (wisdom: Wisdom, oldVNode: VNode, vNode: VNode) -> Void;
typedef PostPatchHook = (wisdom: Wisdom, oldVNode: VNode, vNode: VNode) -> Void;
typedef DestroyHook = (wisdom: Wisdom, vNode: VNode) -> Void;
typedef RemoveHook = (wisdom: Wisdom, vNode: VNode, removeCallback: () -> Void) -> Void;
typedef PostHook = (wisdom: Wisdom) -> Void;

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