package markup;

import markup.Hooks;

@:structInit
class Module {

    public var pre:PreHook = null;

    public var create:CreateHook = null;

    public var update:UpdateHook = null;

    public var destroy:DestroyHook = null;

    public var remove:RemoveHook = null;

    public var post:PostHook = null;

}
