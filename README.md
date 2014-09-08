# Line Learn

A tool written as a ruby gem to gameify the process of learning lines.

## Installation

Add this line to your application's Gemfile:

    gem 'line_learn'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install line_learn

## Usage

First create a script file to learn.  This is the tricky part as it may involve a scanner and OCR software.
It may also involve doing some massaging of the script to the format required by line_learn.

The format of the script file should match the example.txt file:

    FRED: I like to go west.
    MARTHA:  Yes.
    FRED:  It's clever.
    BILL:  What do you guys want to do for dinner?
    MARTHA: Not sure.
    FRED:  How about we dine out?
    BILL:  Can we afford it?
    FRED: I think so.
    MARTHA:  There's a new place on Smith St.
    MARTHA:  But that's Italian, and I know you don't like Italian.
    FRED:  It depends.
    BILL:  What does that mean?
    FRED:  I've had it before where I liked it -- well, maybe that was Greek.  I'm not sure.
    FRED:  Let's just eat BBQ, okay?
    BILL:  Okay.

Execute:

    $ line_learn <SCRIPT_FILE> <CHARACTER>

The results of each run can be found in the reports folder.

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
