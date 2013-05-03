# https://github.com/droptype/noat


# Public: class that manages the public API and stores the working data.
#
# * text - A string of arbitrary content, to have annotations applied. The
#            string MAY be empty, but then its annotations MUST only cover
#            the position 0.
#
# The instance is lazy in its application of the annotations. It stores them
# in a list, but only generates the markup when the instance's `.to_s`
# is called.
class NOAT
    def initialize(text)
        @text = text
        @_markup = nil
        @annotations = []
    end


    # Public: add an annotation to the list of annotations to be applied.
    #
    # * tag     - A string to be used as the tag, eg `'em'` becomes `<em>`/`</em>`.
    # * a_start - An integer that is the text position of the open tag.
    # * a_end   - (optional) - An integer that is the test position of the closing tag.
    #               If not provided, the start is used (ie the tag is opened and then
    #               closed immediately, eg `...blah<span></span>blah...`).
    # * attrs   - (optional) - A hash of key-value attributes to be added to
    #               the tag, eg `{ :id => 'foo' }` becomes `id="foo"`.
    def add(tag, a_start, a_end_or_attrs=nil, attrs=nil)
        a_start = a_start.to_i()

        if a_end_or_attrs.is_a? Integer or a_end_or_attrs.is_a? Float
            a_end = a_end_or_attrs
        else
            a_end = a_start
            attrs = a_end_or_attrs
        end

        if a_end.nil?
            a_end = a_start
        end

        if attrs.nil?
            attrs = {}
        end

        a_end = a_end.to_i()

        self._validateRange(a_start, a_end)

        @annotations.push({
            :tag    => tag,
            :start  => a_start,
            :end    => a_end,
            :attrs  => attrs,
        })
        @_markup = nil
    end

    def to_s
        if @_markup == nil
            self._applyAnnotations()
        end
        return @_markup
    end

    def _validateRange(a_start, a_end)
        if a_start > a_end
            raise "start (#{ a_start }) must be <= end (#{ a_end })"
        end
        if a_start < 0
            raise "start (#{ a_start }) must be >= 0"
        end
        if a_end > @text.length
            raise "end (#{ a_end }) must be <= length of text (#{ @text.length })"
        end

    end

    def _applyAnnotations
        @_markup = _addTextAnnotations(@text, @annotations)
    end


end


def _openTag(t)
    attrs = ''
    t[:attrs].each_pair do |k,v|
        if k == '_class'  # for consistency with Python version
            k = 'class'
        end
        attrs += " #{k}=\"#{v}\""
    end
    return "<#{t[:tag]}#{attrs}>"
end

def _closeTag(t)
    return "</#{t[:tag]}>"
end



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
def _addTextAnnotations(text, annotations)
    # Index annotations by their start and end positions.
    annotation_index_by_start = {}
    annotation_index_by_end = {}

    for a in annotations do
        if not annotation_index_by_start.has_key?(a[:start])
            annotation_index_by_start[a[:start]] = []
        end
        annotation_index_by_start[a[:start]].push(a)

        if a[:start] != a[:end]
            if not annotation_index_by_end.has_key?(a[:end])
                annotation_index_by_end[a[:end]] = []
            end
            annotation_index_by_end[a[:end]].push(a)
        end
    end

    # Find the segment boundaries of text, as bounded by opening and closing
    # tags (equivalent to the text nodes in the HTML DOM).
    segment_boundaries = annotation_index_by_end.keys() + annotation_index_by_start.keys()
    segment_boundaries.sort!()

    # Make sure the segments include the beginning and end of the text.
    if segment_boundaries.length == 0 or segment_boundaries[0] != 0
        segment_boundaries.insert(0,0)
    end
    if segment_boundaries[-1] != text.length
        segment_boundaries.push(text.length)
    end

    segments = []
    segment_boundaries[0...segment_boundaries.length-1].each_index do |i|
        s_start = segment_boundaries[i]
        s_end = segment_boundaries[i+1]
        if s_start != s_end
            segments.push(text[s_start...s_end])
        end
    end

    # Always have at least one segment, even if empty, to allow for adding
    # annotations to empty strings.
    if segments.length == 0
        segments.push('')
    end

    output = ''
    open_tags = []
    i = 0

    for seg_text in segments
        tags_to_open = annotation_index_by_start.fetch(i, [])
        tags_to_close = annotation_index_by_end.fetch(i, [])

        tags_to_reopen = []
        for t in tags_to_close
            # Work back up the stack of open tags until the annotation to be
            # closed is found, closing the open tags in order and saving them
            # for reopening. (This should raise an IndexError if there aren't
            # any open tags, which should not be true at this point.)
            while open_tags.length > 0 and t[:tag] != open_tags[-1][:tag]
                o_tag = open_tags.pop()
                output += _closeTag(o_tag)
                tags_to_reopen.push(o_tag)
            end

            # Close the annotation.
            output += _closeTag(t)
            open_tags.pop()

            # Reopen annotations that were closed to prevent overlap.
            while tags_to_reopen.length > 0
                o_tag = tags_to_reopen.pop()
                output += _openTag(o_tag)
                open_tags.push(o_tag)
            end
        end

        # Open the tags that start at this point.
        for t in tags_to_open
            output += _openTag(t)
            # Unless the tag also closes at this point, add it to the stack of
            # open tags. Otherwise, close it.
            if t[:start] != t[:end]
                open_tags.push(t)
            else
                output += _closeTag(t)
            end
        end

        output += seg_text

        i += seg_text.length
    end

    # Close any tags that are still open (should only be any that are set to
    # end at the end of the target string).
    while open_tags.length > 0
        o_tag = open_tags.pop()
        output += _closeTag(o_tag)
    end
    return output
end

