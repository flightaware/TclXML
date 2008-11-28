#!/bin/sh
# \
exec wish "$0" "$@"

# tkxsltproc --
#
#	Simple GUI for xsltproc-style transformations
#
# Copyright (c) 2005-2007 Explain
# http://www.explain.com.au
# Copyright (c) 2003-2004 Zveno
# http://www.zveno.com/
#
# See the file "LICENSE" in this distribution for information on usage and
# redistribution of this file, and for a DISCLAIMER OF ALL WARRANTIES.
#
# $Id: tkxsltproc.tcl,v 1.11 2005/05/20 14:08:10 balls Exp $

# Global initialisation

set VERSION 1.9

# Temporary hack for TclApp-wrapped executables
lappend auto_path [file dirname [info nameofexecutable]]

# v3.1+ gives us the "-indent", "-resulturi" and "-profilefilename" options
package require xslt 3.2

package require msgcat
catch {namespace import ::msgcat::mc}

package require uri 1.2

# We need common routines from tkxmllint
source [file join [file dirname [info script]] common.tcl]

# Pre-load "standard" XSLT extension packages

catch {
    package require xslt::resources
    ::xslt::extension add http://www.zveno.com/resources ::xslt::resources
}
catch {
    package require xslt::process
    ::xslt::extension add http://www.zveno.com/process ::xslt::process
}
catch {
    package require xslt::utilities
    ::xslt::extension add http://www.zveno.com/utilities ::xslt::utilities
}

tk appname tkxsltproc

# Init --
#
#	Create the GUI
#
# Arguments:
#	win	toplevel window
#
# Results:
#	Tk widgets created

proc Init win {
    upvar \#0 State$win state

    if {[info exists state(initialised)]} {
	return
    }

    set w [expr {$win == "." ? {} : $win}]

    array set state {
	src {}
	ssheet {}
	result {}
	cwd {}
	profile 0
	profilefilename {}
	nonet 0
	nowrite 0
	nomkdir 0
	writesubtree None
    }

    wm title $win "Tk XSLTPROC"

    switch [tk windowingsystem] {
	aqua -
	classic {
	    set metakey Command
	    set metakeylabel Command-
	}
	default {
	    set metakey Control
	    set metakeylabel Ctrl+
	}
    }

    menu $w.menu -tearoff 0
    $win configure -menu $w.menu
    $w.menu add cascade -label [mc File] -menu $w.menu.file
    menu $w.menu.file -tearoff 0
    $w.menu.file add command -label [mc {New Window}] -command NewWindow -accel ${metakeylabel}N
    bind $win <${metakey}-n> NewWindow
    $w.menu.file add separator
    $w.menu.file add command -label [mc {Reload Stylesheet}] -command [list Compile $win] -accel ${metakeylabel}R
    bind $win <${metakey}-r> [list Compile $win]
    if {[tk windowingsystem] != "aqua"} {
	$w.menu.file add separator
	$w.menu.file add command -label [mc Preferences...] -command Preferences
	$w.menu.file add separator
	$w.menu.file add command -label [mc Quit] -command {destroy .} -accel ${metakeylabel}Q
    }
    bind $win <${metakey}-q> {destroy .}

    $w.menu add cascade -label [mc Help] -menu $w.menu.help
    menu $w.menu.help -tearoff 0
    $w.menu.help add command -label [mc {About tkxsltproc}] -command tkAboutDialog -accel ${metakeylabel}?
    # This fails on Linux
    catch {bind $win <${metakey}-?> tkAboutDialog}

    if {[tk windowingsystem] == "aqua"} {
	$w.menu add cascade -label tkxsltproc -menu $w.menu.apple
	menu $w.menu.apple -tearoff 0
	$w.menu.apple add command -label [mc {About tkxsltproc}] -command tkAboutDialog
	$w.menu.apple add command -label [mc Preferences...] -command Preferences
    }

    frame $w.controls
    grid $w.controls -row 0 -column 0 -sticky ew
    button $w.controls.xform -text [mc Transform] -command [list Transform $win]
    button $w.controls.reload -text [mc {Reload Stylesheet}] -command [list Compile $win]
    # TODO: add nice icons
    grid $w.controls.xform -row 0 -column 0 -sticky w
    grid $w.controls.reload -row 0 -column 1 -sticky w
    grid columnconfigure $w.controls 1 -weight 1

    Doc $win src -title [mc {Source Document}] -row 1
    Doc $win ssheet -title [mc {Stylesheet Document}] -row 2 -command [list Compile $win]
    Doc $win result -title [mc {Result Document}] -row 3 -type save

    labelframe $w.options -text [mc Options]
    grid $w.options -row 4 -column 0 -sticky ew
    checkbutton $w.options.validate -text [mc {Skip validation}] -variable State${win}(novalidate)
    checkbutton $w.options.timing -text [mc {Display timing}] -variable State${win}(timing)
    checkbutton $w.options.xinclude -text [mc XInclude] -variable State${win}(xinclude)
    checkbutton $w.options.nonet -text [mc {No network}] -variable State${win}(nonet)
    checkbutton $w.options.nowrite -text [mc {No write}] -variable State${win}(nowrite)
    checkbutton $w.options.nomkdir -text [mc {No mkdir}] -variable State${win}(nomkdir)
    label $w.options.writesubtreelabel -text [mc {Write subtree}]
    button $w.options.writesubtree -text [file tail $state(writesubtree)] -command [list WriteSubtree $win]
    button $w.options.profile -text [mc Profile...] -command [list Profile $win]
    if {$::tcl_platform(platform) == "windows"} {
	$w.options.profile configure -state disabled
    }
    button $w.options.security -text [mc Security...] \
	-command [list SecuritySettings $win]

    ### xsltproc options not yet provided
    # novalid
    # nodtdattr
    # maxdepth
    # maxparserdepth
    # catalogs
    # load-trace

    grid $w.options.validate -row 0 -column 0 -sticky w
    grid $w.options.timing -row 0 -column 1 -sticky w
    grid $w.options.xinclude -row 1 -column 0 -sticky w
    grid $w.options.profile -row 1 -column 1 -sticky w
    grid $w.options.nonet -row 0 -column 2 -sticky w
    grid $w.options.nowrite -row 1 -column 2 -sticky w
    grid $w.options.nomkdir -row 0 -column 3 -sticky w
    grid $w.options.writesubtreelabel -row 1 -column 3 -sticky e
    grid $w.options.writesubtree -row 1 -column 4 -sticky w
    grid columnconfigure $w.options 5 -weight 1

    labelframe $w.parameters -text [mc Parameters]
    ShowParameters $win
    text $w.parameters.t -wrap none -height 8 \
	-xscrollcommand [list $w.parameters.xs set] \
	-yscrollcommand [list $w.parameters.ys set]
    scrollbar $w.parameters.xs -orient horizontal \
	-command [list $w.parameters.t xview]
    scrollbar $w.parameters.ys -orient vertical \
	-command [list $w.parameters.t yview]
    $w.parameters.t insert end [mc {No parameters defined}]
    $w.parameters.t configure -tabs {4c right 5c left} -state disabled
    grid $w.parameters.t -row 0 -column 0 -sticky news
    grid $w.parameters.xs -row 1 -column 0 -sticky ew
    grid $w.parameters.ys -row 0 -column 1 -sticky ns
    grid columnconfigure $w.parameters 0 -weight 1

    set state(messages) [labelframe $w.messages -text [mc Messages]]
    grid $w.messages -row 7 -column 0 -sticky news
    text $w.messages.log -wrap none \
	-state disabled \
	-xscrollcommand [list $w.messages.xscroll set] \
	-yscrollcommand [list $w.messages.yscroll set]
    scrollbar $w.messages.xscroll -orient horizontal \
	-command [list $w.messages.log xview]
    scrollbar $w.messages.yscroll -orient vertical \
	-command [list $w.messages.log yview]
    grid $w.messages.log -row 0 -column 0 -sticky news
    grid $w.messages.yscroll -row 0 -column 1 -sticky ns
    grid $w.messages.xscroll -row 1 -column 0 -sticky ew
    grid rowconfigure $w.messages 0 -weight 1
    grid columnconfigure $w.messages 0 -weight 1

    SetProperties $win $w.messages.log

    frame $w.feedback
    grid $w.feedback -row 8 -column 0 -sticky ew
    label $w.feedback.msg -textvariable State${win}(feedback)
    set state(progress) [canvas $w.feedback.progress \
			     -width 100 -height 25]
    set state(progressbar) [$w.feedback.progress create rectangle 0 0 1 25 \
				-fill blue -disabledfill white -state disabled]
    grid $w.feedback.progress -row 0 -column 0
    grid $w.feedback.msg -row 0 -column 1 -sticky ew
    grid columnconfigure $w.feedback 1 -weight 1

    grid rowconfigure $win 7 -weight 1
    grid columnconfigure $win 0 -weight 1

    set state(initialised) 1

    return {}
}

# tkAboutDialog --
#
#	Information about this application
#
# Arguments:
#	None
#
# Results:
#	Displays window

proc tkAboutDialog {} {
    catch {destroy .about}
    toplevel .about
    catch {::tk::unsupported::MacWindowStyle style .about floatProc}
    wm title .about [mc {About tkxsltproc}]
    label .about.libxsltlogo -image libxsltLogo
    label .about.tcllogo -image tclLogo
    label .about.tkxsltproclogo -image tkxsltprocLogo
    text .about.msg -width 40 -height 10 -font Arial
    .about.msg insert end [mc [format "tkxsltproc - A GUI for xsltproc

Version %s

Powered by:
\tlibxml2\tv%s
\tlibxslt\tv%s
\tlibexslt\tv%s
\tTclXSLT\tv%s
\tTcl/Tk\tv%s

http://tclxml.sourceforge.net/tkxsltproc.html
" $::VERSION $::xml::libxml2::libxml2version \
	$::xslt::libxsltversion $::xslt::libexsltversion \
	[package require xslt] [info patchlevel]]]

    .about.msg configure -state disabled

    grid .about.tkxsltproclogo -row 0 -column 0 -rowspan 2 -sticky news
    grid .about.msg -row 0 -column 1 -rowspan 2 -sticky news -padx 20 -pady 20
    grid .about.libxsltlogo -row 0 -column 2 -sticky news
    grid .about.tcllogo -row 1 -column 2 -sticky news
    grid rowconfigure .about 0 -weight 1
    grid rowconfigure .about 1 -weight 1
    grid columnconfigure .about 1 -weight 1

    return {}
}

# Preferences --
#
#	Manage application preferences
#
# Arguments:
#	None
#
# Results:
#	Preferences dialog displayed

proc Preferences {} {
    catch {destroy .prefs}
    toplevel .prefs
    wm title .prefs [mc {tkxsltproc Preferences}]

    labelframe .prefs.extensions -text [mc Extensions]

    grid .prefs.extensions -row 0 -column 0 -sticky news
    grid columnconfigure .prefs 0 -weight 1

    button .prefs.extensions.load -text [mc Load] -command [list Preferences:LoadExtension]
    entry .prefs.extensions.script -textvariable ::preferences(extensionScript)
    button .prefs.extensions.browse -text [mc Browse] -command [list Preferences:Browse]

    grid .prefs.extensions.load - -row 0 -column 0 -sticky w
    grid .prefs.extensions.script -row 1 -column 0 -sticky ew
    grid .prefs.extensions.browse -row 1 -column 1 -sticky e
    grid columnconfigure .prefs.extensions 0 -weight 1

    return {}
}

proc Preferences:LoadExtension {} {
    set fname [.prefs.extensions.script get]

    if {![string length $fname]} {
	tk_messageBox -icon warning -message [mc {No extension script has been given}]
	return {}
    }
    if {![file readable $fname]} {
	tk_messageBox -icon error -message [mc {Unable to open extension script}]
	return {}
    }
    if {[catch {uplevel \#0 source $fname} err]} {
	tk_messageBox -icon error -message "An error occurred while loading the extension\n$err"
	return {}
    }

    return {}
}

proc Preferences:Browse {} {
    set fname [tk_getOpenFile -title [mc {Load Extension Script}]]
    if {![string length $fname]} {
	return {}
    }
    .prefs.extensions.script delete 0 end
    .prefs.extensions.script insert 0 $fname

    return {}
}

proc WriteSubtree {win} {
    upvar \#0 State$win state

    set w [expr {$win == "." ? {} : $win}]

    set dir [tk_chooseDirectory -parent $win -title [mc {Choose Write Subtree}] \
		   -mustexist 1 -initialdir [expr {$state(writesubtree) == "None" ? [pwd] : $state(writesubtree)}]]
    if {$dir != ""} {
	set state(writesubtree) $dir
	$w.options.writesubtree configure -text [file tail $dir]
    }
}

proc Profile win {
    upvar \#0 State$win state

    set w [expr {$win == "." ? {} : $win}]

    catch {destroy .profile}
    toplevel .profile
    wm title .profile [mc {tkxsltproc Profile}]

    set f [labelframe .profile.f -text [mc Profile]]
    grid $f -row 0 -column 0 -sticky news
    grid columnconfigure .profile 0 -weight 1

    checkbutton $f.state -text [mc Enabled] -variable State${win}(profile)
    entry $f.fname -textvariable State${win}(profilefilename) -width 30
    button $f.browse -text [mc Browse] -command [list Profile:Browse $win]
    grid $f.state - -row 0 -column 0 -sticky ew
    grid $f.fname -row 1 -column 0 -sticky ew
    grid $f.browse -row 1 -column 1 -sticky w
    grid columnconfigure $f 0 -weight 1

    return {}
}

proc Profile:Browse win {
    upvar \#0 State$win state

    set fname [tk_getSaveFile -title [mc {Save Profiling Data}]]
    if {![string length $fname]} {
	return {}
    }

    set state(profilefilename) $fname

    return {}
}

# Doc --
#
#	Setup a document pane
#
# Arguments:
#	win	toplevel window
#	p	pane
#	args	configuration options
#
# Results:
#	Widgets created and positioned

proc Doc {win p args} {
    upvar \#0 State$win state

    set w [expr {$win == "." ? {} : $win}]

    array set options {
	-type open
	-title {}
	-command {}
    }
    array set options $args

    labelframe $w.$p -text $options(-title)
    grid $w.$p -row $options(-row) -column 0 -sticky ew
    label $w.$p.url -text [mc URL:]
    entry $w.$p.urlentry -width 60 -textvariable State${win}(${p})
    button $w.$p.browse -text [mc Browse] -command [list Browse $win $p -title $options(-title) -type $options(-type) -command $options(-command)]
    grid $w.$p.url -row 0 -column 0 -sticky w
    grid $w.$p.urlentry -row 0 -column 1 -sticky ew
    grid $w.$p.browse -row 0 -column 2 -sticky e
    grid columnconfigure $w.$p 1 -weight 1

    return {}
}

# NewWindow --
#
#	Create another toplevel window
#
# Arguments:
#	None
#
# Results:
#	Tk toplevel created and initialised

proc NewWindow {} {
    global counter

    Init [toplevel .top[Incr counter]]

    return {}
}

# Compile --
#
#	Manage loading the stylesheet
#
# Arguments:
#	win	toplevel window
#
# Results:
#	Compiles stylesheet, adds widgets for parameters

proc Compile {win} {
    global stylesheets
    upvar \#0 State$win state

    set w [expr {$win == "." ? {} : $win}]

    Log clear $win
    catch {unset state(stylesheetLoaded)}

    Feedback $win [mc {Loading stylesheet document}]
    if {[catch {LoadDoc $win ssheet [mc stylesheet]} ssheetdoc]} {
	puts stderr "Compile: unable to load stylesheet due to \"$ssheetdoc\""
	return {}
    }

    Feedback $win [mc {Compiling stylesheet}]
    set time(precompile) [clock clicks -milliseconds]
    if {[catch {XSLTCompile $win $ssheetdoc} ssheet]} {
	Log add $win $ssheet
	Feedback $win [mc {Compiling stylesheet failed}]
	after 2000 [list Feedback $win {}]
	return {}
    }
    set time(compile) [clock clicks -milliseconds]
    Log timing $win "Compiling stylesheet took [expr $time(compile) - $time(precompile)]ms\n"

    set state(ssheet_cmd) $ssheet
    set stylesheets($ssheet) $win

    $ssheet configure -messagecommand [list messages $win]

    PopulateParams $win

    set state(stylesheetLoaded) $state(ssheet:mtime)

    Feedback $win [mc {Loading stylesheet completed}]
    after 2000 [list Feedback $win {}]

    return {}
}

# XSLTCompile --
#
#	Stub for compilation of the stylesheet
#
# Arguments:
#	win	toplevel window
#	doc	DOM document token of stylesheet to compile
#
# Results:
#	Returns stylesheet command or error message

proc XSLTCompile {win doc} {
    return [::xslt::compile $doc]
}

# PopulateParams --
#
#	Add widgets for stylesheet parameters
#
# Arguments:
#	win	toplevel window
#
# Results:
#	Widgets added for each stylesheet parameter

proc PopulateParams win {
    upvar \#0 State$win state
    upvar \#0 Parameters$win params

    set w [expr {$win == "." ? {} : $win}]
    set t $w.parameters.t

    ShowParameters $win

    $t configure -state normal

    foreach child [winfo children $w.parameters.t] {
	destroy $child
    }
    $t delete 1.0 end

    set state(parameters) {}

    set parameters [$state(ssheet_cmd) get parameters]
    if {[llength $parameters] == 0} {
	HideParameters $win
    }

    foreach parameter [lsort $parameters] {
	foreach {name ns select} $parameter break

	# Bug workaround: Variables cannot be resolved when passed
	# in as parameters, so do not attempt to set a default
	# value that computes using a variable reference.
	if {[string first \$ $select] >= 0} {
	    set select {}
	}

	# Workaround #2: XPath select expressions may need to be
	# resolved against the base URI of the stylesheet that
	# defines the parameter.
	if {![regexp {^("|').*("|')$} $select]} {
	    set select {}
	}

	if {[string first . $name] >= 0} {
	    set splitname [split $name .]
	    set head [lindex $splitname 0]
	    if {[winfo exists $t.menu$head]} {
		if {[winfo class $t.menu$head] != "Menubutton"} {
		    Log add $win "Unable to add parameter entry for \"$name\""
		    continue
		}
	    } else {
		menubutton $t.menu$head -text $head -menu $t.menu$head.menu
		menu $t.menu$head.menu -tearoff 0
		$t window create end -window $t.menu$head
		$t insert end \n
		$t insert end \t\t
		entry $t.menu${head}_value -width 50
		bindtags $t.menu${head}_value "[bindtags $t.menu${head}_value] parameter"
		$t window create end -window $t.menu${head}_value
		$t insert end \n
	    }
	    set root .menu
	    foreach step [lrange $splitname 1 [expr [llength $splitname] - 2]] {
		if {![winfo exists $t.menu$head${root}_$step]} {
		    $t.menu$head$root insert 0 cascade -label $step \
			-menu $t.menu$head${root}_$step
		    menu $t.menu$head${root}_$step -tearoff 0
		}
		append root _$step
	    }
	    set tail [lindex $splitname end]
	    set m $t.menu$head$root
	    $m insert 0 command -label $tail -command [list NestedParameter $win $name $ns $t.menu$head $t.menu$head$root $t.menu${head}_value]
	    set params($name) $select
	    lappend state(parameters) [list $name $ns [list set ::Parameters${win}($name)]]
	} else {
	    entry $t.value$name -width 50
	    if {[string length $name] > 15} {
		$t insert end $name\n\t\t
	    } else {
		$t insert end \t$name\t
	    }
	    $t.value$name insert 0 $select
	    $t window create end -window $t.value$name -stretch yes -align center
	    $t insert end \n

	    lappend state(parameters) [list $name $ns [list $t.value$name get]]
	}
    }

    $t configure -state disabled

    return {}
}

proc ShowParameters {win} {
    upvar \#0 State$win state

    set w [expr {$win == "." ? {} : $win}]

    grid $w.parameters -row 6 -column 0 -sticky news

    return {}
}

proc HideParameters {win} {
    upvar \#0 State$win state

    set w [expr {$win == "." ? {} : $win}]

    grid forget $w.parameters

    return {}
}

# NestedParameter --
#
#	Displays parameter value for a "nested" parameter.
#
# Arguments:
#	win	toplevel window
#	name	parameter name
#	ns	parameter's XML Namespace
#	mb	menu button for this parameter group
#	menu	menu widget for this parameter
#	entry	entry widget to display parameter select value
#
# Results:
#	Widget display changed

proc NestedParameter {win name ns mb menu entry} {
    upvar \#0 State$win state
    upvar \#0 Parameters$win select

    set w [expr {$win == "." ? {} : $win}]

    set t $w.parameters.t
    $t configure -state normal

    set tags [$t tag ranges $mb]
    foreach {start end} $tags {
	$t delete $start $end
    }

    $t insert [list $mb + 1 chars] \t$name $mb

    $entry delete 0 end
    $entry insert 0 $select($name)

    bind parameter <Key> [list ChangeParameter $win $name $entry]

    $t configure -state disabled
    return {}
}

# ChangeParameter --
#
#	Keep track of parameter values
#
# Arguments:
#	win	toplevel window
#	name	parameter name
#	entry	entry widget containing value
#
# Results:
#	State variable updated

proc ChangeParameter {win name entry} {
    upvar \#0 State$win state
    upvar \#0 Parameters$win select

    set w [expr {$win == "." ? {} : $win}]

    set select($name) [$entry get]

    return {}
}

# Transform --
#
#	Perform XSL transformation and display report
#
# Arguments:
#	win	toplevel window
#
# Results:
#	Documents read into memory, parsed, transformed and report displayed

proc Transform win {
    upvar \#0 State$win state

    set w [expr {$win == "." ? {} : $win}]

    Log clear $win

    if {![info exists state(stylesheetLoaded)]} {
	tk_messageBox -parent $win -message [mc "Stylesheet has not been loaded"] -type ok
	return {}
    }

    set time(start) [clock clicks -milliseconds]

    Feedback $win [mc {Loading source document}]
    if {[catch {LoadDoc $win src [mc source]} srcdoc]} {
	return {}
    }
    if {![info exists state(ssheet_cmd)] || \
	[string equal $state(ssheet_cmd) {}] || \
	    $state(stylesheetLoaded) < [LastModTime $state(ssheet)]} {
	Compile $win
    }

    set parameters {}
    foreach parameter $state(parameters) {
	foreach {name ns entry} $parameter break
	set value [eval $entry]
	if {[string length $value]} {
	    lappend parameters $name $value
	}
    }

    $state(ssheet_cmd) configure -resulturi [$w.result.urlentry get]
    if {$state(profile)} {
	if {[catch {open $state(profilefilename) w} profilech]} {
	    tk_messageBox -icon error -type ok -parent $win -message "Unable to write profiling data to \"$state(profilefilename)\" due to \"$profilech\""
	    return {}
	}
	$state(ssheet_cmd) configure -profilechannel $profilech
    }

    Feedback $win [mc {Perform transformation}]
    if {[catch {eval $state(ssheet_cmd) transform [list $srcdoc] $parameters} resultdoc]} {
	catch {close $profilech}
	Log add $win $resultdoc
	Feedback $win [mc {Transformation failed}]
	after 2000 [list Feedback $win {}]
	return {}
    }
    catch {close $profilech}
    set time(xform) [clock clicks -milliseconds]
    Log timing $win "Transformation took [expr $time(xform) - $time(start)]ms\n"

    # When the stylesheet's method is NULL, the type of the result document
    # determines the default output method.
    set method [$state(ssheet_cmd) cget -method]
    switch -glob -- $method,[dom::node cget $resultdoc -nodeType] {
	,HTMLdocument {
	    set method html
	}
	,* {
	    set method xml
	}
    }

    if {[string length $state(result)]} {

	set fname {}
	set state(result) [$w.result.urlentry get]
	if {[catch {uri::split $state(result)} spliturl]} {
	    # Treat as a pathname
	    set fname $state(result)
	    set state(result) file:///$state(result)
	} else {
	    array set urlarray $spliturl
	    switch -- $urlarray(scheme) {
		http {
		    tk_messageBox -message "Saving to a http URL is not yet supported" -parent $win -type ok -icon warning
		    Log add $win [Serialize $win $resultdoc -method [$state(ssheet_cmd) cget -method]]
		}
		file {
		    set fname $urlarray(path)
		}
		default {
		    tk_messageBox -message "Saving to a \"$urlarray(scheme)\" type URL is not supported" -parent $win -type ok -icon warning
		    Log add $win [Serialize $win $resultdoc -method [$state(ssheet_cmd) cget -method]]
		}
	    }
	}

	if {[string length $fname] && [catch {open $fname w} ch]} {
	    Log add $win $ch
	    Feedback $win [mc {Unable to save result}]
	    after 2000 [list Feedback $win {}]
	    return {}
	}
	fconfigure $ch -encoding utf-8
	puts $ch [Serialize $win $resultdoc -method $method -indent [$state(ssheet_cmd) cget -indent]]
	close $ch
    } else {
	Log add $win [Serialize $win $resultdoc -method $method -indent [$state(ssheet_cmd) cget -indent]]
    }
    set time(finish) [clock clicks -milliseconds]
    Log timing $win "saving result took [expr $time(finish) - $time(xform)]ms\n"
    Log timing $win "total time for processing: [expr $time(finish) - $time(start)]ms\n"

    Feedback $win [mc {Processing completed}]
    after 2000 [list Feedback $win {}]

    return {}
}

# Serialize --
#
#	Stub for serializing DOM document
#
# Arguments:
#	win	toplevel window
#	doc	DOM document
#	args	additional arguments
#
# Results:
#	Document text

proc Serialize {win doc args} {
    return [eval dom::serialize [list $doc] $args]
}

# messages --
#
#	Display messages emitted by the stylesheet
#
# Arguments:
#	win	toplevel window
#	args	messages
#
# Results:
#	Updates message display

proc messages {win args} {
    upvar \#0 State$win state

    foreach msg $args {
	if {[catch {Log addMessage $win "$msg"} errmsg]} {
	    puts stderr "messages: $args"
	}
    }
    update

    return {}
}

# LoadDoc --
#
#	Load a document into an in-memory DOM tree
#
# Arguments:
#	win	toplevel window
#	type	type of document
#	label	display label
#
# Results:
#	Returns DOM tree token

proc LoadDoc {win type label} {
    upvar \#0 State$win state

    set w [expr {$win == "." ? {} : $win}]

    set state($type) [$w.$type.urlentry get]

    if {![string length $state($type)]} {
	tk_messageBox -parent $win -type ok -icon error -message [mc "You haven't specified a $label document"]
	return -code error "unable to load $label document"
    }

    if {[catch {uri::split $state($type)} spliturl]} {
	# Try the URL as a pathname
	set fname $state($type)
	set state($type) file:///$state($type)
	array set urlarray {scheme file}
    } else {
	array set urlarray $spliturl
	switch -- $urlarray(scheme) {
	    http {
		set fname $state($type)
	    }
	    file {
		set fname $urlarray(path)
	    }
	    default {
		tk_messageBox -message "\"$urlarray(scheme)\" type URLs are not supported" -parent $win -type ok -icon warning
		return -code error "unable to load $label document"
	    }
	}
    }

    set time(start) [clock clicks -milliseconds]

    if {[catch {ReadAndParseXML $win $type $fname $state($type) time \
		    -noent 1 -nonet $state(nonet)} doc]} {
	return
    }

    set state(${type}:mtime) 0
    # HTTP downloads will not have mtime set
    catch {set state(${type}:mtime) [file mtime $fname]}
    set state(${type}_doc) $doc

    # BUG WORKAROUND: store the source doc's directory
    set state(${type}_dir) {}
    catch {set state(${type}_dir) [file dirname $fname]}

    return $doc
}

# LastModTime --

proc LastModTime {uri} {
    if {[catch {uri::split $uri} spliturl]} {
	# Try the URL as a pathname
	set fname $uri
    } else {
	array set urlarray $spliturl
	switch -- $urlarray(scheme) {
	    http {
		# Not yet supported
		return 0
	    }
	    file {
		set fname $urlarray(path)
	    }
	    default {
		return 0
	    }
	}
    }

    return [file mtime $fname]
}

# ::xslt::security --
#
#	Implement restrictions on stylesheet operations
#
# Arguments:
#	name	name of requesting stylesheet
#	op	requested operation
#	value	additional info
#
# Results:
#	Returns boolean

proc ::xslt::security {name op value} {
    global stylesheets

    upvar #0 State$stylesheets($name) state

    switch -- $op {
	readfile {
	    return 1
	}
	writefile {
	    if {$value == {}} {
		# This is the console
		return 1
	    } elseif {!$state(nowrite)} {
		if {$state(writesubtree) != "None"} {
		    set towrite [file split [file normalize $value]]
		    set ok 1
		    set split [file split $state(writesubtree)]
		    for {set count 0} {$count < [llength $split]} {incr count} {
			if {[lindex $towrite $count] != [lindex $split $count]} {
			    set ok 0
			}
		    }
		    return $ok
		} else {
		    return 1
		}
	    } else {
		return 0
	    }
	}
	createdirectory {
	    return [expr !$state(nomkdir)]
	}
	readnetwork -
	writenetwork {
	    if {$state(nonet) && \
		    ([string match http://* $value] || \
		     [string match ftp://* $value])} {
		return 0
	    } else {
		return 1
	    }
	}
    }
    # shouldn't be here
    return 0
}

### Image data - end of script

image create photo libxsltLogo -data {
R0lGODlhtABEAPf/AP///wAAAP7+/vz8/AUKAjU1Mvv7+729vd7e3SwtKWJi
XPb29pKTjpSVkUtMSoODfIuMiXFyb/T09La2sYmKhpmaldnZ2BscGtHRzdXV
1fPz8yQmI9LS0c3NyeHh4ZydmWprZDs8OdnZ1UtSUubm5sXFweTk5P39/Q4O
DcnJxfj4+FlaVTEyLsHBvL6+ufDw8BMWEnR1ckNFQtXV0YGCgPLy8rm5sQAE
ACwwKu7u7qysqvL18SgqJnFycAACALm5rFFSTbKyprW1ruTl4q2tpTk5N0RL
TKGhnaSkoezs7DtFRm9wbcrKyMHBudzc2icpJPr6+s7OzElKRuDg3mxuah4i
HWVmZMnJwgIHAGpsaenp6FZYVn1+fOjo5rGxrhEWDmRlYrm6tcbGw8LCwMzM
xfb49cXFvXp8eYSFgl1dWO3u7KmpoXh5djI1L7Gxqebm5GFiYHx9el1eXKam
mu/x7qampcDAtOrq6hQYE3d4dWdoZYKDgaWlnXZ2dO7w7uzs6mlqaH+Afvv6
+L29tnl7eKCgmvP18qqqpTY4NX19cV9gXebp6mJjYVpaWXJ0cQ4SDPX29KCg
lVpcWr29sfPz8lpdXebo5oWHhOrs6UFDP5eYlFdXVSEjHqqqnff69ldaWcXF
uVVVUXt7cFFSUOnr6Pn8+EZIRK6uoo6QjBgYFlBUU4eIhQoKCU5QTK6vq1FX
Vezu6+js7dDQysjIvbq7uUFHSfHx8ba2qAsPCaeno/X19V1hYL6/vMfIxejq
5z4/PAQHAQMDA0lPUC02NgwMC6GioOTm5AYLBCYrKNrb2dbZ2s3S1OLl4dPT
zp2fnH19duzu7qKkoSAlIwYGBry8uS8wLICAdczMwvv8+fz7+G1ubAgMBuHm
6d/j5vH08NfX1re3taOjnVNXV8/PxwIFALOzq8/Qz9jc3fj799PT09PW1J6e
j+3w8fb6+szMyvP29v3+/MPEvmJlZdvf4MPEw6Sjm4iHgrO0ruDi36+vp29y
cPv7+gIGApCQjQIIAICAgCH5BAEAAP8ALAAAAAC0AEQAAAj/AP8JFBjIkYNq
wQIoXMiwocOHECNKnEixosWLGDM+DFbNgaNAA0MK5MJCo8mTKFOqXImSBReR
Aq2wChBsVJ0oJwDo3Mmzp8+fQIMKHUq0qNGjSJP2PBGlzqiErKyIbKTwCROl
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
CAA7
}
image create photo tclLogo -data {
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
5V+g+JBhTvOaGyEIADs=
}
image create photo tkxsltprocLogo -data {
R0lGODlh8AAPAfcAMf///84SB0kMDM6JGS4JCVZWVs3NzczMzNacJdOJitGR
HsrKytujpNOVIJKSkpCQkJSUlBAODpiYmIyMjJaWloCAgI6Ojvfr0JycnJ6e
noqKiqurq5qamqCgoMDAwIWFhaOjozMzM4iIiIKCgrCwsKWlpISEhKenp6mp
qa2trcdqa7a2tq6urrOysrS0tOSiI7m4uH5+frEwMbq6usPDw25ubry8vHx7
e76+vnp6esjIyNypLcXFxcTExHh4eHBwcOKYHHRzc8h8EiIiInV1deeqKnJy
ctCPHO3Trevr67hHR+G1Ne3NlfTh4UFBQd+xMpxiDtWYIuXBPevCO92tMGBg
YMqBFPHhVasSCerNRocRC/rx8dmjKffuXu/bUcuCFfbpq5URC3gRDLkSCNmt
atakUsd6EfDw8OG2d8yGIem5NO7S0ubEQOm1MtqlKvHUSrJxce3VTOS1WuK5
OE1NTbWKi5lpaqoYGeOdIGsQDPr04ezRSvTncsyGGO3TeOiyL/PlWFwODNWd
SujKRJowMdOWPtHMxWhoaMh8EdfFqfDeUsqCFvTpXJJPTe/YTuO8OoBQC/Xn
j9O5kMyFF/z48e3JQefGQeq+OOO9PMl+E+vQSM+MG9qmK9abI+jIQ+/NRMuD
FU8wBnIIBe3US+WmPfTnWsl9Er6mheG3NqOBgYsHCMh7EdGTNOanJ76goO7L
QnlmZtzT09igJzMgBeLXyJh2SObBYOO+PNGUKdCNHPPgwebBiKMNBMmAFKGR
kerOR8ewsc6LL9zAl+S9OtObMuGzQ6EZGmRAC+fHQvDSSMqAE+bm5s+OMOXl
5ePj4+Tk5OLi4uDg4OHh4d7e3t/f39vb293d3dzc3NefJ9ra2tnZ2djY2NfX
19XV1dbW1tTU1NPT09LS0tHR0dDQ0HYVFaASC8p/E+fn59igKOnCwr5XV+Kz
s+evLZkICezGPvDQRqQhIsqCILCgoMB+G3wlJciaXNXDwK19Iqh9QejIUJJ9
emcaGsuZJ8+OJqQJCgAAACH5BAEAAAAALAAAAADwAA8BAAj/AAEIHEiwoMGD
CBMqXMiwocOHECNKnEixosWLGDNq3Mixo8ePIEOKHEmypMmTKFOqXMmypcuX
MGPKnEmzps2bOHPq3Mmzp8+fQIMKHaqwCdGjSEGmu2M0qdOnFIFhkQG1qlWG
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
ECv1mgEBADs=
}

# Filter out the process serial number on Mac OS X
if {[set idx [lsearch -glob $argv "-psn*"]] >= 0} {
    set argv [lreplace $argv $idx $idx]
}
array set args {
    -inline 1
}
array set args $argv

if {$args(-inline)} {
    Init .
}
