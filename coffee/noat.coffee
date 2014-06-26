###
https://github.com/marquee/noat
###

# Public: class that manages the public API and stores the working data.
#
# * text - A string of arbitrary content, to have annotations applied. The
#            string MAY be empty, but then its annotations MUST only cover
#            the position 0.
#
# The instance is lazy in its application of the annotations. It stores them
# in a list, but only generates the markup when the instance's `.toString`
# is called.
class NOAT
    constructor: (text) ->
        @text           = text
        @annotations    = []
        @_markup        = null

    ###
    Public: add an annotation to the list of annotations to be applied.

    * tag   - A string to be used as the tag, eg `'em'` becomes `<em>`/`</em>`.
    * start - An integer that is the text position of the open tag.
    * end   - (optional) - An integer that is the test position of the closing tag.
                If not provided, the start is used (ie the tag is opened and then
                closed immediately, eg `...blah<span></span>blah...`).
    * attrs - (optional) - An object of key-value attributes to be added to
                the tag, eg `{ 'id': 'foo' }` becomes `id="foo"`.
    ###
    add: (tag, start, end_or_attrs, attrs={}) ->
        if arguments.length > 4
            throw new Error("add() takes 2, 3 or 4 arguments (#{ arguments.length } given)")

        if typeof end_or_attrs isnt 'number'
            end = start
            attrs = end_or_attrs
        else
            end = end_or_attrs

        end = start if not end

        start = parseInt(start)
        end = parseInt(end)

        @_validateRange(start, end)

        @annotations.push
            tag     : tag
            start   : start
            end     : end
            attrs   : attrs
        @_markup = null

    _applyAnnotations: ->
        @_markup = _addTextAnnotations(@text, @annotations)

    toString: ->
        if not @_markup?
            @_applyAnnotations()
        return @_markup

    _validateRange: (start, end) ->
        if start > end
            throw new Error("start (#{ start }) must be <= end (#{ end })")
        if start < 0
            throw new Error("start (#{ start }) must be >= 0")
        if end > @text.length
            throw new Error("end (#{ end }) must be <= length of text (#{ @text.length })")


_openTag = (t) ->
    attrs = ''
    for k, v of t.attrs
        if k is '_class' # for consistency with Python version
            k = 'class'
        attrs += " #{k}=\"#{_escapeHTML(v)}\""
    return "<#{t.tag}#{attrs}>"

_closeTag = (t) ->
    return "</#{t.tag}>"


# Private: insert the specified annotation tags into the given text at the
# correct positions, avoiding overlapping tags (invalid HTML).

# The text is broken into segments, bounded by the start and end points of all of
# the annotations. It is then reassembled, with opening and closing tags for
# annotations inserted between the segments. Tags are closed and reopened as
# needed to prevent overlap.

# * content     - str content of the block
# * annotations - list of annotations (MAY be empty)
#     * type  - str type of the annotation
#     * start - int starting point of the annotation
#     * end   - int ending point of the annotation
#     * attrs - (optional) a dict of tag attributes

# Returns a string containing the markup of the text content, with
# annotations inserted.
_addTextAnnotations = (text, annotations) ->

    # Index annotations by their start and end positions.
    annotation_index_by_start = {}
    annotation_index_by_end = {}

    for a in annotations
        annotation_index_by_start[a['start']] ?= []
        annotation_index_by_start[a['start']].push( a )

        if a['start'] != a['end']
            annotation_index_by_end[a['end']] ?= []
            annotation_index_by_end[a['end']].push( a )


    # Find the segment boundaries of text, as bounded by opening and closing
    # tags (equivalent to the text nodes in the HTML DOM).
    segment_boundaries = []
    for k, v of annotation_index_by_start
        segment_boundaries.push(parseInt(k))
    for k, v of annotation_index_by_end
        segment_boundaries.push(parseInt(k))
    segment_boundaries.sort (a,b) -> a - b

    # Make sure the segments include the beginning and end of the text.
    if segment_boundaries.length == 0 or segment_boundaries[0] != 0
        segment_boundaries.unshift(0)
    if segment_boundaries[segment_boundaries.length-1] != text.length
        segment_boundaries.push(text.length)

    # Extract the actual text content for each segment.
    segments = []
    for i, bound of segment_boundaries[0...-1]
        start = bound
        end = segment_boundaries[parseInt(i)+1]
        if start != end
            segments.push(text.substring(start,end))

    # Always have at least one segment, even if empty, to allow for adding
    # annotations to empty strings.
    if segments.length is 0
        segments.push('')

    output = ''
    open_tags = []
    i = 0

    for seg_text in segments
        tags_to_open = annotation_index_by_start[i] or []
        tags_to_close = annotation_index_by_end[i] or []

        tags_to_reopen = []
        for t in tags_to_close
            # Work back up the stack of open tags until the annotation to be
            # closed is found, closing the open tags in order and saving them
            # for reopening. (This should raise an IndexError if there aren't
            # any open tags, which should not be true at this point.)
            while open_tags.length > 0 and t['tag'] != open_tags[open_tags.length-1]['tag']
                o_tag = open_tags.pop()
                output += _closeTag(o_tag)
                tags_to_reopen.push(o_tag)

            # Close the annotation.
            output += _closeTag(t)
            open_tags.pop()

            # Reopen annotations that were closed to prevent overlap.
            while tags_to_reopen.length > 0
                o_tag = tags_to_reopen.pop()
                output += _openTag(o_tag)
                open_tags.push(o_tag)

        # Open the tags that start at this point.
        for t in tags_to_open
            output += _openTag(t)
            # Unless the tag also closes at this point, add it to the stack of
            # open tags. Otherwise, close it.
            if t['start'] != t['end']
                open_tags.push(t)
            else
                output += _closeTag(t)

        # Add the escaped segment text content, but track the length of the
        # original text to preserve annotation positions.
        output += _escapeHTML(seg_text)
        i += seg_text.length

    # Close any tags that are still open (should only be any that are set to
    # end at the end of the target string).
    while open_tags.length > 0
        o_tag = open_tags.pop()
        output += _closeTag(o_tag)


    return output

# Escape HTML entities.
_escapeHTML = (str) ->
    return str.replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;').replace(/"/g, '&quot;').replace(/'/g, '&#39;')


if module?.exports?
    module.exports = NOAT
else
    window['NOAT'] = NOAT
