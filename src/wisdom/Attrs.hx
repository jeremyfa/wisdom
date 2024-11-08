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

    public inline function exists(attrs:String):Bool {
        return this.exists(attrs);
    }

    public inline function get(attrs:String):Any {
        return this.get(attrs);
    }

    public inline function set(attrs:String, value:String):Void {
        this.set(attrs, value);
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
