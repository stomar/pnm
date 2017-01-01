PNM - A Ruby library for PNM image files (PBM, PGM, PPM)
========================================================

PNM is a pure [Ruby][Ruby] library for creating, reading,
and writing of `PNM` image files (Portable Anymap):

- `PBM` (Portable Bitmap),
- `PGM` (Portable Graymap), and
- `PPM` (Portable Pixmap).

It is a portable and lightweight utility for exporting or importing
of raw pixel data to or from an image file format that can be processed
by most image manipulation programs.

PNM comes without any dependencies on other gems or native libraries.

Examples
--------

Create a PGM grayscale image from a two-dimensional array of gray values:

``` ruby
require "pnm"

# pixel data
pixels = [[ 0, 10, 20],
          [10, 20, 30]]

# optional settings
options = {:maxgray => 30, :comment => "Test Image"}

# create the image object
image = PNM.create(pixels, options)

# retrieve some image properties
image.info    # => "PGM 3x2 Grayscale"
image.type    # => :pgm
image.width   # => 3
image.height  # => 2
```

Note that for PBM bilevel images a pixel value of 0 signifies white
(and 1 signifies black), whereas for PGM and PPM images a value of 0
signifies black.

See PNM.create for a more detailed description of pixel data formats
and available options.

Write an image to a file:

``` ruby
image.write("test.pgm")
image.write_with_extension("test")  # adds the correct file extension

# use ASCII or "plain" format (default is binary)
image.write("test.pgm", :ascii)

# write to an I/O stream
File.open("test.pgm", "w") {|f| image.write(f) }
```

Read an image from a file (returns a PNM::Image object):

``` ruby
image = PNM.read("test.pgm")
image.comment  # => "Test Image"
image.maxgray  # => 30
image.pixels   # => [[0, 10, 20], [10, 20, 30]]
```

Force an image type:

``` ruby
color_image = PNM.create([[0, 1],[1, 0]], :type => :ppm)
color_image.info  # => "PPM 2x2 Color"
```

Check equality of two images:

``` ruby
color_image == image  # => false
```

Installation
------------

To install PNM, you can either

- use `gem install pnm` to install from RubyGems.org,

- clone or download the repository and use
  `rake build` and `[sudo] gem install pnm`.

Requirements
------------

- No additional Ruby gems or native libraries are needed.

- PNM has been tested with

  - Ruby 2.4,
  - Ruby 2.3,
  - Ruby 2.2,
  - Ruby 2.1,
  - Ruby 2.0.0,
  - Ruby 1.9.3,
  - JRuby 1.7.19,
  - Rubinius 2.5.2.

Documentation
-------------

Documentation should be available via `ri PNM` or can be found at
[www.rubydoc.info/gems/pnm/](http://www.rubydoc.info/gems/pnm/).

Reporting bugs
--------------

Report bugs on the PNM home page: <https://github.com/stomar/pnm/>

License
-------

Copyright &copy; 2013-2017 Marcus Stollsteimer

`PNM` is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License version 3 or later (GPLv3+),
see [www.gnu.org/licenses/gpl.html](http://www.gnu.org/licenses/gpl.html).
There is NO WARRANTY, to the extent permitted by law.


[Ruby]: http://www.ruby-lang.org/
