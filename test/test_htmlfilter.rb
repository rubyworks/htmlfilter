require './test/helper.rb'

require "htmlfilter"

class TestHTMLFilter < MicroTest::TestCase

  # core tests

  def test_strip_single
    hf = HTMLFilter.new
    hf.send(:strip_single,'\"').assert == '"'
    hf.send(:strip_single,'\0').assert == "\000"
  end

  # functional tests

  def assert_filter(filtered, original)
    original.html_filter.assert == filtered
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

  def test_multiline_strings
    assert_filter "<b>\nbold\n</b>", "<b>\nbold\n</b>"
  end
end
