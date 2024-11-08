package wisdom;

#if tracker

import haxe.DynamicAccess;
import wisdom.ObservableValue;

abstract State(DynamicAccess<ObservableValue>) from DynamicAccess<ObservableValue> to DynamicAccess<ObservableValue> {

    inline function new(state:DynamicAccess<ObservableValue>) {
        this = state;
    }

    @:from
    static public function fromDynamic(d:Dynamic) {
        var res:DynamicAccess<ObservableValue> = {};
        for (field in Reflect.fields(d)) {
            var val = Reflect.field(d, field);
            if (val is ObservableValue) {
                res.set(field, val);
            }
            else {
                res.set(field, new ObservableValue(val));
            }
        }
        return new State(res);
    }

    public inline function exists(key:String):Bool {
        return this.exists(key);
    }

    public function get(key:String):Any {
        if (!this.exists(key)) {
            this.set(key, new ObservableValue(null));
        }
        return this.get(key).value;
    }

    public function getUnobserved(key:String):Any {
        return @:privateAccess this.get(key)?.unobservedValue;
    }

    public function set(key:String, value:Any):Any {
        if (!this.exists(key)) {
            this.set(key, new ObservableValue(value));
        }
        else {
            this.get(key).value = value;
        }
        return value;
    }

    public function getAndSet(key:String, value:Any):Any {
        final prevValue = get(key);
        set(key, value);
        return prevValue;
    }

    public function getUnobservedAndSet(key:String, value:Any):Any {
        final prevValue = getUnobserved(key);
        set(key, value);
        return prevValue;
    }

    public inline function keys() {
        return this.keys();
    }

}

#end
