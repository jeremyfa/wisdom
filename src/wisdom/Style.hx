package wisdom;

import haxe.DynamicAccess;

using StringTools;

abstract Style(DynamicAccess<Any>) from DynamicAccess<Any> to DynamicAccess<Any> {

    inline function new(styles:DynamicAccess<Any>) {
        this = styles;
    }

    @:from
    static public function fromDynamic(d:Dynamic) {
        return new Style(d);
    }

    @:from
    static public function fromString(s:String) {

        var styles = new DynamicAccess<Any>();
        if (s == null || s.trim().length == 0) return new Style(styles);

        for (declaration in s.split(";")) {
            var trimmed = declaration.trim();
            if (trimmed.length == 0) continue;

            var colonIndex = trimmed.indexOf(":");
            if (colonIndex == -1) continue;

            var key = trimmed.substring(0, colonIndex).trim();
            var value = trimmed.substring(colonIndex + 1).trim();
            styles.set(key, value);
        }

        return new Style(styles);
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
