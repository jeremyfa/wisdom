package wisdom;

import wisdom.Hooks;

class ModuleHooks {

    public final create:Array<CreateHook> = [];

    public final update:Array<UpdateHook> = [];

    public final remove:Array<RemoveHook> = [];

    public final destroy:Array<DestroyHook> = [];

    public final pre:Array<PreHook> = [];

    public final post:Array<PostHook> = [];

    public function new() {}

}