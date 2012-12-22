# NOAT: Non-Overlapping Annotation Tagging

NOAT is a helper class for inserting annotations as HTML tags at arbitary points in text, based on their start and end positions, while avoiding overlapping open and close tags of different type (invalid HTML).

The text is broken into segments, bounded by the start and end points of all of the annotations. It is then reassembled, with opening and closing tags for annotations inserted between the segments. Tags are closed and reopened as needed to prevent overlap.

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

Simply inserting the tags at the given `start` and `end` positions would result in invalid HTML:

```html
Duis <em>mollis, est non<strong> commodo l</em>uctus, nisi erat por</strong>ttitor ligula, eget lacinia odio sem nec elit.
```

The correct output is:

```html
Duis <em>mollis, est non<strong> commodo l</strong></em><strong> uctus, nisi erat por</strong>ttitor ligula, eget lacinia odio sem nec elit.
```

Note that the `</strong>` tag before the `strong`'s `end`, to allow the `emphasis` annotation to be closed without overlapping the `<strong>`. The `strong` annotation is then reopened with a `<strong>` and then closed at its actual end.



## Usage

NOAT is available in three flavors: Python, CoffeeScript, and Ruby. The API is basically the same, with some slight differences for language variations. In every case, the adding of annotations is lazy, so the actual markup is not generated until the `__str__`, `toString`, or `to_s` method is called.

There are no dependencies, and even the tests can just be run directly, eg `python tests.py`.

### `.add`

Python: `.add(tag, start, end, **attributes)`
CoffeeScript: `.add(tag, start, end, attributes={})`
Ruby: `.add(tag, start, end, attributes={})`

`tag` can be any string. `start` and `end` are integers describing the start and end positions of the annotations (inclusive). `end` is optional, allowing for 'collapsed' tags, (eg 'abcd<span><span>efgh'). Attributes are an object/dict/hash (CoffeeScript/Python/Ruby) of key-value attributes to be added to the tag, eg `<a href="http://example.com"></span>`. Python can also accept keyword arguments (which supersede any dict attributes).

For convenience, since `class` is a reserved word but a common annotation attribute, the attribute key `'_class'` will be converted to `'class'`, allowing for Python keyword arguments to be written as `_class="marker"`.

### Python

```python
>>> from noat import NOAT
>>> some_text = 'Lorem ipsum dolor sit amet.'
>>> markup = NOAT(some_text)
>>> markup.add('em', 5, 15)
>>> markup.add('a', 4, 10, href='http://example.com')
>>> str(markup)
'Lore<a href="http://example.com">m<em> ipsu</em></a><em>m dol</em>or sit amet.'
```

### CoffeeScript

```coffeescript
coffee> NOAT = require './noat'
coffee> some_text = 'Lorem ipsum dolor sit amet.'
coffee> markup = new NOAT(some_text)
coffee> markup.add('em', 5, 15)
coffee> markup.add('a', 4, 10, {href:'http://example.com'})
coffee> markup.toString()
'Lore<a href="http://example.com">m<em> ipsu</em></a><em>m dol</em>or sit amet.'
```

### Ruby

```ruby
irb(main):001:0> NOAT = require './noat.rb'
irb(main):002:0> some_text = 'Lorem ipsum dolor sit amet.'
irb(main):003:0> markup = NOAT.new(some_text)
irb(main):004:0> markup.add('em', 5, 15)
irb(main):005:0> markup.add('a', 4, 10, {:href => 'http://example.com'})
irb(main):006:0> markup.to_s()
=> "Lore<a href=\"http://example.com\">m<em> ipsu</em></a><em>m dol</em>or sit amet."
```


## Authors

* [Alec Perkins](https://github.com/alecperkins) ([Droptype Inc](http://droptype.com))



## License

Unlicensed aka Public Domain. See /UNLICENSE for more information.

