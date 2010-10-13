require File.dirname(__FILE__) + '/helper.rb'

require "test/unit"
require "htmlfilter"

class TestHTMLFilter < Test::Unit::TestCase

  # core tests

  def test_strip_single
    hf = HTMLFilter.new
    assert_equal( '"', hf.send(:strip_single,'\"') )
    assert_equal( "\000", hf.send(:strip_single,'\0') )
  end

  # functional tests

  def assert_filter(filtered, original)
    assert_equal(filtered, original.html_filter)
  end

  def test_fix_quotes
    assert_filter '<img src="foo.jpg" />', "<img src=\"foo.jpg />"
  end

  def test_basics
    assert_filter '', ''
    assert_filter 'hello', 'hello'
  end

  def test_balancing_tags
    assert_filter "<b>hello</b>", "<<b>hello</b>"
    assert_filter "<b>hello</b>", "<b>>hello</b>"
    assert_filter "<b>hello</b>", "<b>hello<</b>"
    assert_filter "<b>hello</b>", "<b>hello</b>>"
    assert_filter "", "<>"
  end

  def test_tag_completion
    assert_filter "hello", "hello<b>"
    assert_filter "<b>hello</b>", "<b>hello"
    assert_filter "hello<b>world</b>", "hello<b>world"
    assert_filter "hello", "hello</b>"
    assert_filter "hello", "hello<b/>"
    assert_filter "hello<b>world</b>", "hello<b/>world"
    assert_filter "<b><b><b>hello</b></b></b>", "<b><b><b>hello"
    assert_filter "", "</b><b>"
  end

  def test_end_slashes
    assert_filter '<img />', '<img>'
    assert_filter '<img />', '<img/>'
    assert_filter '', '<b/></b>'
  end

end
