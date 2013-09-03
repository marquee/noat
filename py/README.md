# NOAT: Non-Overlapping Annotation Tagging

NOAT ("note") is a helper class for inserting reference-based annotations as
HTML tags at arbitary points in text, based on their start and end positions,
while avoiding overlapping open and close tags of different type (invalid HTML).
This ensures creating a well-formed HTML document that will yield a properly
structured DOM.

The text is broken into segments, bounded by the start and end points of all of
the annotations. It is then reassembled, with opening and closing tags for
annotations inserted between the segments. Tags are closed and reopened as
needed to prevent overlap.

For example, given:

```python
text = "Duis mollis, est non commodo luctus, nisi erat porttitor ligula, eget lacinia odio sem nec elit."

annotations = [{
    'type': 'emphasis',
    'start': 5,
    'end': 30,
},{
    'type': 'strong',
    'start': 20,
    'end': 50,
}]
```

Simply inserting the tags at the given `start` and `end` positions would result
in invalid HTML:

```html
Duis <em>mollis, est non<strong> commodo l</em>uctus, nisi erat por</strong>
ttitor ligula, eget lacinia odio sem nec elit.
```

The correct output is:

```html
Duis <em>mollis, est non<strong> commodo l</strong></em><strong> uctus, nisi
erat por</strong>ttitor ligula, eget lacinia odio sem nec elit.
```

Note that `</strong>` tag before the `strong`'s `end`, to allow the `emphasis`
annotation to be closed without overlapping the `<strong>`. The `strong`
annotation is then reopened with a `<strong>` and then closed at its actual end.



## Usage

There are no dependencies. NOAT works in both Python 2 and 3, and PyPy. The
adding of annotations is lazy, so the actual markup is not generated until the
`__str__` method is called.

```python
>>> from noat import NOAT
>>> some_text = 'Lorem ipsum dolor sit amet.'
>>> markup = NOAT(some_text)
>>> markup.add('em', 5, 15)
>>> markup.add('a', 4, 10, href='http://example.com')
>>> str(markup)
'Lore<a href="http://example.com">m<em> ipsu</em></a><em>m dol</em>or sit amet.'
```

### `NOAT`

The `NOAT` constructor takes a string and returns a NOAT instance, which can
then have annotations added to it.

### `.add`

    markup.add(tag, start, [end,] [attributes,] [**attributes])

`tag` can be any string. `start` and `end` are integers describing the start and
end positions of the annotations (inclusive). `end` is optional, allowing for
'collapsed' tags, (eg `abcd<span></span>efgh`). Attributes are a dict of
key-value attributes to be added to the tag, eg
`<a href="http://example.com">link</a>`. Keyword arguments can also be provided,
(which supersede any dict attributes).

For convenience, since `class` is a reserved word but a common annotation
attribute, the attribute key `'_class'` will be converted to `'class'`, allowing
for keyword arguments to be written as `_class="marker"`.




## Authors

* [Alec Perkins](https://github.com/alecperkins) ([Droptype Inc](http://droptype.com))



## License

Unlicensed aka Public Domain. See /UNLICENSE for more information.


