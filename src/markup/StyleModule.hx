package markup;

class StyleModule {

    public static function module():Module {

        return {
            create: updateStyle,
            update: updateStyle
        };

    }

    static function updateStyle(markup:Markup, oldVnode:VNode, vnode:VNode):Void {

        final elm:Element = cast vnode.elm;

        var oldStyle = oldVnode.data.style;
        var style = vnode.data.style;

        if (oldStyle == null && style == null) return;
        if (oldStyle == style) return;

        if (oldStyle != null) {
            for (name in oldStyle.keys()) {
                if (style == null || !style.exists(name)) {
                    markup.api.removeStyle(elm, name);
                }
            }
        }
        if (style != null) {
            for (name => value in style) {
                if (oldStyle == null || !oldStyle.exists(name) || oldStyle.get(name) != value) {
                    markup.api.setStyle(elm, name, value);
                }
            }
        }

    }

}
