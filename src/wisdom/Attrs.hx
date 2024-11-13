package wisdom;

import haxe.DynamicAccess;

abstract Attrs(DynamicAccess<String>) from DynamicAccess<String> to DynamicAccess<String> {

    inline function new(attrs:DynamicAccess<String>) {
        this = attrs;
    }

    @:from
    static public function fromDynamic(d:Dynamic) {
        return new Attrs(d);
    }

    public inline function exists(key:String):Bool {
        return this.exists(key);
    }

    public inline function get(key:String):Any {
        return this.get(key);
    }

    public inline function set(key:String, value:String):Void {
        this.set(key, value);
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
