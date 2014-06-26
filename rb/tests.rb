# encoding: utf-8

$passed = 0
$failed = 0

def assertEqual(name, value, expected)
    $failed += 1
    raise "#{name}: #{value} != #{expected}" unless value == expected
    $passed += 1
    $failed -= 1
end


require './noat.rb'


markup = NOAT.new('')
target = ''
assertEqual('emptyString', markup.to_s(), target)



markup = NOAT.new('')
target = '<em></em>'
markup.add('em', 0)
assertEqual('emptyStringWithAnnotation', markup.to_s(), target)



markup = NOAT.new('0123456789')
target = '0123456789'
assertEqual('noAnnotations', markup.to_s(), target)



markup = NOAT.new('0123456789')
target = '012<em>3456</em>789'
markup.add('em', 3, 7)
assertEqual('singleAnnotationSubstring', markup.to_s(), target)


markup = NOAT.new('0123456789é')
target = '012<em>3456</em>789é'
markup.add('em', 3, 7)
assertEqual('singleAnnotationUnicode', markup.to_s(), target)


markup = NOAT.new('0123456789')
target = '0<a href="/">123</a>456789'
markup.add('a', 1, 4, {:href => '/'})
assertEqual('singleAnnotationWithSingleAttribute', markup.to_s(), target)



markup = NOAT.new('0123456789')
target = '0<a class="é">123</a>456789'
markup.add('a', 1, 4, {:class => 'é'})
assertEqual('singleAnnotationWithUnicodeAttribute', markup.to_s(), target)



markup = NOAT.new('0123456789')
target = '0<a href="?foo=false&amp;bar=true">123</a>456789'
markup.add('a', 1, 4, {:href => '?foo=false&bar=true'})
assertEqual('singleAnnotationWithEntityAttribute', markup.to_s(), target)



markup = NOAT.new('0123456789')
target = '0<a href="/" id="foo">123</a>456789'
markup.add('a', 1, 4, {:href => '/', :id => 'foo'})
assertEqual('singleAnnotationWithMultipleAttributes', markup.to_s(), target)



markup = NOAT.new('0123456789')
target = '<strong>0123456789</strong>'
markup.add('strong', 0, 10)
assertEqual('singleAnnotationEntireString', markup.to_s(), target)


markup = NOAT.new('0123456789')
target = '<strong>012</strong>345<em>67</em>89'
markup.add('strong', 0, 3)
markup.add('em', 6, 8)
assertEqual('multipleNonOverlappingAnnotations', markup.to_s(), target)


markup = NOAT.new('0123456789')
target = '0<a href="/">12<em>3</em></a><em>456</em>789'
markup.add('a', 1, 4, {:href => '/'})
markup.add('em', 3, 7)
assertEqual('multipleOverlappingAnnotations', markup.to_s(), target)


markup = NOAT.new('0123456789')
target = '0<a href="/">123</a><em>456</em>789'
markup.add('a', 1, 4, {:href => '/'})
markup.add('em', 4, 7)
assertEqual('multipleAdjacentAnnotations', markup.to_s(), target)


markup = NOAT.new('0123456789')
target = '0123<em>45</em>6789'
markup.add('em', 4.1, 6.8)
assertEqual('floatsAsRange', markup.to_s(), target)


markup = NOAT.new('0123456789')
target = '0123<span class="marker"></span>456789'
markup.add('span', 4, { :class => 'marker' })
assertEqual('collapsedRange', markup.to_s(), target)


markup = NOAT.new('0123456789')
target = '0123<span class="marker">4</span>56789'
markup.add('span', 4, 5, { '_class' => 'marker' })
assertEqual('substituteClass', markup.to_s(), target)



markup = NOAT.new('0123<&6789')
target = '012<em>3&lt;&amp;6</em>789'
markup.add('em', 3, 7)
assertEqual('singleAnnotationAndEscaping', markup.to_s(), target)



markup = NOAT.new('0123456789')
begin
    markup.add('em', 7, 4)
rescue Exception => e
    assertEqual('backwardStartEnd', e.to_s(), 'start (7) must be <= end (4)')
else
    raise 'Did not raise an exception'
end



markup = NOAT.new('0123456789')
begin
    markup.add('em', -3, 4)
rescue Exception => e
    assertEqual('invalidStartRange', e.to_s(), 'start (-3) must be >= 0')
else
    raise 'Did not raise an exception'
end



markup = NOAT.new('0123456789')
begin
    markup.add('em', 5, 100)
rescue Exception => e
    assertEqual('invalidEndRange', e.to_s(), 'end (100) must be <= length of text (10)')
else
    raise 'Did not raise an exception'
end






print $passed, ' passed'
puts ''
print $failed, ' failed'
puts ''

