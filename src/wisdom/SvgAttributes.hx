package wisdom;

using StringTools;

/**
 * Which attributes an SVG element accepts.
 *
 * Deliberately name-based: every known SVG attribute is accepted on every
 * known SVG element. Presentation attributes legitimately apply to nearly all
 * graphics and container elements, the per-element rules for the rest are
 * intricate, and for wisdom's purpose a misplaced attribute is harmless (the
 * element just ignores it) while a dropped one is a real bug. The attribute
 * set is the union of the SVG 2 attribute index, MDN's SVG attribute
 * reference, and the SVG 1.1 font and glyph attributes.
 *
 * Lookups are case-sensitive: SVG attribute and element names are camelCase
 * (`viewBox`, `clipPath`). Element names are also matched lowercase, which is
 * how the HTML parser hands them over.
 */
class SvgAttributes {

    static final attrs:Map<String, Bool> = [
        // Core, document, conditional processing
        "id" => true, "class" => true, "style" => true, "lang" => true, "tabindex" => true, "autofocus" => true,
        "xml:base" => true, "xml:lang" => true, "xml:space" => true, "xmlns" => true, "xmlns:xlink" => true,
        "version" => true, "baseProfile" => true, "contentScriptType" => true, "contentStyleType" => true,
        "focusable" => true, "externalResourcesRequired" => true, "playbackOrder" => true, "timelineBegin" => true,
        "requiredExtensions" => true, "requiredFeatures" => true, "systemLanguage" => true, "nonce" => true,

        // Linking (SVG <a>, <use>, <image>, gradients, patterns, animation targets)
        "href" => true, "xlink:href" => true, "xlink:type" => true, "xlink:role" => true, "xlink:arcrole" => true,
        "xlink:title" => true, "xlink:show" => true, "xlink:actuate" => true,
        "target" => true, "download" => true, "ping" => true, "rel" => true, "hreflang" => true, "type" => true,
        "referrerpolicy" => true, "referrerPolicy" => true, "crossorigin" => true, "decoding" => true,
        "fetchpriority" => true, "media" => true, "title" => true,

        // Presentation attributes
        "alignment-baseline" => true, "baseline-shift" => true, "clip" => true, "clip-path" => true, "clip-rule" => true,
        "color" => true, "color-interpolation" => true, "color-interpolation-filters" => true, "color-profile" => true,
        "color-rendering" => true, "cursor" => true, "direction" => true, "display" => true, "dominant-baseline" => true,
        "enable-background" => true, "fill" => true, "fill-opacity" => true, "fill-rule" => true, "filter" => true,
        "flood-color" => true, "flood-opacity" => true, "font" => true, "font-family" => true, "font-kerning" => true,
        "font-size" => true, "font-size-adjust" => true, "font-stretch" => true, "font-style" => true,
        "font-variant" => true, "font-weight" => true, "font-width" => true, "glyph-orientation-horizontal" => true,
        "glyph-orientation-vertical" => true, "image-rendering" => true, "inline-size" => true, "isolation" => true,
        "kerning" => true, "letter-spacing" => true, "lighting-color" => true, "line-height" => true, "marker" => true,
        "marker-end" => true, "marker-mid" => true, "marker-start" => true, "mask" => true, "mask-type" => true,
        "mix-blend-mode" => true, "opacity" => true, "overflow" => true, "paint-order" => true, "pointer-events" => true,
        "shape-inside" => true, "shape-margin" => true, "shape-outside" => true, "shape-padding" => true,
        "shape-rendering" => true, "shape-subtract" => true, "solid-color" => true, "solid-opacity" => true,
        "stop-color" => true, "stop-opacity" => true, "stroke" => true, "stroke-dasharray" => true,
        "stroke-dashoffset" => true, "stroke-linecap" => true, "stroke-linejoin" => true, "stroke-miterlimit" => true,
        "stroke-opacity" => true, "stroke-width" => true, "text-anchor" => true, "text-decoration" => true,
        "text-orientation" => true, "text-overflow" => true, "text-rendering" => true, "transform" => true,
        "transform-box" => true, "transform-origin" => true, "unicode-bidi" => true, "vector-effect" => true,
        "viewport-fill" => true, "viewport-fill-opacity" => true, "visibility" => true, "white-space" => true,
        "word-spacing" => true, "writing-mode" => true,

        // Geometry, viewport, text layout
        "x" => true, "y" => true, "z" => true, "dx" => true, "dy" => true, "width" => true, "height" => true,
        "cx" => true, "cy" => true, "r" => true, "rx" => true, "ry" => true, "fr" => true, "fx" => true, "fy" => true,
        "x1" => true, "y1" => true, "x2" => true, "y2" => true, "points" => true, "d" => true, "pathLength" => true,
        "viewBox" => true, "preserveAspectRatio" => true, "zoomAndPan" => true, "viewTarget" => true,
        "refX" => true, "refY" => true, "markerWidth" => true, "markerHeight" => true, "markerUnits" => true,
        "orient" => true, "side" => true, "startOffset" => true, "method" => true, "spacing" => true,
        "textLength" => true, "lengthAdjust" => true, "rotate" => true,

        // Units and references
        "clipPathUnits" => true, "maskUnits" => true, "maskContentUnits" => true, "patternUnits" => true,
        "patternContentUnits" => true, "patternTransform" => true, "gradientUnits" => true,
        "gradientTransform" => true, "spreadMethod" => true, "offset" => true, "filterUnits" => true,
        "primitiveUnits" => true, "filterRes" => true,

        // Filter primitives
        "in" => true, "in2" => true, "result" => true, "stdDeviation" => true, "operator" => true, "mode" => true,
        "scale" => true, "xChannelSelector" => true, "yChannelSelector" => true, "values" => true,
        "tableValues" => true, "slope" => true, "intercept" => true, "amplitude" => true, "exponent" => true,
        "azimuth" => true, "elevation" => true, "pointsAtX" => true, "pointsAtY" => true, "pointsAtZ" => true,
        "specularExponent" => true, "specularConstant" => true, "diffuseConstant" => true, "surfaceScale" => true,
        "limitingConeAngle" => true, "bias" => true, "kernelMatrix" => true, "divisor" => true,
        "kernelUnitLength" => true, "targetX" => true, "targetY" => true, "order" => true, "preserveAlpha" => true,
        "edgeMode" => true, "radius" => true, "numOctaves" => true, "seed" => true, "stitchTiles" => true,
        "baseFrequency" => true, "k1" => true, "k2" => true, "k3" => true, "k4" => true,
        "transferFunctionType" => true,

        // Animation
        "begin" => true, "dur" => true, "end" => true, "min" => true, "max" => true, "restart" => true,
        "repeatCount" => true, "repeatDur" => true, "calcMode" => true, "keyTimes" => true, "keySplines" => true,
        "keyPoints" => true, "from" => true, "to" => true, "by" => true, "additive" => true, "accumulate" => true,
        "attributeName" => true, "attributeType" => true, "path" => true, "origin" => true, "autoReverse" => true,

        // SVG 1.1 fonts and glyphs (deprecated, harmless to keep)
        "glyphRef" => true, "format" => true, "u1" => true, "u2" => true, "g1" => true, "g2" => true, "k" => true,
        "unicode" => true, "glyph-name" => true, "horiz-adv-x" => true, "horiz-origin-x" => true,
        "horiz-origin-y" => true, "vert-adv-y" => true, "vert-origin-x" => true, "vert-origin-y" => true,
        "units-per-em" => true, "ascent" => true, "descent" => true, "cap-height" => true, "x-height" => true,
        "accent-height" => true, "alphabetic" => true, "ideographic" => true, "mathematical" => true,
        "hanging" => true, "v-alphabetic" => true, "v-ideographic" => true, "v-mathematical" => true,
        "v-hanging" => true, "underline-position" => true, "underline-thickness" => true,
        "strikethrough-position" => true, "strikethrough-thickness" => true, "overline-position" => true,
        "overline-thickness" => true, "stemv" => true, "stemh" => true, "panose-1" => true, "widths" => true,
        "bbox" => true, "unicode-range" => true, "arabic-form" => true, "orientation" => true, "local" => true,
        "name" => true, "rendering-intent" => true, "string" => true
    ];

    /** Every SVG element, current and deprecated, plus the HTML media elements SVG 2 allows inline. */
    static final elements:Map<String, Bool> = [
        "a" => true, "altGlyph" => true, "altGlyphDef" => true, "altGlyphItem" => true, "animate" => true,
        "animateColor" => true, "animateMotion" => true, "animateTransform" => true, "audio" => true,
        "canvas" => true, "circle" => true, "clipPath" => true, "color-profile" => true, "cursor" => true,
        "defs" => true, "desc" => true, "discard" => true, "ellipse" => true, "feBlend" => true,
        "feColorMatrix" => true, "feComponentTransfer" => true, "feComposite" => true, "feConvolveMatrix" => true,
        "feDiffuseLighting" => true, "feDisplacementMap" => true, "feDistantLight" => true, "feDropShadow" => true,
        "feFlood" => true, "feFuncA" => true, "feFuncB" => true, "feFuncG" => true, "feFuncR" => true,
        "feGaussianBlur" => true, "feImage" => true, "feMerge" => true, "feMergeNode" => true,
        "feMorphology" => true, "feOffset" => true, "fePointLight" => true, "feSpecularLighting" => true,
        "feSpotLight" => true, "feTile" => true, "feTurbulence" => true, "filter" => true, "font" => true,
        "font-face" => true, "font-face-format" => true, "font-face-name" => true, "font-face-src" => true,
        "font-face-uri" => true, "foreignObject" => true, "g" => true, "glyph" => true, "glyphRef" => true,
        "hatch" => true, "hatchpath" => true, "hkern" => true, "iframe" => true, "image" => true, "line" => true,
        "linearGradient" => true, "marker" => true, "mask" => true, "mesh" => true, "meshgradient" => true,
        "meshGradient" => true, "meshpatch" => true, "meshPatch" => true, "meshrow" => true, "meshRow" => true,
        "metadata" => true, "missing-glyph" => true, "mpath" => true, "path" => true, "pattern" => true,
        "polygon" => true, "polyline" => true, "radialGradient" => true, "rect" => true, "script" => true,
        "set" => true, "solidcolor" => true, "stop" => true, "style" => true, "svg" => true, "switch" => true,
        "symbol" => true, "text" => true, "textPath" => true, "title" => true, "tref" => true, "tspan" => true,
        "unknown" => true, "use" => true, "video" => true, "view" => true, "vkern" => true
    ];

    /**
     * Lowercase aliases of `elements` are added once, at load time, so that a
     * lookup is a single map access with no per-call `toLowerCase()`: the HTML
     * parser lowercases tag names, wisdom markup keeps their case.
     */
    static final lowercaseAliasesAdded:Bool = {
        for (k in [for (k in elements.keys()) k]) elements.set(k.toLowerCase(), true);
        true;
    };

    public static function isValidAttribute(tag:String, attr:String):Bool {

        // Open-ended families.
        if (attr.startsWith("data-") ||
            attr.startsWith("aria-") ||
            attr == "role" ||
            attr.startsWith("on") ||
            attr.startsWith("xlink:") ||
            attr.startsWith("xml:") ||
            attr.startsWith("xmlns")) return true;

        if (!isValidTag(tag)) return false;

        return attrs.exists(attr);

    }

    public static function isValidTag(tag:String):Bool {

        return elements.exists(tag);

    }

}
