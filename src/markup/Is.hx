package markup;

class Is {

    public inline static function primitive(value:Any):Bool {
        return (value is String) || (value is Int) || (value is Float);
    }

    public inline static function array(value:Any):Bool {
        return value is Array;
    }

    public inline static function emptyStringOrNull(value:String):Bool {
        return value == null || value.length == 0;
    }

}