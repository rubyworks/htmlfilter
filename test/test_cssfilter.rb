require './test/helper.rb'

require "cssfilter"

class TestCSSFilter < MicroTest::TestCase

  def setup
    @css = <<-END
      * {
        margin: 0;
        height: 0;
      }

      body {
        margin: 0;
        height: 0;
        background: url(http://xzy.org);
      }

      h1 {
        trythis: url(http://here.org/fun.js);
        font-size: 12pt;
      }
    END
    @result = "* {\nmargin: 0;\nheight: 0;\n}\nbody {\nmargin: 0;\nheight: 0;\n}\nh1 {\ntrythis: url(http://here.org/fun.js);\nfont-size: 12pt;\n}"
  end

  def test_filter
    cssfilter = CSSFilter.new(:allowed_hosts=>["here.org"], :strip_whitespace => true)
    csstree   = cssfilter.filter(@css)

    csstree.to_s.assert == @result
  end

end

