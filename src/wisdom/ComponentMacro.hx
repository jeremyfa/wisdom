package wisdom;

#if macro
import haxe.macro.Compiler;
import haxe.macro.ComplexTypeTools;
import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.ExprTools;
import haxe.macro.PositionTools;

using StringTools;

class ComponentMacro {

    // A flag used to prevent the compiler to perform multiple times
    // expensive operations when an error happens
    static var macroHasErrors:Bool = false;

    static var hasSuperUpdate:Bool = false;

    macro static public function build():Array<Field> {

        var fields = Context.getBuildFields();

        var props:Array<Field> = [];
        var updateField:Field = null;

        for (field in fields) {

            switch field.kind {
                case FVar(t, e):
                    if (hasPropsMeta(field.meta)) {
                        props.push(field);
                    }

                case FProp(get, set, t, e):
                    if (hasPropsMeta(field.meta)) {
                        props.push(field);
                    }

                case FFun(f):
                    if (field.name == 'render') {
                        transformRenderMethod(field);
                    }
                    else if (field.name == 'update') {
                        updateField = field;
                    }

            }

        }

        // Create update field if not there already
        if (updateField == null) {
            updateField = {
                name: 'update',
                pos: Context.currentPos(),
                access: [AOverride],
                kind: FFun({
                    args: [{
                        name: 'xid',
                        type: macro :wisdom_.Xid
                    },
                    {
                        name: 'ctx',
                        type: macro :wisdom_.ReactiveContext
                    },
                    {
                        name: 'data',
                        type: macro :wisdom_.VNodeData
                    },
                    {
                        name: 'children',
                        type: macro :Array<wisdom_.VNode>
                    }],
                    ret: macro :Void,
                    expr: macro {
                        super.update(xid, ctx, data, children);
                    }
                })
            };
            fields.push(updateField);
        }
        else {
            // If there already, ensure it's ready to be modified

            // Ensure expr is surrounded with a block
            switch updateField.kind {
                case FFun(fn):
                    switch (fn.expr.expr) {
                        case EBlock(exprs):
                        default:
                            fn.expr.expr = EBlock([{
                                pos: fn.expr.pos,
                                expr: fn.expr.expr
                            }]);
                    }
                case _:
            }

            switch updateField.kind {
                case FFun(fn):
                    // Check super.update() is called
                    if (!checkSuperUpdate(fn.expr)) {

                        final superUpdateCall = Context.parse(
                            'super.update(' + fn.args[0].name + ', ' + fn.args[1].name + ', ' + fn.args[2].name + ', ' + fn.args[3].name,
                            updateField.pos
                        );

                        // If not, add the call
                        switch (fn.expr.expr) {
                            case EBlock(exprs):
                                fn.expr.expr = EBlock(
                                    [
                                        superUpdateCall
                                    ].concat(exprs)
                                );
                            case _:
                        }
                    }
                case _:
            }

        }

        // Inject props fields assigns in update method
        switch updateField.kind {
            case FFun(fn):

                var assignExprs = [];
                var usedPropNames = new Map<String,Bool>();
                final prefixLen = 'unobserved'.length;

                for (prop in props) {

                    // Ensure it works even if observable macro was processed before
                    var name = prop.name;
                    if (name.startsWith('unobserved')) {
                        name = name.charAt(prefixLen).toLowerCase() + name.substr(prefixLen + 1);
                    }

                    if (!usedPropNames.exists(name)) {
                        usedPropNames.set(name, true);

                        // Didn't process that prop, add assign expr
                        var assignExpr:Expr = switch (name) {
                            case 'children':
                                null;
                            case 'props' | 'attrs' | 'classes' | 'style' | 'on':
                                macro @:pos(updateField.pos) this.$name = this.data.$name;
                            case _:
                                macro @:pos(updateField.pos) this.$name = this.data.props.get($v{name});
                        }

                        if (assignExpr != null) {
                            assignExprs.push(assignExpr);
                        }
                    }
                }

                if (assignExprs.length > 0) {
                    switch (fn.expr.expr) {
                        case EBlock(exprs):
                            fn.expr.expr = EBlock(
                                exprs.concat(assignExprs)
                            );
                        case _:
                    }
                }

            case _:
        }

        return fields;

    }

    /** Replace `super.destroy();`
        with `{ _lifecycleState = -1; super.destroy(); }`
        */
    static function checkSuperUpdate(e:Expr):Bool {

        // This super.destroy() call patch ensures
        // the parent destroy() method will not ignore our call as it would normally do
        // when the object is marked destroyed.

        switch (e.expr) {
            case ECall({expr: EField({expr: EConst(CIdent('super')), pos: _}, 'update'), pos: _}, _):
                hasSuperUpdate = true;
            default:
                ExprTools.iter(e, checkSuperUpdate);
        }

        return hasSuperUpdate;

    }

    static function transformRenderMethod(field:Field) {

        switch field.kind {
            case FVar(t, e):
            case FProp(get, set, t, e):

            case FFun(fn):

                fn.ret = macro :wisdom_.VNode;

                // Add return if needed
                switch (fn.expr.expr) {
                    case EBlock(exprs) if (exprs.length == 1):
                        switch (exprs[0].expr) {
                            case EConst(CString(_, _)):
                                exprs[0].expr = EReturn({
                                    pos: exprs[0].pos,
                                    expr: exprs[0].expr
                                });
                            default:
                        }
                    case EConst(CString(_, _)):
                        fn.expr.expr = EReturn({
                            pos: fn.expr.pos,
                            expr: fn.expr.expr
                        });
                    default:
                }

                // Ensure expr is surrounded with a block
                switch (fn.expr.expr) {
                    case EBlock(exprs):
                    default:
                        fn.expr.expr = EBlock([{
                            pos: fn.expr.pos,
                            expr: fn.expr.expr
                        }]);
                }
        }

    }

    static function hasPropsMeta(meta:Metadata):Bool {

        if (meta == null || meta.length == 0) return false;

        for (meta in meta) {
            if (meta.name == 'props') {
                return true;
            }
        }

        return false;

    }

}

#end
