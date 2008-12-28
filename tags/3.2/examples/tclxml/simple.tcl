#!/bin/sh
# -*- tcl -*- \
exec tclsh "$0" "$@"

# simple.tcl --
#
#	Count the characters in a XML document,
#	from README.
#
# Copyright (c) 2008 Explain
# http://www.explain.com.au/
#
# $Id$

package require xml 3.2


set parser [xml::parser]
$parser configure -elementstartcommand EStart \
    -characterdatacommand PCData

proc EStart {tag attlist args} {
    array set attr $attlist
    puts "Element \"$tag\" started with [array size attr] attributes"
}

proc PCData text {
    incr ::count [string length $text]
}

set count 0
$parser parse [read stdin]

puts "The document contains $count characters"
exit 0

