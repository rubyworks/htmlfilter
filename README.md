# HTMLFilter

[Website](http://rubyworks.github.com/htmlfilter) /
[Source Code](http://github.com/rubyworks/htmlfilter)


## Description

HTML Filter library can be used to sanitize and sterilize
HTML. A good idea if you let users submit HTML in comments,
for instance. 

This library also include CSSFilter. The CSSFilter class will
clean-up a cascading style sheet. It can be used to remove
whitespace and most importantly remove URLs.


## Features

* Based on well-worn PHP library.
* Regular expression based filtering.
* Very efficient for small snippets, like blog comments.
* Pure-Ruby and no dependencies.
* Also has library to clean and compact cascading stylesheets.


## Synopsis

Via the class.

  html = "<b>hello</b>"

  HTMLFilter.new(options).filter(html)

Or using the String extension.

  html.html_filter(options)  #=> "<b>hello</b>"

See API documentation for more information.


## Installation

  $ gem install htmlfilter


## Development

HTMLFilter is hosted on GitHub[http://github.com/rubyworks/htmlfilter].

HTMLFilter is a Rubyworks[http://rubyworks.github.com] project.


## Acknowledgements

Thanks to Jang Kim for adding support for single quoted attributes.

HtmlFilter is a port of lib_filter.php, v1.15 by Cal Henderson <cal@iamcal.com>.
This code is licensed under a Creative Commons Attribution-ShareAlike 2.5 License.
See http://creativecommons.org/licenses/by-sa/2.5/.


## Copyrights

* Copyright (c) 2009 Rubyworks (BSD-2-Clause)
* Copyright (c) 2007 Cal Henderson (CC-BY-SA)

See LICENSE.txt and NOTICE.md for details.

