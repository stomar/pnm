PNM - A Ruby library for PNM image files (PBM, PGM, PPM)
========================================================

PNM is a pure [Ruby][Ruby] library for creating, reading,
and writing of `PNM` image files (Portable AnyMap):

- `PBM` (Portable Bitmap),
- `PGM` (Portable Graymap), and
- `PPM` (Portable Pixmap).

Examples
--------

Create a PGM grayscale image from a two-dimensional array of gray values:

    require 'pnm'

    # pixel data
    pixels = [[ 0, 10, 20],
              [10, 20, 30]]

    # optional settings
    options = {:maxgray => 30, :comment => 'Test Image'}

    # create the image object
    image = PNM::Image.new(:pgm, pixels, options)

    # retrieve some image properties
    image.info    # => "PGM 3x2 Grayscale"
    image.width   # => 3
    image.height  # => 2

See PNM::Image.new for a more detailed description of pixel data formats
and available options.

Write an image to a file:

    image.write('test.pgm')

    # use ASCII or "plain" format (default is binary)
    image.write('test.pgm', :ascii)

    # write to an I/O stream
    File.open('test.pgm', 'w') {|f| image.write(f) }

Read an image from a file (returns a PNM::Image object):

    image = PNM.read('test.pgm')
    image.comment  # => "Test Image"
    image.maxgray  # => 30
    image.pixels   # => [[0, 10, 20], [10, 20, 30]]


Installation
------------

Clone or download the repository and use `rake build`
and `[sudo] gem install pnm` to install PNM.

Requirements
------------

- No additional Ruby gems or native libraries are needed.

- PNM has been tested with Ruby 1.9.3 and Ruby 2.0.0
  on Linux and on Windows.

Documentation
-------------

Documentation should be available via `ri PNM`.

Reporting bugs
--------------

Report bugs on the PNM home page: <https://github.com/stomar/pnm/>

License
-------

Copyright &copy; 2013 Marcus Stollsteimer

`PNM` is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License version 3 or later (GPLv3+),
see [www.gnu.org/licenses/gpl.html](http://www.gnu.org/licenses/gpl.html).
There is NO WARRANTY, to the extent permitted by law.


[Ruby]: http://www.ruby-lang.org/
