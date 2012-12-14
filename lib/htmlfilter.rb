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
  # Here is a very comprhensive set of tags with attributes.
  #
  RELAXED = {
      'allowed' => {
        'a'  => ['class', 'href', 'target', 'name', 'id', 'style', 'title'],
        'abbr'  => ['class', 'dir', 'lang', 'id', 'style', 'title'],
        'acronym'  => ['class', 'dir', 'lang', 'id', 'style', 'title'],
        'address'  => ['class', 'dir', 'lang', 'id', 'style', 'title'],
        #'applet'  => ['class', 'dir', 'lang', 'id', 'style', 'title'],
        'area' => ['shape', 'cords', 'type', 'nohref', 'href', 'class', 'id', 'style', 'title'],
        'b'  => ['class', 'id', 'style', 'title'],
        'base' => ['target', 'type', 'href'], # NO class, id, style, title
        'basefont' => ['color', 'face', 'size'], # NO class, id, style, title
        'bdo'  => ['class', 'dir', 'lang', 'id', 'style', 'title'],
        'bgsound'  => ['loop', 'src'],
        'big'  => ['class', 'dir', 'lang', 'id', 'style', 'title'],
        'blockquote' => ['class', 'id', 'style', 'title'],
        'body' => ['background', 'bgcolor', 'text', 'link', 'vlink', 'class', 'id', 'style', 'title'],
        'button' => ['disabled', 'name', 'type', 'value', 'accesskey', 'class', 'id', 'style', 'title'],
        'br' => ['clear', 'class', 'id', 'style', 'title'],  # </br> or <br />
        'caption' => ['class', 'align', 'valign', 'id', 'style', 'title'],
        'center' => ['class', 'id', 'style', 'title'],
        'cite' => ['class', 'id', 'style', 'title'],
        'code'=> ['class', 'id', 'style', 'title'],
        'col'  => ['char', 'charoff', 'span', 'class', 'width', 'align', 'valign', 'id', 'style', 'title'],
        'colgroup'  => ['char', 'charoff', 'span', 'class', 'width', 'align', 'valign', 'id', 'style', 'title'],
        'div'  => ['class', 'align', 'style', 'id', 'style', 'title'],
        'dl' => ['class', 'id', 'style', 'title'],
        'dt' => ['class', 'id', 'style', 'title'],
        'dd' => ['class', 'id', 'style', 'title'],
        'em'  => ['class', 'id', 'style', 'title'],
        'frameset' => ['cols', 'rows', 'class', 'id', 'style', 'title'],
        'frame' => ['src', 'name', 'noresize', 'scroll', 'marginwidth', 'marginheight', 'class', 'id', 'style', 'title'],
        'form' => ['method', 'action', 'class', 'id', 'style', 'title'],
        'font' => ['face', 'size', 'color', 'class', 'id', 'style', 'title'],
        'head' => [], # NO class, id, style, title
        'html' => [], # NO class, id, style, title
        'h1' => ['align', 'class', 'id', 'style', 'title'],
        'h2' => ['align', 'class', 'id', 'style', 'title'],
        'h3' => ['align', 'class', 'id', 'style', 'title'],
        'h4' => ['align', 'class', 'id', 'style', 'title'],
        'h5' => ['align', 'class', 'id', 'style', 'title'],
        'h6' => ['align', 'class', 'id', 'style', 'title'],
        'hr' => ['width', 'size', 'noshade', 'class', 'id', 'style', 'title'], #</hr> or <hr />
        'i'  => ['class', 'id', 'style', 'title'],
        'iframe' => ['src', 'name', 'noresize', 'scroll', 'marginwidth', 'marginheight', 'class', 'id', 'style', 'title'],
        'img' => ['src', 'align', 'width', 'height', 'alt', 'border', 'ISMAP', 'class', 'USEMAP', 'id', 'style', 'title'],
        'input' => ['name', 'type', 'class', 'id', 'style', 'title'],
        'li' => ['type', 'start', 'class', 'id', 'style', 'title'],
        'link' => ['rel', 'type', 'href', 'class', 'id', 'style', 'title'],
        'map' => ['name', 'class', 'id', 'style', 'title'],
        'meta' => ['http-equiv', 'content', 'name', 'content'], # NO class, id, style, title
        'noframes' => [],
        'option' => ['class', 'id', 'style', 'title'],
        'ol' => ['type', 'start', 'class', 'id', 'style', 'title'],
        'p'  => ['align', 'class', 'id', 'style', 'title'],
        'param' => [], # NO class, id, style, title
        'pre' => ['class', 'id', 'style', 'title'],
        's'  => ['class', 'id', 'style', 'title'],
        'select' => ['name', 'size', 'class', 'id', 'style', 'title'],
        #'script' => '', # not this for sure
        'span'  => ['class', 'id', 'style', 'title'],
        'strong'  => ['class', 'id', 'style', 'title'],
        'style' => ['type'], # NO class, id, style, title
        'table' => ['class', 'border', 'width', 'height', 'cellpadding', 'cellspacing', 'bgcolor', 'background', 'id', 'style', 'title'],
        'tbody' => ['class', 'align', 'valign', 'id', 'style', 'title'],
        'td' => ['class', 'nowrap', 'width', 'align', 'valign', 'colspan', 'rowspan', 'bgcolor', 'id', 'style', 'title'],
        'textarea' => ['name', 'rows', 'cols', 'class', 'id', 'style', 'title'],
        'tfoot' => ['class', 'align', 'valign', 'id', 'style', 'title'],
        'th' => ['class', 'nowrap', 'width', 'align', 'valign', 'colspan', 'rowspan', 'bgcolor', 'id', 'style', 'title'],
        'thead' => ['class', 'align', 'valign', 'id', 'style', 'title'],
        'title' => [], # NO class, id, style, title
        'tr' => ['class', 'align', 'valign', 'bgcolor', 'id', 'style', 'title'],
        'tt' => ['class', 'id', 'style', 'title'],
        'u'  => ['class', 'id', 'style', 'title'],
        'ul' => ['type', 'class', 'id', 'style', 'title'],
      },
      #'body', 'div', 'span', 'br', 'hr', 'p', 'b', 'i', 'tt', 'h1', 'h2', 'h3', 'h4', 'h5', 'h6', 'font', 'blockquote', 'ul', 'ol', 'li', 'dl', 'dt', 'dd', 'a', 'img', 'map', 'area', 'table', 'tr', 'td', 'th', 'thead', 'tfoot', 'tbody', 'caption', 'frameset', 'frame', 'noframes', 'form', 'input', 'select', 'option', 'textarea', 'link', 'col', 'colgroup', 'u', 's', 'strong', 'em', 'base', 'html', 'head', 'title', 'param', 'script', 'meta', 'style' 
      'no_close' => ['img', 'br', 'hr'],
      'always_close' => ['a', 'b'],
      'protocol_attributes' => ['src', 'href'],
      'allowed_protocols' => ['http', 'ftp', 'mailto', 'https', 'sftp'],
      'remove_blanks' => ['a', 'b'],
      'strip_comments' => false, # comments? <!--  -->
      'always_make_tags' => false,
      'allow_numbered_entities' => true,
      'allowed_entities' => ['amp', 'cent', 'copy', 'deg', 'gt', 'lt', 'nbsp', '#174', '#153', 'pound', 'ndash', '#8211', 'mdash', '#8212', 'iexcl', '#161', 'iquest', '#191', 'quot', '#34', 'ldquo', '#8220', 'rdquo', '#8221', '#39', 'lsquo', '#8216', 'rsquo', '#8217', 'laquo', 'raquo', '#171', '#187', 'nbsp', '#160', 'amp', '#38', 'cent', '#162', 'copy', '#169', 'divide', '#247', 'gt', '#62', 'lt', '#60', 'micro', '#181', 'middot', 'para', '#182', 'plusmn', 'euro', '#8364', 'pound', '#163', 'reg', '#174', 'sect', '#167', 'trade', '#153', 'yen', '#165', 'aacute', 'Aacute', '#225', '#193', 'agrave', 'Agrave', '#224', '#192', 'acirc', 'Acirc', '#226', '#194', 'aring', 'Aring', '#229', '#197', 'atilde', 'Atilde', '#227', '#195', 'auml', 'Auml', '#228', '#196', 'aelig', 'AElig', '#230', '#198', 'ccedil', 'Ccedil', '#231', '#199', 'eacute', 'Eacute', '#233', '#201', 'egrave', 'Egrave', '#232', '#200', 'ecirc', 'Ecirc', '#234', '#202', 'euml', 'Euml', '#235', '#203', 'iacute', 'Iacute', '#237', '#205', 'igrave', 'Igrave', '#236', '#204', 'icirc', 'Icirc', '#238', '#206', 'iuml', 'Iuml', '#239', '#207', 'ntilde', 'Ntilde', '#241', '#209', 'oacute', 'Oacute', '#243', '#211', 'ograve', 'Ograve', '#242', '#210', 'ocirc', 'Ocirc', '#244', '#212', 'oslash', 'Oslash', '#248', '#216', 'otilde', 'Otilde', '#245', '#213', 'ouml', 'Ouml', '#246', '#214', 'szlig', '#223', 'uacute', 'Uacute', '#250', '#218', 'ugrave', 'Ugrave', '#249', '#217', 'ucirc', 'Ucirc', '#251', '#219', 'uuml', 'Uuml', '#252', '#220', 'yuml', '#255', '#180', '#96']
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

