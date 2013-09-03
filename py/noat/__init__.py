# https://github.com/droptype/noat

import cgi

# Public: class that manages the public API and stores the working data.
#
# * text - A string of arbitrary content, to have annotations applied. The
#            string MAY be empty, but then its annotations MUST only cover
#            the position 0.
#
# The instance is lazy in its application of the annotations. It stores them
# in a list, but only generates the markup when the instance's `.__str__`
# is called.
class NOAT(object):
    def __init__(self, text):
        self.text           = text
        self.annotations    = []
        self._markup        = None

    def add(self, tag, start, *args, **attrs):
        """
        Public: add an annotation to the list of annotations to be applied.

        * tag   - A str to be used as the tag, eg `'em'` becomes `<em>`/`</em>`.
        * start - An int that is the text position of the open tag.
        * end   - (optional) - An integer that is the test position of the closing tag.
                    If not provided, the start is used (ie the tag is opened and then
                    closed immediately, eg `...blah<span></span>blah...`).
        * kwargs - (optional) - Keyword arguments that are key-value attributes
                    to be added to the tag, eg `id=foo` becomes `id="foo"`.
        """

        attributes = {}

        if len(args) == 2:
            attributes = args[1] 
        if len(args) >= 1:
            end = args[0]
        elif len(args) == 0:
            end = start
        else:
            raise TypeError('add() takes 2, 3, or 4 arguments ({0} given)'.format(len(args) + 2))

        start = int(start)

        try:
            end = int(end)
        except TypeError:
            end = start
            attributes = args[0]

        for k, v in attrs.items():
            if k == '_class':
                k = 'class'
            attributes[k] = v

        self._validateRange(start, end)
        self.annotations.append({
            'tag'   : tag,
            'start' : start,
            'end'   : end,
            'attrs' : attributes,
        })
        # Clear any existing markup.
        self._markup = None

    def _applyAnnotations(self):
        self._markup = _addTextAnnotations(self.text, self.annotations)

    def __str__(self):
        if self._markup is None:
            self._applyAnnotations()
        return self._markup

    def __repr__(self):
        return "NOAT('{0}')".format(self.text)


    def _validateRange(self, start, end):
        if start > end:
            raise IndexError('start ({0}) must be <= end ({1})'.format(start, end))
        if start < 0:
            raise IndexError('start ({0}) must be >= 0'.format(start))
        if end > len(self.text):
            raise IndexError('end ({0}) must be <= length of text ({1})'.format(end, len(self.text)))

def _openTag(t):
    attrs = ''
    for k, v in t['attrs'].items():
        # For convenience, convert '_class' to 'class' since 'class' is a
        # reserved word and akward to use in kwargs otherwise.
        if k == '_class':
            k = 'class'
        attrs += ' {0}="{1}"'.format(k, v)
    return '<{0}{1}>'.format(t['tag'],attrs)

def _closeTag(t):
    return '</{0}>'.format(t['tag'],)

def _addTextAnnotations(text, annotations):
    """
    Private: insert the specified annotation tags into the given text at the
    correct positions, avoiding overlapping tags (invalid HTML).

    The text is broken into segments, bounded by the start and end points of all of
    the annotations. It is then reassembled, with opening and closing tags for
    annotations inserted between the segments. Tags are closed and reopened as
    needed to prevent overlap.

    * content     - str content of the block
    * annotations - list of annotations (MAY be empty)
        * type  - str type of the annotation
        * start - int starting point of the annotation
        * end   - int ending point of the annotation
        * attrs - (optional) a dict of tag attributes

    Returns a unicode containing the markup of the text content, with
    annotations inserted.
    """

    # Index annotations by their start and end positions.
    annotation_index_by_start = {}
    annotation_index_by_end = {}

    for a in annotations:

        if not a['start'] in annotation_index_by_start:
            annotation_index_by_start[a['start']] = []
        annotation_index_by_start[a['start']].append( a )

        if a['start'] != a['end']:
            if not a['end'] in annotation_index_by_end:
                annotation_index_by_end[a['end']] = []
            annotation_index_by_end[a['end']].append( a )


    # Find the segment boundaries of text, as bounded by opening and closing
    # tags (equivalent to the text nodes in the HTML DOM).
    segment_boundaries = list(annotation_index_by_start.keys()) + list(annotation_index_by_end.keys())
    segment_boundaries.sort()

    # Make sure the segments include the beginning and end of the text.
    if len(segment_boundaries) == 0 or segment_boundaries[0] != 0:
        segment_boundaries.insert(0,0)
    if segment_boundaries[-1] != len(text):
        segment_boundaries.append(len(text))

    # Extract the actual text content for each segment.
    segments = []
    for i, bound in enumerate(segment_boundaries[:-1]):
        start = bound
        end = segment_boundaries[i+1]
        if start != end:
            segments.append(text[start:end])

    # Always have at least one segment, even if empty, to allow for adding
    # annotations to empty strings.
    if len(segments) == 0:
        segments.append('')

    output = []
    open_tags = []
    i = 0

    for seg_text in segments:
        tags_to_open = annotation_index_by_start.get(i, [])
        tags_to_close = annotation_index_by_end.get(i, [])

        tags_to_reopen = []
        for t in tags_to_close:
            # Work back up the stack of open tags until the annotation to be
            # closed is found, closing the open tags in order and saving them
            # for reopening. (This should raise an IndexError if there aren't
            # any open tags, which should not be true at this point.)
            while len(open_tags) > 0 and t['tag'] != open_tags[-1]['tag']:
                o_tag = open_tags.pop()
                output.append(_closeTag(o_tag))
                tags_to_reopen.append(o_tag)

            # Close the annotation.
            output.append(_closeTag(t))
            open_tags.pop()

            # Reopen annotations that were closed to prevent overlap.
            while len(tags_to_reopen) > 0:
                o_tag = tags_to_reopen.pop()
                output.append(_openTag(o_tag))
                open_tags.append(o_tag)

        # Open the tags that start at this point.
        for t in tags_to_open:
            output.append(_openTag(t))
            # Unless the tag also closes at this point, add it to the stack of
            # open tags. Otherwise, close it.
            if t['start'] != t['end']:
                open_tags.append(t)
            else:
                output.append(_closeTag(t))

        # Add the escaped segment text content, but track the length of the
        # original text to preserve annotation positions.
        output.append(cgi.escape(seg_text))
        i += len(seg_text)

    # Close any tags that are still open (should only be any that are set to
    # end at the end of the target string).
    while open_tags:
        o_tag = open_tags.pop()
        output.append(_closeTag(o_tag))


    return u''.join(output)



