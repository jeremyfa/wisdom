package wisdom;

using StringTools;

class SvgAttributes {

    // Attribute groups as bit flags
    private static inline var NONE = 0;
    private static inline var CORE = 1;           // Core attributes
    private static inline var PRESENTATION = 2;   // Visual properties
    private static inline var GEOMETRY = 4;       // Position and size
    private static inline var ANIMATION = 8;      // Animation-related
    private static inline var XLINK = 16;         // XLink attributes
    private static inline var EVENT = 32;         // Event handlers
    private static inline var ARIA = 64;          // Accessibility
    private static inline var FILTER = 128;       // Filter effects
    private static inline var TEXT = 256;         // Text-specific attributes
    private static inline var GRADIENT = 512;     // Gradient-specific
    private static inline var COLOR = 1024;       // Color-specific
    private static inline var CONDITIONAL = 2048; // Conditional processing
    private static inline var DOCUMENT = 4096;    // Document level
    private static inline var CLIPBOARD = 8192;   // Clipboard events
    private static inline var SCRIPT = 16384;     // Scripting-related

    // Common combinations
    private static inline var SHAPE_ATTRS = CORE | PRESENTATION | GEOMETRY;
    private static inline var CONTAINER_ATTRS = CORE | PRESENTATION;
    private static inline var GRAPHIC_ATTRS = SHAPE_ATTRS | XLINK;
    private static inline var ALL_INTERACTIVE = CORE | EVENT | CLIPBOARD | SCRIPT;

    // Valid SVG elements and their allowed attribute groups
    private static final elementGroups:Map<String, Int> = [
        // Container elements
        "svg" => DOCUMENT | CORE | PRESENTATION | GEOMETRY | CONDITIONAL,
        "g" => CONTAINER_ATTRS,
        "defs" => CONTAINER_ATTRS,
        "symbol" => CONTAINER_ATTRS | GEOMETRY,
        "switch" => CONTAINER_ATTRS | CONDITIONAL,
        "foreignObject" => SHAPE_ATTRS,

        // Shape elements
        "rect" => SHAPE_ATTRS,
        "circle" => SHAPE_ATTRS,
        "ellipse" => SHAPE_ATTRS,
        "line" => SHAPE_ATTRS,
        "polyline" => SHAPE_ATTRS,
        "polygon" => SHAPE_ATTRS,
        "path" => SHAPE_ATTRS,
        "mesh" => SHAPE_ATTRS,
        "solidcolor" => CORE | COLOR,

        // Text elements
        "text" => SHAPE_ATTRS | TEXT,
        "tspan" => SHAPE_ATTRS | TEXT,
        "textPath" => SHAPE_ATTRS | TEXT | XLINK,
        "altGlyph" => SHAPE_ATTRS | TEXT | XLINK,
        "altGlyphDef" => CORE,
        "altGlyphItem" => CORE,
        "glyphRef" => CORE | TEXT | XLINK,

        // Referencing elements
        "image" => GRAPHIC_ATTRS,
        "use" => GRAPHIC_ATTRS,

        // Clipping and masking
        "clipPath" => CORE | GEOMETRY,
        "mask" => CORE | PRESENTATION | GEOMETRY,

        // Paint servers
        "pattern" => SHAPE_ATTRS | XLINK,
        "marker" => SHAPE_ATTRS,
        "linearGradient" => CORE | PRESENTATION | GRADIENT,
        "radialGradient" => CORE | PRESENTATION | GRADIENT,
        "meshGradient" => CORE | PRESENTATION | GRADIENT,
        "meshRow" => CORE | PRESENTATION,
        "meshPatch" => CORE | PRESENTATION,
        "stop" => CORE | PRESENTATION | GRADIENT,
        "hatch" => CORE | PRESENTATION,
        "hatchpath" => CORE | PRESENTATION,

        // Filter elements
        "filter" => CORE | PRESENTATION | FILTER | XLINK,
        "feBlend" => FILTER,
        "feColorMatrix" => FILTER,
        "feComponentTransfer" => FILTER,
        "feComposite" => FILTER,
        "feConvolveMatrix" => FILTER,
        "feDiffuseLighting" => FILTER,
        "feDisplacementMap" => FILTER,
        "feDropShadow" => FILTER,
        "feFlood" => FILTER | COLOR,
        "feFuncA" => FILTER,
        "feFuncB" => FILTER,
        "feFuncG" => FILTER,
        "feFuncR" => FILTER,
        "feGaussianBlur" => FILTER,
        "feImage" => FILTER | XLINK,
        "feMerge" => FILTER,
        "feMergeNode" => FILTER,
        "feMorphology" => FILTER,
        "feOffset" => FILTER,
        "fePointLight" => FILTER,
        "feSpecularLighting" => FILTER,
        "feSpotLight" => FILTER,
        "feTile" => FILTER,
        "feTurbulence" => FILTER,
        "feDistantLight" => FILTER,

        // Animation elements
        "animate" => ANIMATION | XLINK,
        "animateColor" => ANIMATION | XLINK,
        "animateMotion" => ANIMATION,
        "animateTransform" => ANIMATION,
        "discard" => ANIMATION,
        "mpath" => CORE | XLINK,
        "set" => ANIMATION,

        // Font elements
        "font" => CORE | PRESENTATION | GEOMETRY | TEXT,
        "font-face" => CORE | TEXT,
        "font-face-format" => CORE,
        "font-face-name" => CORE,
        "font-face-src" => CORE,
        "font-face-uri" => CORE | XLINK,
        "hkern" => CORE,
        "vkern" => CORE,

        // Metadata elements
        "desc" => CORE,
        "metadata" => CORE,
        "title" => CORE,

        // Scripting elements
        "script" => CORE | SCRIPT | XLINK,
        "style" => CORE | SCRIPT,

        // Extensibility elements
        "unknown" => ALL_INTERACTIVE
    ];

    // Core attributes that apply to all SVG elements
    private static final globalAttrs = [
        // Core attributes
        "id" => true,
        "class" => true,
        "style" => true,
        "lang" => true,
        "tabindex" => true,
        "xml:base" => true,
        "xml:lang" => true,
        "xml:space" => true,

        // Global event attributes
        "onclick" => true,
        "onfocus" => true,
        "onblur" => true,

        // ARIA attributes
        "role" => true,

        // Animation timing attributes
        "begin" => true,
        "end" => true,
        "dur" => true,

        // Common attributes
        "transform" => true,
        "pointer-events" => true,
        "xmlns" => true,
        "xmlns:xlink" => true,
        "version" => true
    ];

    // Group-specific attributes
    private static final groupAttrs:Map<Int, Array<String>> = [
        CORE => [
            // Transform attributes
            "transform", "transform-origin", "transform-box",

            // Opacity and compositing
            "opacity", "mix-blend-mode", "isolation",

            // Overflow properties
            "overflow", "clip", "clip-path", "clip-rule",

            // Interactivity
            "cursor", "pointer-events",

            // Mask properties
            "mask", "mask-type",

            // Filter properties
            "filter", "flood-color", "flood-opacity",
            "lighting-color"
        ],

        PRESENTATION => [
            // Fill properties
            "fill", "fill-opacity", "fill-rule",

            // Stroke properties
            "stroke", "stroke-width", "stroke-linecap", "stroke-linejoin",
            "stroke-miterlimit", "stroke-dasharray", "stroke-dashoffset",
            "stroke-opacity", "vector-effect",

            // Color and painting
            "color", "color-interpolation", "color-interpolation-filters",
            "color-profile", "color-rendering",

            // Display
            "display", "visibility", "shape-rendering",

            // Paint order
            "paint-order",

            // Marker properties
            "marker", "marker-start", "marker-mid", "marker-end",

            // Other visual properties
            "image-rendering", "writing-mode", "baseline-shift",
            "dominant-baseline", "glyph-orientation-horizontal",
            "glyph-orientation-vertical", "direction",
            "shape-inside", "shape-outside", "shape-margin",
            "shape-padding"
        ],

        GEOMETRY => [
            // Position
            "x", "y", "z", "dx", "dy",

            // Size
            "width", "height",

            // Circle/Ellipse
            "cx", "cy", "r", "rx", "ry",

            // Line
            "x1", "y1", "x2", "y2",

            // Polygon/Polyline
            "points",

            // Path
            "d", "pathLength",

            // ViewBox
            "viewBox", "preserveAspectRatio",
            "zoomAndPan", "viewport-fill", "viewport-fill-opacity",

            // Other
            "refX", "refY", "markerWidth", "markerHeight",
            "markerUnits", "orient"
        ],

        ANIMATION => [
            // Timing
            "begin", "dur", "end", "min", "max", "restart",
            "repeatCount", "repeatDur", "fill",

            // Value control
            "calcMode", "values", "keyTimes", "keySplines",
            "from", "to", "by", "autoReverse",

            // Motion
            "path", "keyPoints", "rotate", "origin",

            // Other
            "accumulate", "additive", "attributeName",
            "attributeType", "type"
        ],

        XLINK => [
            "xlink:href", "xlink:show", "xlink:actuate",
            "xlink:type", "xlink:role", "xlink:arcrole",
            "xlink:title", "href"
        ],

        EVENT => [
            // Mouse events
            "onmousedown", "onmouseup", "onclick", "ondblclick",
            "onmouseover", "onmouseout", "onmousemove",

            // Focus events
            "onfocusin", "onfocusout", "onactivate",

            // Key events
            "onkeydown", "onkeypress", "onkeyup",

            // Other events
            "onload", "onerror", "onabort", "onunload",
            "onzoom", "onresize", "onscroll"
        ],

        FILTER => [
            // Common filter attributes
            "filterUnits", "primitiveUnits", "x", "y",
            "width", "height", "result", "in", "in2",

            // Specific filter effect attributes
            "stdDeviation", "operator", "mode", "scale",
            "xChannelSelector", "yChannelSelector",
            "type", "values", "transferFunctionType",
            "tableValues", "slope", "intercept",
            "amplitude", "exponent", "offset",

            // Light source attributes
            "azimuth", "elevation", "pointsAtX", "pointsAtY",
            "pointsAtZ", "specularExponent", "limitingConeAngle",

            // Matrix attributes
            "bias", "kernelMatrix", "divisor", "kernelUnitLength",
            "targetX", "targetY", "order",

            // Other
            "surfaceScale", "diffuseConstant", "specularConstant"
        ],

        TEXT => [
            // Font properties
            "font-family", "font-size", "font-size-adjust",
            "font-stretch", "font-style", "font-variant",
            "font-weight",

            // Text layout
            "text-anchor", "text-decoration", "text-rendering",
            "unicode-bidi", "word-spacing", "letter-spacing",
            "writing-mode", "text-orientation",
            "dominant-baseline", "alignment-baseline",
            "baseline-shift",

            // Text content
            "textLength", "lengthAdjust",

            // Text path
            "startOffset", "method", "spacing",

            // Glyph positioning
            "glyphRef", "format", "rotate", "u1", "u2", "g1", "g2", "k"
        ],

        GRADIENT => [
            "gradientUnits", "gradientTransform", "spreadMethod",
            "offset", "stop-color", "stop-opacity",
            "fr", "fx", "fy"
        ],

        COLOR => [
            "color-interpolation", "color-interpolation-filters",
            "color-profile", "color-rendering", "solid-color",
            "solid-opacity"
        ],

        CONDITIONAL => [
            "requiredFeatures", "requiredExtensions",
            "systemLanguage"
        ],

        DOCUMENT => [
            "baseProfile", "contentScriptType",
            "contentStyleType", "playbackOrder",
            "timelineBegin", "version", "preserveAspectRatio",
            "viewBox", "zoomAndPan", "xmlns", "xmlns:xlink"
        ],

        CLIPBOARD => [
            "oncopy", "oncut", "onpaste"
        ],

        SCRIPT => [
            "type", "crossorigin", "href", "xlink:href"
        ]
    ];

    public static function isValidAttribute(tag:String, attr:String):Bool {

        // Check pattern matches
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

        // Special cases for specific elements
        return switch [tag, attr] {
            case ["path", "pathLength"]: true;
            case ["textPath", "startOffset" | "method" | "spacing"]: true;
            case ["pattern", "patternUnits" | "patternContentUnits" | "patternTransform"]: true;
            case ["marker", "markerUnits" | "markerWidth" | "markerHeight" | "orient" | "refX" | "refY"]: true;
            case ["feImage", "preserveAspectRatio"]: true;
            case ["svg", "contentScriptType" | "contentStyleType" | "playbackOrder"]: true;
            case ["style", "type" | "media"]: true;
            default: false;
        };

    }

    public static function isValidTag(tag:String):Bool {

        return elementGroups.exists(tag.toLowerCase());

    }

}
