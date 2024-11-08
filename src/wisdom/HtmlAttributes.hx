package wisdom;

using StringTools;

class HtmlAttributes {

    // Attribute groups as bit flags
    private static inline var NONE = 0;
    private static inline var HALIGN = 1;      // horizontal alignment only
    private static inline var VALIGN = 2;      // vertical alignment only
    private static inline var DIMS = 4;
    private static inline var MEDIA = 8;
    private static inline var FORM = 16;
    private static inline var SRC = 32;
    private static inline var HREF = 64;
    private static inline var META = 128;
    private static inline var TABLE = 256;
    private static inline var INTERACT = 512;

    // Common attribute combinations
    private static inline var MEDIA_DIMS = MEDIA | DIMS;
    private static inline var FORM_INTERACT = FORM | INTERACT;
    private static inline var FULL_ALIGN = HALIGN | VALIGN;

    // Quick lookup maps for elements and their allowed attribute groups
    private static final elementGroups:Map<String, Int> = [
        "a" => HREF | MEDIA | INTERACT,
        "abbr" => NONE,
        "address" => NONE,
        "area" => HREF | MEDIA | DIMS,
        "article" => NONE,
        "aside" => NONE,
        "audio" => MEDIA | SRC,
        "b" => NONE,
        "base" => HREF,
        "bdi" => NONE,
        "bdo" => NONE,
        "blockquote" => NONE,
        "button" => FORM_INTERACT,
        "canvas" => DIMS,
        "caption" => HALIGN,
        "cite" => NONE,
        "code" => NONE,
        "col" => DIMS | FULL_ALIGN,
        "colgroup" => DIMS,
        "data" => NONE,
        "datalist" => NONE,
        "dd" => NONE,
        "del" => NONE,
        "details" => INTERACT,
        "dfn" => NONE,
        "dialog" => INTERACT,
        "div" => HALIGN,
        "dl" => NONE,
        "dt" => NONE,
        "em" => NONE,
        "embed" => SRC | DIMS | MEDIA,
        "fieldset" => FORM,
        "figcaption" => NONE,
        "figure" => NONE,
        "footer" => NONE,
        "form" => FORM | META,
        "h1" => HALIGN, "h2" => HALIGN, "h3" => HALIGN,
        "h4" => HALIGN, "h5" => HALIGN, "h6" => HALIGN,
        "header" => NONE,
        "hgroup" => NONE,
        "hr" => DIMS | HALIGN,
        "i" => NONE,
        "iframe" => SRC | DIMS | MEDIA,
        "img" => SRC | DIMS | MEDIA,
        "input" => FORM_INTERACT | DIMS | MEDIA,
        "ins" => NONE,
        "kbd" => NONE,
        "label" => FORM,
        "legend" => HALIGN,
        "li" => NONE,
        "link" => HREF | MEDIA | META,
        "main" => NONE,
        "map" => NONE,
        "mark" => NONE,
        "menu" => NONE,
        "meta" => META,
        "meter" => FORM,
        "nav" => NONE,
        "noscript" => NONE,
        "object" => DIMS | MEDIA | FORM,
        "ol" => NONE,
        "optgroup" => FORM,
        "option" => FORM,
        "output" => FORM,
        "p" => HALIGN,
        "picture" => NONE,
        "pre" => NONE,
        "progress" => FORM,
        "q" => NONE,
        "rp" => NONE,
        "rt" => NONE,
        "ruby" => NONE,
        "s" => NONE,
        "samp" => NONE,
        "script" => SRC | META,
        "section" => NONE,
        "select" => FORM_INTERACT,
        "slot" => NONE,
        "small" => NONE,
        "source" => SRC | MEDIA | DIMS,
        "span" => NONE,
        "strong" => NONE,
        "style" => MEDIA | META,
        "sub" => NONE,
        "summary" => NONE,
        "sup" => NONE,
        "table" => TABLE | DIMS | FULL_ALIGN,
        "tbody" => FULL_ALIGN,
        "td" => TABLE | DIMS | FULL_ALIGN,
        "template" => NONE,
        "textarea" => FORM_INTERACT,
        "tfoot" => FULL_ALIGN,
        "th" => TABLE | DIMS | FULL_ALIGN,
        "thead" => FULL_ALIGN,
        "time" => NONE,
        "tr" => FULL_ALIGN,
        "track" => SRC | META,
        "u" => NONE,
        "ul" => NONE,
        "var" => NONE,
        "video" => SRC | DIMS | MEDIA,
        "wbr" => NONE
    ];

    // Global attributes (most common ones)
    private static final globalAttrs = [
        "class" => true, "id" => true, "style" => true, "title" => true,
        "lang" => true, "dir" => true, "tabindex" => true, "hidden" => true
    ];

    // Group-specific attributes
    private static final groupAttrs:Map<Int, Array<String>> = [
        HALIGN => ["align"],
        VALIGN => ["valign"],
        DIMS => ["width", "height", "size"],
        MEDIA => ["crossorigin", "preload", "autoplay", "loop", "controls", "muted"],
        FORM => ["name", "value", "type", "disabled", "required", "readonly", "placeholder", "autocomplete", "autofocus", "form", "maxlength", "minlength", "pattern"],
        SRC => ["src", "srcset", "alt", "loading"],
        HREF => ["href", "target", "rel", "download", "hreflang", "referrerpolicy"],
        META => ["content", "charset", "name", "http-equiv", "scheme"],
        TABLE => ["colspan", "rowspan", "headers", "scope"],
        INTERACT => ["checked", "selected", "multiple", "open"]
    ];

    public static function isValidAttribute(tag:String, attr:String):Bool {
        attr = attr.toLowerCase();
        tag = tag.toLowerCase();

        // Check pattern matches using pre-compiled regexes
        if (attr.startsWith("data-") ||
            attr.startsWith("aria-") ||
            attr == "role" ||
            attr.startsWith("on")) return true;

        // Check global attributes
        if (globalAttrs.exists(attr)) return true;

        // Get element's allowed groups
        final groups = elementGroups.get(tag);
        if (groups == null) return false;

        // Check group-specific attributes
        for (group => attrs in groupAttrs) {
            if ((groups & group) != 0 && attrs.indexOf(attr) != -1) return true;
        }

        // Special cases lookup (for unique attributes that don't fit patterns)
        return switch [tag, attr] {
            case ["time", "datetime"] | ["del", "datetime"] | ["ins", "datetime"]: true;
            case ["meter", "low" | "high" | "optimum"]: true;
            case ["dialog", "open"]: true;
            case ["details", "open"]: true;
            case ["ol", "reversed" | "start"]: true;
            case ["html", "manifest" | "version" | "xmlns"]: true;
            case ["li", "value"]: true;
            default: false;
        };

    }

}
