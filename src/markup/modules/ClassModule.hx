package markup.modules;

class ClassModule {

    public static function module():Module {

        return {
            create: updateClass,
            update: updateClass
        };

    }

    static function updateClass(markup:Markup, oldVnode:VNode, vnode:VNode):Void {

        final elm:Element = cast vnode.elm;

        var oldClass = oldVnode.data.classes;
        var klass = vnode.data.classes;

        if (oldClass == null && klass == null) return;
        if (oldClass == klass) return;

        if (oldClass != null) {
            for (name in oldClass.toArray()) {
                if (klass == null || !klass.contains(name)) {
                    // was `true` and now not provided
                    markup.backend.removeClass(elm, name);
                }
            }
        }

        if (klass != null) {
            for (name in klass.toArray()) {
                if (oldClass == null || !oldClass.contains(name)) {
                    markup.backend.addClass(elm, name);
                }
            }
        }

    }

}
