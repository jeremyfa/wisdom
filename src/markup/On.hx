package markup;

import haxe.Constraints.Function;
import haxe.DynamicAccess;

abstract On(DynamicAccess<Function>) from DynamicAccess<Function> to DynamicAccess<Function> {

    inline function new(on:DynamicAccess<Function>) {
        this = on;
    }

    @:from
    static public function fromDynamic(d:Dynamic) {
        return new On(d);
    }

    public inline function exists(event:String):Bool {
        return this.exists(event);
    }

    public inline function get(event:String):Any {
        return this.get(event);
    }

    public inline function set(event:String, listener:Function):Void {
        this.set(event, listener);
    }

    public inline function keys() {
        return this.keys();
    }

    public inline function iterator() {
        return this.iterator();
    }

    public inline function keyValueIterator() {
        return this.keyValueIterator();
    }

}
