#!/bin/sh
# -*- tcl -*- \
exec tclsh "$0" "$@"

# simple.tcl --
#
#	Simple character count of a DOM document,
#	from README.
#
# Copyright (c) 2008 Explain
# http://www.explain.com.au/
#
# $Id$

package require xml 3.2

set doc [dom::parse [read stdin]]
set count 0
foreach textNode [dom::selectNode $doc //text()] {
    incr count [string length [$textNode cget -nodeValue]]
}

puts "The document contains $count characters"
exit 0

