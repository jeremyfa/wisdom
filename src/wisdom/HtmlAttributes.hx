package wisdom;

using StringTools;

/**
 * Which attributes an HTML element accepts.
 *
 * `attrElements` mirrors the "Attributes" index of the HTML Standard, one
 * entry per attribute listing the elements it applies to
 * (https://html.spec.whatwg.org/multipage/indices.html#attributes-3), so it
 * can be audited against the spec line by line. `globalAttrs` is the spec's
 * list of global attributes. `legacyAttrs` keeps the obsolete presentational
 * attributes that browsers still honour, plus a few widespread non-standard
 * ones, so that nothing this class used to accept is ever dropped.
 *
 * Over-acceptance is harmless for wisdom's purpose: a misplaced attribute is
 * merely set on an element that ignores it, which is exactly what raw HTML
 * does. Under-acceptance is not: the attribute is silently dropped. When in
 * doubt, accept.
 */
class HtmlAttributes {

    /** Global attributes, applicable to every HTML element. */
    static final globalAttrs:Map<String, Bool> = [
        "accesskey" => true, "anchor" => true, "autocapitalize" => true, "autocorrect" => true,
        "autofocus" => true, "class" => true, "contenteditable" => true, "dir" => true,
        "draggable" => true, "enterkeyhint" => true, "exportparts" => true, "headingoffset" => true,
        "headingreset" => true, "hidden" => true, "id" => true, "inert" => true, "inputmode" => true,
        "is" => true, "itemid" => true, "itemprop" => true, "itemref" => true, "itemscope" => true,
        "itemtype" => true, "lang" => true, "nonce" => true, "part" => true, "popover" => true,
        "slot" => true, "spellcheck" => true, "style" => true, "tabindex" => true, "title" => true,
        "translate" => true, "virtualkeyboardpolicy" => true, "writingsuggestions" => true,
        "xml:lang" => true, "xmlns" => true
    ];

    /** Attribute → elements it applies to, straight from the HTML Standard's index. */
    static final attrElements:Map<String, Array<String>> = [
        "abbr" => ["th"],
        "accept" => ["input"],
        "accept-charset" => ["form"],
        "action" => ["form"],
        "allow" => ["iframe"],
        "allowfullscreen" => ["iframe"],
        "alpha" => ["input"],
        "alt" => ["area", "img", "input"],
        "as" => ["link"],
        "async" => ["script"],
        "autocomplete" => ["form", "input", "select", "textarea"],
        "autoplay" => ["audio", "video"],
        "blocking" => ["link", "script", "style"],
        "charset" => ["meta"],
        "checked" => ["input"],
        "cite" => ["blockquote", "del", "ins", "q"],
        "closedby" => ["dialog"],
        "color" => ["link"],
        "colorspace" => ["input"],
        "cols" => ["textarea"],
        "colspan" => ["td", "th"],
        "command" => ["button"],
        "commandfor" => ["button"],
        "content" => ["meta"],
        "controls" => ["audio", "video"],
        "coords" => ["area"],
        "crossorigin" => ["audio", "img", "link", "script", "video"],
        "data" => ["object"],
        "datetime" => ["del", "ins", "time"],
        "decoding" => ["img"],
        "default" => ["track"],
        "defer" => ["script"],
        "dirname" => ["input", "textarea"],
        "disabled" => ["button", "fieldset", "input", "link", "optgroup", "option", "select", "textarea"],
        "download" => ["a", "area"],
        "enctype" => ["form"],
        "fetchpriority" => ["img", "link", "script"],
        "for" => ["label", "output"],
        "form" => ["button", "fieldset", "input", "object", "output", "select", "textarea"],
        "formaction" => ["button", "input"],
        "formenctype" => ["button", "input"],
        "formmethod" => ["button", "input"],
        "formnovalidate" => ["button", "input"],
        "formtarget" => ["button", "input"],
        "headers" => ["td", "th"],
        "height" => ["canvas", "embed", "iframe", "img", "input", "object", "source", "video"],
        "high" => ["meter"],
        "href" => ["a", "area", "base", "link"],
        "hreflang" => ["a", "link"],
        "http-equiv" => ["meta"],
        "imagesizes" => ["link"],
        "imagesrcset" => ["link"],
        "integrity" => ["link", "script"],
        "ismap" => ["img"],
        "kind" => ["track"],
        "label" => ["optgroup", "option", "track"],
        "list" => ["input"],
        "loading" => ["audio", "iframe", "img", "video"],
        "loop" => ["audio", "video"],
        "low" => ["meter"],
        "max" => ["input", "meter", "progress"],
        "maxlength" => ["input", "textarea"],
        "media" => ["link", "meta", "source", "style"],
        "method" => ["form"],
        "min" => ["input", "meter"],
        "minlength" => ["input", "textarea"],
        "multiple" => ["input", "select"],
        "muted" => ["audio", "video"],
        "name" => ["a", "button", "details", "fieldset", "form", "iframe", "input", "map", "meta", "object", "output", "select", "slot", "textarea", "track"],
        "nomodule" => ["script"],
        "novalidate" => ["form"],
        "open" => ["details", "dialog"],
        "optimum" => ["meter"],
        "pattern" => ["input"],
        "ping" => ["a", "area"],
        "placeholder" => ["input", "textarea"],
        "playsinline" => ["video"],
        "popovertarget" => ["button", "input"],
        "popovertargetaction" => ["button", "input"],
        "poster" => ["video"],
        "preload" => ["audio", "video"],
        "readonly" => ["input", "textarea"],
        "referrerpolicy" => ["a", "area", "iframe", "img", "link", "script"],
        "rel" => ["a", "area", "form", "link"],
        "required" => ["input", "select", "textarea"],
        "reversed" => ["ol"],
        "rows" => ["textarea"],
        "rowspan" => ["td", "th"],
        "sandbox" => ["iframe"],
        "scope" => ["th"],
        "selected" => ["option"],
        "shadowrootclonable" => ["template"],
        "shadowrootcustomelementregistry" => ["template"],
        "shadowrootdelegatesfocus" => ["template"],
        "shadowrootmode" => ["template"],
        "shadowrootserializable" => ["template"],
        "shadowrootslotassignment" => ["template"],
        "shape" => ["area"],
        "size" => ["input", "select"],
        "sizes" => ["img", "link", "source"],
        "span" => ["col", "colgroup"],
        "src" => ["audio", "embed", "iframe", "img", "input", "script", "source", "track", "video"],
        "srcdoc" => ["iframe"],
        "srclang" => ["track"],
        "srcset" => ["img", "source"],
        "start" => ["ol"],
        "step" => ["input"],
        "target" => ["a", "area", "base", "form"],
        "type" => ["a", "button", "embed", "input", "link", "meta", "object", "ol", "script", "source", "style"],
        "usemap" => ["img"],
        "value" => ["button", "data", "input", "li", "meter", "option", "output", "param", "progress"],
        "width" => ["canvas", "embed", "iframe", "img", "input", "object", "source", "video"],
        "wrap" => ["textarea"]
    ];

    /**
     * Obsolete but still-honoured attributes, and a few widespread
     * non-standard ones. Kept generous on purpose.
     */
    static final legacyAttrs:Map<String, Array<String>> = [
        "align" => ["caption", "col", "colgroup", "div", "embed", "h1", "h2", "h3", "h4", "h5", "h6", "hr", "iframe", "img", "input", "legend", "object", "p", "table", "tbody", "td", "tfoot", "th", "thead", "tr"],
        "valign" => ["col", "colgroup", "tbody", "td", "tfoot", "th", "thead", "tr"],
        "width" => ["area", "col", "colgroup", "hr", "pre", "table", "td", "th"],
        "height" => ["area", "col", "colgroup", "table", "td", "th", "tr"],
        "hreflang" => ["area"],
        "size" => ["area", "canvas", "col", "colgroup", "embed", "font", "hr", "iframe", "img", "object", "source", "table", "td", "th", "video"],
        "border" => ["img", "object", "table"],
        "cellpadding" => ["table"],
        "cellspacing" => ["table"],
        "frame" => ["table"],
        "rules" => ["table"],
        "summary" => ["table"],
        "bgcolor" => ["body", "table", "td", "th", "tr"],
        "background" => ["body", "table", "td", "th"],
        "text" => ["body"], "link" => ["body"], "vlink" => ["body"], "alink" => ["body"],
        "nowrap" => ["td", "th"],
        "axis" => ["td", "th"],
        "char" => ["col", "colgroup", "tbody", "td", "tfoot", "th", "thead", "tr"],
        "charoff" => ["col", "colgroup", "tbody", "td", "tfoot", "th", "thead", "tr"],
        "hspace" => ["embed", "iframe", "img", "object"],
        "vspace" => ["embed", "iframe", "img", "object"],
        "longdesc" => ["iframe", "img"],
        "frameborder" => ["iframe"], "scrolling" => ["iframe"], "allowtransparency" => ["iframe"],
        "marginwidth" => ["iframe"], "marginheight" => ["iframe"], "seamless" => ["iframe"],
        "archive" => ["object"], "classid" => ["object"], "code" => ["object"], "codebase" => ["object"],
        "codetype" => ["object"], "declare" => ["object"], "standby" => ["object"], "usemap" => ["input", "object"],
        "charset" => ["a", "link", "script"],
        "language" => ["script"], "event" => ["script"], "for" => ["script"],
        "rev" => ["a", "link"],
        "name" => ["embed", "img", "param"],
        "coords" => ["a"], "shape" => ["a"],
        "media" => ["a", "area"],
        "scheme" => ["meta"],
        "type" => ["li", "menu", "ul"],
        "compact" => ["dir", "dl", "menu", "ol", "ul"],
        "noshade" => ["hr"],
        "clear" => ["br"],
        "color" => ["basefont", "font", "hr"], "face" => ["basefont", "font"],
        "manifest" => ["html"], "version" => ["html"],
        "datetime" => ["data"],
        // Not a real attribute on <select> (its value is a property), but the previous
        // table accepted it and existing markup relies on the DOM output staying the same.
        "value" => ["select"],
        // Non-standard but widespread.
        "capture" => ["input"], "webkitdirectory" => ["input"], "incremental" => ["input"], "results" => ["input"],
        "controlslist" => ["audio", "video"], "disablepictureinpicture" => ["video"],
        "disableremoteplayback" => ["audio", "video"], "autopictureinpicture" => ["video"],
        "behavior" => ["marquee"], "direction" => ["marquee"], "scrollamount" => ["marquee"],
        "scrolldelay" => ["marquee"], "truespeed" => ["marquee"]
    ];

    /** Every HTML element this table knows about, current and obsolete. */
    static final elements:Map<String, Bool> = [
        "a" => true, "abbr" => true, "acronym" => true, "address" => true, "applet" => true, "area" => true,
        "article" => true, "aside" => true, "audio" => true, "b" => true, "base" => true, "basefont" => true,
        "bdi" => true, "bdo" => true, "bgsound" => true, "big" => true, "blink" => true, "blockquote" => true,
        "body" => true, "br" => true, "button" => true, "canvas" => true, "caption" => true, "center" => true,
        "cite" => true, "code" => true, "col" => true, "colgroup" => true, "data" => true, "datalist" => true,
        "dd" => true, "del" => true, "details" => true, "dfn" => true, "dialog" => true, "dir" => true,
        "div" => true, "dl" => true, "dt" => true, "em" => true, "embed" => true, "fieldset" => true,
        "figcaption" => true, "figure" => true, "font" => true, "footer" => true, "form" => true, "frame" => true,
        "frameset" => true, "h1" => true, "h2" => true, "h3" => true, "h4" => true, "h5" => true, "h6" => true,
        "head" => true, "header" => true, "hgroup" => true, "hr" => true, "html" => true, "i" => true,
        "iframe" => true, "img" => true, "input" => true, "ins" => true, "isindex" => true, "kbd" => true,
        "keygen" => true, "label" => true, "legend" => true, "li" => true, "link" => true, "listing" => true,
        "main" => true, "map" => true, "mark" => true, "marquee" => true, "menu" => true, "menuitem" => true,
        "meta" => true, "meter" => true, "nav" => true, "nobr" => true, "noembed" => true, "noframes" => true,
        "noscript" => true, "object" => true, "ol" => true, "optgroup" => true, "option" => true, "output" => true,
        "p" => true, "param" => true, "picture" => true, "plaintext" => true, "pre" => true, "progress" => true,
        "q" => true, "rb" => true, "rp" => true, "rt" => true, "rtc" => true, "ruby" => true, "s" => true,
        "samp" => true, "script" => true, "search" => true, "section" => true, "select" => true, "slot" => true,
        "small" => true, "source" => true, "spacer" => true, "span" => true, "strike" => true, "strong" => true,
        "style" => true, "sub" => true, "summary" => true, "sup" => true, "table" => true, "tbody" => true,
        "td" => true, "template" => true, "textarea" => true, "tfoot" => true, "th" => true, "thead" => true,
        "time" => true, "title" => true, "tr" => true, "track" => true, "tt" => true, "u" => true, "ul" => true,
        "var" => true, "video" => true, "wbr" => true, "xmp" => true
    ];

    public static function isValidAttribute(tag:String, attr:String):Bool {

        attr = attr.toLowerCase();
        tag = tag.toLowerCase();

        // Open-ended families.
        if (attr.startsWith("data-") ||
            attr.startsWith("aria-") ||
            attr == "role" ||
            attr.startsWith("on")) return true;

        if (globalAttrs.exists(attr)) return true;

        // A custom element (its name contains a hyphen) may carry any attribute.
        // Any other unknown tag is not HTML as far as this table knows; the
        // caller may still consult the SVG table.
        if (!elements.exists(tag)) return tag.indexOf("-") != -1;

        final els = attrElements.get(attr);
        if (els != null && els.indexOf(tag) != -1) return true;

        final legacy = legacyAttrs.get(attr);
        if (legacy != null && legacy.indexOf(tag) != -1) return true;

        return false;

    }

    public static function isValidTag(tag:String):Bool {

        return elements.exists(tag.toLowerCase());

    }

}
