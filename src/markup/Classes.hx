package markup;

using StringTools;

abstract Classes(Array<String>) from Array<String> to Array<String> {

    inline function new(classes:Array<String>) {
        this = classes;
    }

    @:from
    static public function fromString(s:String) {
        var classes = [];
        for (c in s.split(' ')) {
            c = c.trim();
            if (c.length > 0) {
                classes.push(c);
            }
        }
        return new Classes(classes);
    }

    @:to
    public function toArray():Array<String> {
        return this;
    }

    public function contains(klass:String):Bool {
        return this.contains(klass);
    }

}
