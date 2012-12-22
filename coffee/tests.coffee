NOAT = require './noat'

{ok, equal} = require 'assert'


oldOk = ok
ok = ->
    oldOk(arguments...)
    console.log('.')

oldEqual = equal
equal = ->
    oldEqual(arguments...)
    console.log('.')

passed = []
failed = []

SOLO = false

test = (name, fn) ->
    if not SOLO or name is SOLO
        try
            fn()
            passed.push(name)
        catch e
            console.log('F', name)
            failed.push([name, e])



test 'noAnnotations', ->
    markup = new NOAT('0123456789')
    target = '0123456789'
    equal(markup.toString(), target)


test 'singleAnnotationSubstring', ->
    markup = new NOAT('0123456789')
    target = '012<em>3456</em>789'
    markup.add('em', 3, 7)
    equal(markup.toString(), target)



test 'singleAnnotationUnicode', ->
    markup = new NOAT('0123456789é')
    target = '012<em>3456</em>789é'
    markup.add('em', 3, 7)
    equal(markup.toString(), target)



test 'singleAnnotationWithSingleAttribute', ->
    markup = new NOAT('0123456789')
    target = '0<a href="/">123</a>456789'
    markup.add('a', 1, 4, {href:'/'})
    equal(markup.toString(), target)



test 'singleAnnotationWithMultipleAttributes', ->
    markup = new NOAT('0123456789')
    target = '0<a href="/" id="foo">123</a>456789'
    markup.add('a', 1, 4, {href:'/', id:'foo'})
    equal(markup.toString(), target)



test 'singleAnnotationEntireString', ->
    markup = new NOAT('0123456789')
    target = '<strong>0123456789</strong>'
    markup.add('strong', 0, 10)
    equal(markup.toString(), target)



test 'multipleNonOverlappingAnnotations', ->
    markup = new NOAT('0123456789')
    target = '<strong>012</strong>345<em>67</em>89'
    markup.add('strong', 0, 3)
    markup.add('em', 6, 8)
    equal(markup.toString(), target)



test 'multipleOverlappingAnnotations', ->
    markup = new NOAT('0123456789')
    target = '0<a href="/">12<em>3</em></a><em>456</em>789'
    markup.add('a', 1, 4, {href:'/'})
    markup.add('em', 3, 7)
    equal(markup.toString(), target)



test 'multipleAdjacentAnnotations', ->
    markup = new NOAT('0123456789')
    target = '0<a href="/">123</a><em>456</em>789'
    markup.add('a', 1, 4, {href:'/'})
    markup.add('em', 4, 7)
    equal(markup.toString(), target)



test 'floatsAsRange', ->
    markup = new NOAT('0123456789')
    target = '0123<em>45</em>6789'
    markup.add('em', 4.1, 6.8)
    equal(markup.toString(), target)



test 'collapsedRange', ->
    markup = new NOAT('0123456789')
    target = '0123<span class="marker"></span>456789'
    attrs = { 'class': 'marker' }
    markup.add('span', 4, attrs)
    equal(markup.toString(), target)



test 'substituteClass', ->
    markup = new NOAT('0123456789')
    target = '0123<span class="marker">4</span>56789'
    attrs = { _class: 'marker' }
    markup.add('span', 4, 5, attrs)
    equal(markup.toString(), target)




test 'backwardStartEnd', ->
    markup = new NOAT('0123456789')
    try
        markup.add('em', 7, 4)
    catch e
        equal(e.toString(), 'Error: start (7) must be <= end (4)')



test 'invalidStartRange', ->
    markup = new NOAT('0123456789')
    try
        markup.add('em', -3, 4)
    catch e
        equal(e, 'Error: start (-3) must be >= 0')



test 'invalidEndRange', ->
    markup = new NOAT('0123456789')
    try
        markup.add('em', 5, 100)
    catch e
        equal(e, 'Error: end (100) must be <= length of text (10)')




for t in failed
    console.log '\n'
    console.log t

console.log "\nPassed #{ passed.length } tests"
console.log "Failed #{ failed.length } tests"