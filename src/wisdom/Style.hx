package wisdom;

import haxe.DynamicAccess;

abstract Style(DynamicAccess<Any>) from DynamicAccess<Any> to DynamicAccess<Any> {

    inline function new(styles:DynamicAccess<Any>) {
        this = styles;
    }

    @:from
    static public function fromDynamic(d:Dynamic) {
        return new Style(d);
    }

    public inline function exists(style:String):Bool {
        return this.exists(style);
    }

    public inline function get(style:String):Any {
        return this.get(style);
    }

    public inline function set(style:String, value:String):Void {
        this.set(style, value);
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
