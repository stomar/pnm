PNM - A Ruby library for PNM image files (PBM, PGM, PPM)
========================================================

PNM is a pure [Ruby][Ruby] library for creating, reading,
and writing of `PNM` image files (Portable AnyMap):

- `PBM` (Portable Bitmap),
- `PGM` (Portable Graymap), and
- `PPM` (Portable Pixmap).

Examples
--------

Create an image from an array of gray values:

    require 'pnm'

    pixels = [[0, 1, 2], [1, 2, 3]]
    image = PNM::Image.new(:pgm, pixels, {:maxgray => 3})

Write an image to a file:

    image.write('test.pgm')

Read an image from a file:

    image = PNM.read('test.pgm')
    image.info     # => "PGM 3x2 Grayscale"
    image.maxgray  # => 3
    image.pixels   # => [[0, 1, 2], [1, 2, 3]]

Installation
------------

Clone or download the repository and use `rake build`
and `[sudo] gem install pnm` to install PNM.

Requirements
------------

- No additional Ruby gems or native libraries are needed.

- PNM has been tested with Ruby 1.9.3 and Ruby 2.0.0
  on a Linux machine and on Windows.

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
