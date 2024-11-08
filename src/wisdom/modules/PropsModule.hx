package wisdom.modules;

class PropsModule {

    public static function module():Module {

        return {
            create: updateProps,
            update: updateProps
        };

    }

    static function updateProps(wisdom:Wisdom, oldVnode:VNode, vnode:VNode):Void {

        final elm:Element = cast vnode.elm;

        var oldProps = oldVnode.data.props;
        var props = vnode.data.props;

        if (oldProps == null && props == null) return;
        if (oldProps == props) return;

        if (oldProps != null) {
            for (name => oldVal in oldProps) {

                if (oldVal != null && (props == null || !props.exists(name) || props.get(name) == null) && wisdom.backend.isAttribute(vnode.sel, name)) {
                    wisdom.backend.removeAttribute(elm, name);
                }
            }
        }
        if (props != null) {
            for (name => val in props) {
                if (oldProps == null || oldProps.get(name) != val) {

                    wisdom.backend.setProp(elm, name, val);

                    if (val != null && wisdom.backend.isAttribute(vnode.sel, name)) {
                        wisdom.backend.setAttribute(elm, name, Std.string(val));
                    }
                }
            }
        }

    }

}
