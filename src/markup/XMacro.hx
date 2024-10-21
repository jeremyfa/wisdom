package markup;

import haxe.macro.Context;
import haxe.macro.Expr;

using StringTools;

class XMacro {

    macro static public function build():Array<Field> {

        var fields = Context.getBuildFields();

        // TODO

        return fields;

    }

}
