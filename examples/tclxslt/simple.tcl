#!/bin/sh
# -*- tcl -*- \
exec tclsh "$0" "$@"

# simple.tcl --
#
#	Simple transformation of a XML document,
#	from README.
#
# Copyright (c) 2008 Explain
# http://www.explain.com.au/
#
# $Id$

package require xml 3.2

set chan [open "count.xsl"]
set styleDoc [dom::parse [read $chan]]
close $chan
set sourceDoc [dom::parse [read stdin]]

set style [xslt::compile $styleDoc]
set resultDoc [$style transform $sourceDoc]

puts [dom::serialize $resultDoc]
exit 0

