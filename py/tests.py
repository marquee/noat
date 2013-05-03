# coding: utf-8

from __future__ import print_function, unicode_literals

from noat import NOAT


def checkMarkupAsString(markup, target):
    try:
        # Allow for multiple targets since the attributes may be ordered
        # differently, but still correct.
        if not hasattr(target, '__iter__'):
            target = [target]
        # Call the __str__ directly because of py2/py3 compatibility.
        assert(markup.__str__() in target)
    except AssertionError:
        raise AssertionError('"%s"' % (markup,) + ' does not equal ' + '"%s"' % (target,))



def test_noAnnotations():
    markup = NOAT('0123456789')
    target = '0123456789'
    checkMarkupAsString(markup, target)



def test_singleAnnotationSubstring():
    markup = NOAT('0123456789')
    target = '012<em>3456</em>789'
    markup.add('em', 3, 7)
    checkMarkupAsString(markup, target)



def test_singleAnnotationUnicode():
    markup = NOAT('0123456789é')
    target = '012<em>3456</em>789é'
    markup.add('em', 3, 7)
    checkMarkupAsString(markup, target)



def test_singleAnnotationWithSingleAttribute():
    markup = NOAT('0123456789')
    target = '0<a href="/">123</a>456789'
    markup.add('a', 1, 4, href='/')
    checkMarkupAsString(markup, target)



def test_singleAnnotationWithMultipleAttributes():
    markup = NOAT('0123456789')
    target_a = '0<a href="/" id="foo">123</a>456789'
    target_b = '0<a id="foo" href="/">123</a>456789'
    markup.add('a', 1, 4, href='/', id='foo')
    checkMarkupAsString(markup, [target_a, target_b])



def test_singleAnnotationEntireString():
    markup = NOAT('0123456789')
    target = '<strong>0123456789</strong>'
    markup.add('strong', 0, 10)
    checkMarkupAsString(markup, target)



def test_multipleNonOverlappingAnnotations():
    markup = NOAT('0123456789')
    target = '<strong>012</strong>345<em>67</em>89'
    markup.add('strong', 0, 3)
    markup.add('em', 6, 8)
    checkMarkupAsString(markup, target)



def test_multipleOverlappingAnnotations():
    markup = NOAT('0123456789')
    target = '0<a href="/">12<em>3</em></a><em>456</em>789'
    markup.add('a', 1, 4, href='/')
    markup.add('em', 3, 7)
    checkMarkupAsString(markup, target)



def test_multipleAdjacentAnnotations():
    markup = NOAT('0123456789')
    target = '0<a href="/">123</a><em>456</em>789'
    markup.add('a', 1, 4, href='/')
    markup.add('em', 4, 7)
    checkMarkupAsString(markup, target)



def test_backwardStartEnd():
    markup = NOAT('0123456789')
    try:
        markup.add('em', 7, 4)
    except IndexError:
        assert True
    else:
        assert AssertionError('Did not raise IndexError')



def test_invalidStartRange():
    markup = NOAT('0123456789')
    try:
        markup.add('em', -3, 4)
    except IndexError:
        assert True
    else:
        assert AssertionError('Did not raise IndexError')



def test_invalidEndRange():
    markup = NOAT('0123456789')
    try:
        markup.add('em', 5, 100)
    except IndexError:
        assert True
    else:
        assert AssertionError('Did not raise IndexError')



def test_floatsAsRange():
    markup = NOAT('0123456789')
    target = '0123<em>45</em>6789'
    markup.add('em', 4.1, 6.8)
    checkMarkupAsString(markup, target)




def test_collapsedRange():
    markup = NOAT('0123456789')
    target = '0123<span class="marker"></span>456789'
    attrs = { 'class': 'marker' }
    markup.add('span', 4, **attrs)
    checkMarkupAsString(markup, target)



def test_substituteClass():
    markup = NOAT('0123456789')
    target = '0123<span class="marker">4</span>56789'
    markup.add('span', 4, 5, _class='marker')
    checkMarkupAsString(markup, target)


def test_attributesAsDict():
    markup = NOAT('0123456789')
    target = '0123<span class="marker">4</span>56789'
    markup.add('span', 4, 5, { 'class': 'marker' })
    checkMarkupAsString(markup, target)


def test_attributesAsDictCollapsed():
    markup = NOAT('0123456789')
    target = '0123<span class="marker"></span>456789'
    markup.add('span', 4, { 'class': 'marker' })
    checkMarkupAsString(markup, target)



def test_attributesAsDictAndKwargs():
    markup = NOAT('0123456789')
    target = '0123<span class="foo">4</span>56789'
    markup.add('span', 4, 5, { 'class': 'marker' }, _class='foo')
    checkMarkupAsString(markup, target)




# Microrunner

passed = []
failed = []
for k, v in list(globals().items()):
    if k.find('test_') == 0:
        try:
            v()
        except Exception as e:
            print('F', k)
            failed.append([k, e])
        else:
            print('.')
            passed.append(k)

print(len(passed), 'passed')
print(len(failed), 'failed')
print()

for failure in failed:
    print(failure)