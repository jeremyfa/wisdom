package wisdom.modules;

class AttributesModule {

    public static function module():Module {

        return {
            create: updateAttributes,
            update: updateAttributes
        };

    }

    static function updateAttributes(wisdom:Wisdom, oldVnode:VNode, vnode:VNode):Void {

        final elm:Element = cast vnode.elm;

        var oldAttributes = oldVnode.data.attrs;
        var attributes = vnode.data.attrs;

        if (oldAttributes != null) {
            for (name => oldVal in oldAttributes) {
                if (oldVal != null && (attributes == null || !attributes.exists(name) || attributes.get(name) == null)) {
                    wisdom.backend.removeAttribute(elm, name);
                }
            }
        }
        if (attributes != null) {
            for (name => value in attributes) {
                if (value != null && (oldAttributes == null || !oldAttributes.exists(name) || oldAttributes.get(name) != value)) {
                    wisdom.backend.setAttribute(elm, name, value);
                }
            }
        }

    }

}
