# = HTML Filter
#
# HTML Filter library can be used to sanitize and sterilize
# HTML. A good idea if you let users submit HTML in comments,
# for instance.
#
# HtmlFilter is a port of lib_filter.php, v1.15 by Cal Henderson <cal@iamcal.com>
# licensed under a Creative Commons Attribution-ShareAlike 2.5 License
# http://creativecommons.org/licenses/by-sa/3.0/.
#
# == Usage
#
#   hf = HTMLFilter.new
#   hf.filter("<b>Bold Action")  #=> "<b>Bold Action</b>"
#
# == Reference
#
# * http://iamcal.com/publish/articles/php/processing_html/
# * http://iamcal.com/publish/articles/php/processing_html_part_2/
#
# == Issues
#
# * The built in option constants could use some refinement.
#
# == Copying
#
# Copyright (c) 2009 Thomas Sawyer, Rubyworks (BSD-2-Clause)
#
# Thanks to Jang Kim for adding support for single quoted attributes.

class HTMLFilter

  # Library version.
  VERSION = "1.2.0"  # :till: VERSION = "<%= version %>"

  # tags and attributes that are allowed
  #
  # Eg.
  #
  #   {
  #     'a' => ['href', 'target'],
  #     'b' => [],
  #     'img' => ['src', 'width', 'height', 'alt']
  #   }
  attr_accessor :allowed

  # tags which should always be self-closing (e.g. "<img />")
  attr_accessor :no_close

  # tags which must always have seperate opening and closing
  # tags (e.g. "<b></b>")
  attr_accessor :always_close

  # attributes which should be checked for valid protocols
  # (src,href)
  attr_accessor :protocol_attributes

  # protocols which are allowed (http, ftp, mailto)
  attr_accessor :allowed_protocols

  # tags which should be removed if they contain no content
  # (e.g. "<b></b>" or "<b />")
  attr_accessor :remove_blanks

  # should we remove comments? (true, false)
  attr_accessor :strip_comments

  # should we try and make a <b> tag out of "b>" (true, false)
  attr_accessor :always_make_tags

  # entity control option (true, false)
  attr_accessor :allow_numbered_entities

  # entity control option (amp, gt, lt, quot, etc.)
  attr_accessor :allowed_entities

  ## max number of text characters at which to truncate (leave as +nil+ for no truncation)
  #attr_accessor :truncate

  # Default settings
  DEFAULT = {
    'allowed' => {
      'a'   => ['href', 'target'],
      'img' => ['src', 'width', 'height', 'alt'],
      'b'   => [],
      'i'   => [],
      'em'  => [],
      'tt'  => [],
    },
    'no_close' => ['img', 'br', 'hr'],
    'always_close' => ['a', 'b'],
    'protocol_attributes' => ['src', 'href'],
    'allowed_protocols' => ['http', 'ftp', 'mailto'],
    'remove_blanks' => ['a', 'b'],
    'strip_comments' => true,
    'always_make_tags' => true,
    'allow_numbered_entities' => true,
    'allowed_entities' => ['amp', 'gt', 'lt', 'quot']
  }

  # Basic settings are simlialr to DEFAULT but do not allow any type
  # of links, neither <tt>a href</tt> or <tt>img</tt>.
  BASIC = {
    'allowed' => {
      'b'   => [],
      'i'   => [],
      'em'  => [],
      'tt'  => [],
    },
    'no_close' => ['img', 'br', 'hr'],
    'always_close' => ['a', 'b'],
    'protocol_attributes' => ['src', 'href'],
    'allowed_protocols' => ['http', 'ftp', 'mailto'],
    'remove_blanks' => ['a', 'b'],
    'strip_comments' => true,
    'always_make_tags' => true,
    'allow_numbered_entities' => true,
    'allowed_entities' => ['amp', 'gt', 'lt', 'quot']
  }

  # Strict settings do not allow any tags.
  STRICT = {
    'allowed' => {},
    'no_close' => ['img', 'br', 'hr'],
    'always_close' => ['a', 'b'],
    'protocol_attributes' => ['src', 'href'],
    'allowed_protocols' => ['http', 'ftp', 'mailto'],
    'remove_blanks' => ['a', 'b'],
    'strip_comments' => true,
    'always_make_tags' => true,
    'allow_numbered_entities' => true,
    'allowed_entities' => ['amp', 'gt', 'lt', 'quot']
  }

  # Relaxed settings allows a great deal of HTML spec.
  #
  # TODO: Need to expand upon RELAXED options.
  #
  RELAXED = {
    'allowed' => {
      'a'    => ['class', 'href', 'target'],
      'b'    => ['class'],
      'i'    => ['class'],
      'img'  => ['class', 'src', 'width', 'height', 'alt'],
      'div'  => ['class'],
      'pre'  => ['class'],
      'code' => ['class'],
      'ul'   => ['class'], 'ol' => ['class'], 'li' => ['class']
    },
    'no_close' => ['img', 'br', 'hr'],
    'always_close' => ['a', 'b'],
    'protocol_attributes' => ['src', 'href'],
    'allowed_protocols' => ['http', 'ftp', 'mailto'],
    'remove_blanks' => ['a', 'b'],
    'strip_comments' => true,
    'always_make_tags' => true,
    'allow_numbered_entities' => true,
    'allowed_entities' => ['amp', 'gt', 'lt', 'quot']
  }

  # New html filter.
  #
  # Provide custom +options+, or use one of the built-in options
  # constants.
  #
  #   hf = HTMLFilter.new(HTMLFilter::RELAXED)
  #   hf.filter(htmlstr)
  #
  def initialize(options=nil)
    if options
      h = DEFAULT.dup
      options.each do |k,v|
        h[k.to_s] = v
      end
      options = h
    else
      options = DEFAULT.dup
    end
    options.each{ |k,v| send("#{k}=",v) }
  end

  # Filter html string.
  #
  def filter(html)
    @tag_counts = {}
    html = escape_comments(html)
    html = balance_html(html)
    html = check_tags(html)
    html = process_remove_blanks(html)
    html = validate_entities(html)
    #html = truncate_html(html)
    html
  end

  private

  #
  # internal tag counter
  #

  def tag_counts ; @tag_counts; end

  #
  #
  #

  def escape_comments(data)
    data = data.gsub(/<!--(.*?)-->/s) do
      '<!--' + escape_special_chars(strip_single($1)) + '-->'
    end

    return data
  end

  #
  #
  #

  def balance_html(data)
    data = data.dup

    if always_make_tags
      # try and form html
      data.gsub!(/>>+/, '>')
      data.gsub!(/<<+/, '<')
      data.gsub!(/^>/, '')
      data.gsub!(/<([^>]*?)(?=<|$)/, '<\1>')
      data.gsub!(/(^|>)([^<]*?)(?=>)/, '\1<\2')
    else
      # escape stray brackets
      data.gsub!(/<([^>]*?)(?=<|$)/, '&lt;\1')
      data.gsub!(/(^|>)([^<]*?)(?=>)/, '\1\2&gt;<')
      # the last regexp causes '<>' entities to appear
      # (we need to do a lookahead assertion so that the last bracket
      # can be used in the next pass of the regexp)
      data.gsub!('<>', '')
    end

    return data
  end

  #
  #
  #

  def check_tags(data)
    data = data.dup

    data.gsub!(/<(.*?)>/s){
      process_tag(strip_single($1))
    }

    tag_counts.each do |tag, cnt|
        cnt.times{ data << "</#{tag}>" }
    end

    return data
  end

  #
  #
  #

  def process_tag(data)

    # ending tags

    re = /^\/([a-z0-9]+)/si

    if matches = re.match(data)
        name = matches[1].downcase
        if allowed.key?(name)
            unless no_close.include?(name)
                if tag_counts[name]
                    tag_counts[name] -= 1
                    return "</#{name}>"
                end
            end
        else
            return ''
        end
    end

    # starting tags

    re = /^([a-z0-9]+)(.*?)(\/?)$/si

    if matches = re.match(data)
        name   = matches[1].downcase
        body   = matches[2]
        ending = matches[3]

        if allowed.key?(name)
            params = ""

            matches_2 = body.scan(/([a-z0-9]+)=(["'])(.*?)\2/si)         # <foo a="b" />
            matches_1 = body.scan(/([a-z0-9]+)(=)([^"\s']+)/si)          # <foo a=b />
            matches_3 = body.scan(/([a-z0-9]+)=(["'])([^"']*?)\s*$/si)   # <foo a="b />

            matches = matches_1 + matches_2 + matches_3

            matches.each do |match|
                pname = match[0].downcase
                if allowed[name].include?(pname)
                    value = match[2]
                    if protocol_attributes.include?(pname)
                        value = process_param_protocol(value)
                    end
                    params += %{ #{pname}="#{value}"}
                end
            end
            if no_close.include?(name)
                ending = ' /'
            end
            if always_close.include?(name)
                ending = ''
            end
            if ending.empty?
                if tag_counts.key?(name)
                    tag_counts[name] += 1
                else
                    tag_counts[name] = 1
                end
            end
            unless ending.empty?
                ending = ' /'
            end
            return '<' + name + params + ending + '>'
        else
            return ''
        end
    end

    # comments
    if /^!--(.*)--$/si =~ data
        if strip_comments
            return ''
        else
            return '<' + data + '>'
        end
    end

    # garbage, ignore it
    return ''
  end

  #
  #
  #

  def process_param_protocol(data)
    data = decode_entities(data)

    re = /^([^:]+)\:/si

    if matches = re.match(data)
        unless allowed_protocols.include?(matches[1])
            #data = '#'.substr(data, strlen(matches[1])+1)
            data = '#' + data[0..matches[1].size+1]
        end
    end

    return data
  end

  #
  #
  #

  def process_remove_blanks(data)
    data = data.dup

    remove_blanks.each do |tag|
        data.gsub!(/<#{tag}(\s[^>]*)?><\/#{tag}>/, '')
        data.gsub!(/<#{tag}(\s[^>]*)?\/>/, '')
    end

    return data
  end

  #
  #
  #

  def fix_case(data)
    data_notags = strip_tags(data)
    data_notags = data_notags.gsub(/[^a-zA-Z]/, '')

    if data_notags.size < 5
        return data
    end

    if /[a-z]/ =~ data_notags
        return data
    end

    data = data.gsub(/(>|^)([^<]+?)(<|$)/s){
        strip_single($1) +
        fix_case_inner(strip_single($2)) +
        strip_single($3)
    }

    return data
  end

  #
  #
  #

  def fix_case_inner(data)
    data = data.dup

    data.downcase!

    data.gsub!(/(^|[^\w\s\';,\\-])(\s*)([a-z])/){
        strip_single("#{$1}#{$2}") + strip_single($3).upcase
    }

    return data
  end

  #
  #
  #

  def validate_entities(data)
    data = data.dup

    # validate entities throughout the string
    data.gsub!(%r!&([^&;]*)(?=(;|&|$))!){
        check_entity(strip_single($1), strip_single($2))
    }

    # validate quotes outside of tags
    data.gsub!(/(>|^)([^<]+?)(<|$)/s){
        m1, m2, m3 = $1, $2, $3
        strip_single(m1) +
        strip_single(m2).gsub('\"', '&quot;') +
        strip_single(m3)
    }

    return data
  end

  #
  #
  #

  def check_entity(preamble, term)
    if term != ';'
        return '&amp;' + preamble
    end

    if is_valid_entity(preamble)
        return '&' + preamble
    end

    return '&amp;' + preamble
  end

  #
  #
  #

  def is_valid_entity(entity)
    re = /^#([0-9]+)$/i

    if md = re.match(entity)
        if (md[1].to_i > 127)
            return true
        end
        return allow_numbered_entities
    end

    if allowed_entities.include?(entity)
        return true
    end

    return nil
  end

  # within attributes, we want to convert all hex/dec/url
  # escape sequences into their raw characters so that we can
  # check we don't get stray quotes/brackets inside strings.

  def decode_entities(data)
    data = data.dup

    data.gsub!(/(&)#(\d+);?/){ decode_dec_entity($1, $2) }
    data.gsub!(/(&)#x([0-9a-f]+);?/i){ decode_hex_entity($1, $2) }
    data.gsub!(/(%)([0-9a-f]{2});?/i){ decode_hex_entity($1, $2) }

    data = validate_entities(data)

    return data
  end

  #
  #
  #

  def decode_hex_entity(*m)
    return decode_num_entity(m[1], m[2].to_i.to_s(16))
  end

  #
  #
  #

  def decode_dec_entity(*m)
    return decode_num_entity(m[1], m[2])
  end

  #
  #
  #

  def decode_num_entity(orig_type, d)
    d = d.to_i
    d = 32 if d < 0   # space

    # don't mess with high chars
    if d > 127
        return '%' + d.to_s(16) if orig_type == '%'
        return "&#{d};" if orig_type == '&'
    end

    return escape_special_chars(d.chr)
  end

  #
  #
  #

  def strip_single(data)
    return data.gsub('\"', '"').gsub('\0', 0.chr)
  end

  # Certain characters have special significance in HTML, and
  # should be represented by HTML entities if they are to
  # preserve their meanings. This function returns a string
  # with some of these conversions made; the translations made
  # are those most useful for everyday web programming.

  def escape_special_chars(data)
    data = data.dup
    data.gsub!( /&/n  , '&amp;' )
    data.gsub!( /\"/n , '&quot;' )
    data.gsub!( />/n  , '&gt;' )
    data.gsub!( /</n  , '&lt;' )
    data.gsub!( /'/   , '&#039;' )
    return data
  end

  ## HTML comment regular expression
  #REM_RE = %r{<\!--(.*?)-->}
  #
  ## HTML tag regular expression
  #TAG_RE = %r{</?\w+((\s+\w+(\s*=\s*(?:"(.|\n)*?"|'(.|\n)*?'|[^'">\s]+))?)+\s*|\s*)/?>}    #'
  #
  ##
  #def truncate_html(html)
  #  return html unless truncate
  #  # default settings
  #  limit = truncate
  #
  #  mask = html.gsub(REM_RE){ |m| "\0" * m.size }
  #  mask = mask.gsub(TAG_RE){ |m| "\0" * m.size }
  #
  #  i, x = 0, 0
  #
  #  while i < mask.size && x < limit
  #    x += 1 if mask[i] != "\0"
  #    i += 1
  #  end
  #
  #  while x > 0 && mask[x,1] == "\0"
  #    x -= 1
  #  end
  #
  #  return html[0..x]
  #end

end

# Overload the standard String class for extra convienience.

class String
  def html_filter(*opts)
    HTMLFilter.new(*opts).filter(self)
  end
end

