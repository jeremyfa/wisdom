package markup;

import haxe.DynamicAccess;

abstract Props(DynamicAccess<Any>) from DynamicAccess<Any> to DynamicAccess<Any> {

    inline function new(props:DynamicAccess<Any>) {
        this = props;
    }

    @:from
    static public function fromDynamic(d:Dynamic) {
        return new Props(d);
    }

    public inline function exists(props:String):Bool {
        return this.exists(props);
    }

    public inline function get(props:String):Any {
        return this.get(props);
    }

    public inline function set(props:String, value:String):Void {
        this.set(props, value);
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
