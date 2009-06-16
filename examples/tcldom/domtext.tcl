# domtext.tcl --
#
#	Megawidget to display a DOM document in a Text widget.
#
#	This widget both generates and reacts to DOM Events.
#
# Copyright (c) 2008-2009 Explain
# http://www.explain.com.au/
# Copyright (c) 1999-2003 Zveno Pty Ltd
# http://www.zveno.com/
#
# See the file "LICENSE" in this distribution for information on usage and
# redistribution of this file, and for a DISCLAIMER OF ALL WARRANTIES.
#
# $Id: domtext.tcl,v 1.5 2003/12/09 04:56:40 balls Exp $

package provide domtext 3.3

# We need the DOM
# V2.0 gives us Level 2 Events

package require dom 3.3

# Configuration options:
#
#	-elementbgcolorlist {colour1 colour2 ...}
#		Specifies a list of colours to cycle through for
#		backgrounds of sucessive element content.
#
#	-showtag text|tab|<empty>
#		"text" denotes that start and end tags are shown
#		as their XML text.  "tab" denotes that start and
#		end tags are shown as an image.  Empty value
#		denotes that start and end tags are not shown.

namespace eval domtext {
#    Widget::tkinclude domtext text .text \
#	    remove {-command -state}

#    Widget::declare domtext {
#	{-highlightcolor	String	"#d9ffff"	0}
#	{-rootnode		String	""		0}
#	{-state			String	"normal"	0}
#	{-tagcolor		String	"#18605a"	0}
#	{-commentcolor		String	"#660f91"	0}
#	{-entityrefcolor	String	"#0080c0"	0}
#	{-elementbgcolorlist	String	""		0}
#	{-showtag		String	"text"		0}
#    }

    proc ::domtext { path args } { return [domtext::create $path {*}$args] }

    # Define bindings for domtext widget class

    # Certain mouse event bindings for the Text widget class must be overridden

    bind domtext <Button-1> [namespace code [list TkeventOverride %W %x %y]]
    bind domtext <Double-Button-1> [namespace code [list TkeventOverride %W %x %y]]

    # All of these bindings for the Text widget class cause characters
    # to be inserted or deleted.  These must be caught and prevented if the
    # characters are part of markup, otherwise the node value must be
    # updated
    # TODO: update with all bindings for Text widget

    foreach spec {
	<Meta-Key-d> <Meta-Key-Delete> <Meta-Key-BackSpace>
	<Control-Key-h> <Control-Key-t> <Control-Key-k> <Control-Key-d>
	<Control-Key-i> <Key>
	<<Cut>> <<Paste>> <<PasteSelection>> <<Clear>>
	<Key-BackSpace> <Key-Delete> <Key-Return>
    } {
	bind domtext $spec [list domtext::TkeventFilter_$spec %W %A]
    }
    foreach spec {
	<Key-Up> <Key-Down> <Key-Left> <Key-Right>
    } {
	bind domtext $spec [list domtext::KeySelect %W $spec]
    }
    foreach spec {
	<Meta-Key> <Control-Key>
    } {
	bind domtext $spec {# Do nothing - allow the normal Text class binding to take effect}
    }

    variable eventTypeMap
    array set eventTypeMap {
	ButtonPress	mousedown
	ButtonRelease	mouseup
	Enter		mouseover
	Leave		mouseout
	Motion		mousemove
	FocusIn		DOMFocusIn
	FocusOut	DOMFocusOut
    }
}

# domtext::create --
#
#	Widget class creation command
#
# Arguments:
#	path	widget path
#	args	configuration options
#
# Results:
#	Widget created, returns path

proc domtext::create {path args} {
    variable state

    array set maps [list Text {} :text {} .text {}]

    text $path -wrap none -takefocus 1
    set cmd [namespace current]::_cmd$path
    rename ::$path $cmd
    dict set state $path cmd $cmd
    proc ::$path {args} "[namespace current]::Cmd $path {*}\$args"

    $cmd tag configure starttab -elide 1
    $cmd tag configure endtab -elide 1
    $cmd tag configure sel -borderwidth 2
    $cmd tag configure sel -relief raised

    bindtags $path [list $path Domtext [winfo toplevel $path] all]

    dict set state $path rootnode {}
    dict set state $path nextColor 0
    dict set state $path tag_backgrounds {
	#fdd5bd #bdfdd5 #bdd5fd #999ab9
    }
    dict set state $path insert end
    dict set state $path showtag 0

    configure $path {*}$args

    return $path
}

# domtext::Cmd --
#
#	Implements widget command
#
# Arguments:
#	path	widget path
#	cmd	subcommand
#	args	options
#
# Results:
#	Depends on subcommand

proc domtext::Cmd {path cmd args} {
    [namespace current]::$cmd $path {*}$args
}

# domtext::cget --
#
#	Implements the cget method
#
# Arguments:
#	path	widget path
#	option	configuration option
#
# Results:
#	Returns value of option

proc domtext::cget {path option} {
    variable state

    regexp {^-(.*)} $option discard opt
    return [dict get $state $path $opt]
}

# domtext::configure --
#
#	Implements the configure method
#
# Arguments:
#	path	widget path
#	args	configuration options
#
# Results:
#	Sets values of options

proc domtext::configure {path args} {
    variable state

    switch [llength $args] {
	0 {
	    return {}
	}
	1 {
	    return [cget $path [lindex $args 0]]
	}
	default {
	    set cmd [dict get $state $path cmd]
	    foreach {option value} $args {
		regexp {^-(.*)} $option discard opt

		switch -- $opt {
		    rootnode {
			dict set state $path rootnode $value

			$cmd delete 1.0 end
			# Delete all marks and tags
			# This doesn't delete the standard marks and tags
			$cmd tag delete {*}[$cmd tag names]
			$cmd mark unset {*}[$cmd mark names]
			# Remove event listeners from previous DOM tree

			dict set state $path insert 1.0

			if {[string length $value]} {
			    set docel [$value cget -documentElement]

			    if {[string length $docel]} {
				# Listen for UI events
				dom::node addEventListener $value DOMActivate [namespace code [list NodeSelected $path]] -usecapture 1

				# Listen for mutation events
				#dom::node addEventListener $value DOMNodeInserted [namespace code [list NodeInserted $path]] -usecapture 1
				#dom::node addEventListener $value DOMNodeRemoved [namespace code [list NodeRemoved $path]] -usecapture 1
				#dom::node addEventListener $value DOMCharacterDataModified [namespace code [list NodePCDATAModified $path]] -usecapture 1
				#dom::node addEventListener $value DOMAttrModified [namespace code [list NodeAttrModified $path]] -usecapture 1
				#dom::node addEventListener $value DOMAttrRemoved [namespace code [list NodeAttrRemoved $path]] -usecapture 1

				Refresh $path
			    }
			}
		    }

		    tagcolor {
			$cmd tag configure tags -foreground $value
		    }
		    highlightcolor {
			$cmd tag configure highlight -background $value
		    }
		    commentcolor {
			$cmd tag configure comment -foreground $value
		    }
		    entityrefcolor {
			$cmd tag configure entityreference -foreground $value
		    }
		    elementbgcolorlist {
			dict set state $path nextColor 0
			dict set state $path tag_backgrounds $value
			ElementBackgroundSetAll $path [dict get $state $path rootnode]
		    }

		    showtag {
			switch -- $value {
			    text {
				$cmd tag configure starttab -elide 1
				$cmd tag configure endtab -elide 1
				$cmd tag configure tags -elide 0
			    }
			    tab {
				$cmd tag configure tags -elide 1
				$cmd tag configure starttab -elide 0
				$cmd tag configure endtab -elide 0
			    }
			    {} {
				$cmd tag configure tags -elide 1
				$cmd tag configure starttab -elide 1
				$cmd tag configure endtab -elide 1
			    }
			    default {
				return -code error "invalid mode \"$value\""
			    }
			}
		    }

		    xscrollcommand -
		    yscrollcommand {
			$cmd configure $option $value
		    }

		    default {
			return -code error "unknown option \"$option\""
		    }
		}
	    }
	}
    }

    return {}
}

# domtext::xview --
#
#	Implements xview method
#
# Arguments:
#	path	widget path
#	args	additional arguments
#
# Results:
#	Depends on Text's xview method

proc domtext::xview {path args} {
    variable state

    [dict get $state $path cmd] xview {*}$args
}

# domtext::yview --
#
#	Implements yview method
#
# Arguments:
#	path	widget path
#	args	additional arguments
#
# Results:
#	Depends on Text's yview method

proc domtext::yview {path args} {
    variable state

    [dict get $state $path cmd] yview {*}$args
}

# domtext::instate --
#
#	Implements instate method
#
# Arguments:
#	path	widget path
#	args	additional arguments
#
# Results:
#	Depends on Text's instate method

proc domtext::instate {path args} {
    variable state

    [dict get $state $path cmd] instate {*}$args
}

# domtext::Refresh --
#
#	Inserts serialized nodes into the Text widget,
#	while at the same time marking up the text to support
#	DOM-level editing functions.
#
#	This function is similar to the DOM package's
#	serialization feature.  The code started by being copied
#	from there.
#
#	Assumes that the widget is in normal state
#
# Arguments:
#	path	widget path
#
# Results:
#	Text widget populated with serialized text.

proc domtext::Refresh {path} {
    variable state

    set rootnode [dict get $state $path rootnode]
    if {$rootnode == {}} {
	return {}
    }

    RefreshNode $path [dict get $state $path cmd] [$rootnode cget -documentElement]

    return {}
}

proc domtext::RefreshNode {path cmd node} {
    variable state

    set id [$node cget -id]

    set insert [dict get $state $path insert]

    $cmd mark set $id $insert
    $cmd mark gravity $id left

    set end $insert

    # For all nodes we bind Tk events to be able to generate DOM events
    $cmd tag bind $id <1> [namespace code [list TkeventSelect $path $node %x %y]]
    $cmd tag bind $id <Double-1> [namespace code [list TkeventOpen $path $node]]

    $cmd tag configure $id -background [ElementBackgroundCycle $path]

    switch [$node cget -nodeType] {
	document -
	documentFragment {

	    foreach childToken [$node children] {
		set end [RefreshNode $path $cmd $childToken]
		dict set state $path insert $end
	    }

	    $cmd tag add $id $id $end
	}

	element {

	    # Serialize the start tag
	    $cmd insert $insert <[$node cget -prefix][expr {[$node cget -prefix] != "" ? ":" : ""}][$node cget -nodeName] [list tags tag:start:$id] [SerializeAttributeList [array get [$node cget -attributes]]] [list tags attrs:$id] > [list tags tag:start:$id]

	    set insert [lindex [$cmd tag ranges tag:start:$id] end]

	    # Add the start tab icon
	    $cmd image create $insert -image ::domtext::starttab -align center -name tab:start:$id
	    foreach t [list starttab tags tag:start:$id] {
		$cmd tag add $t tab:start:$id
	    }

	    set insert [lindex [$cmd tag ranges tag:start:$id] end]
	    dict set state $path insert $insert

	    # Serialize the content
	    $cmd mark set content:$id $insert
	    $cmd mark gravity content:$id left
	    foreach childToken [$node children] {
		set end [RefreshNode $path $cmd $childToken]
		dict set state $path insert $end
		set insert $end
	    }
	    $cmd tag add content:$id content:$id $end

	    # Serialize the end tag
	    $cmd insert $insert </[$node cget -prefix][expr {[$node cget -prefix] != "" ? ":" : ""}][$node cget -nodeName]> [list tags tag:end:$id]
	    set end [lindex [$cmd tag ranges tag:end:$id] end]
	    # Add the end tab icon
	    $cmd image create $end -image ::domtext::endtab -align center -name tab:end:$id
	    foreach t [list endtab tags tag:end:$id] {
		$cmd tag add $t tab:end:$id
	    }
	    set end [lindex [$cmd tag ranges tag:end:$id] end]

	    dict set state $path insert $end
	    $cmd tag add $id $id $end

	    $cmd tag raise starttab
	    $cmd tag raise endtab
	    $cmd tag configure starttab -elide [expr {[dict get $state $path showtag] != "tab"}]
	    $cmd tag configure endtab -elide [expr {[dict get $state $path showtag] != "tab"}]

	}

	textNode {
	    set text [Encode [$node cget -nodeValue]]
	    if {[string length $text]} {
		$cmd insert $insert $text $id
		set end [lindex [$cmd tag ranges $id] 1]
		dict set state $path insert $end
	    } else {
		dict set state $path end $insert
	    }
	}

	comment {
	    set text [$node cget -nodeValue]
	    $cmd insert $insert <!-- [list comment markup $id] $text [list comment $id] --> [list comment markup $id]
	    set end [lindex [$cmd tag ranges $id] 1]
	    dict set state $path insert $end
	}

	entityReference {
	    set text [$node cget -nodeName]
	    $cmd insert $insert & [list entityreference markup $id] $text [list entityreference $id] \; [list entityreference markup $id]
	    set end [lindex [$cmd tag ranges $id] 1]
	    dict set state $path insert $end
	}

	processingInstruction {
	    set text [$node cget -nodeValue]
	    if {[string length $text]} {
		set text " $text"
	    }
	    $cmd insert $insert "<?[$node cget -nodeName]$text?>" $id
	    set end [lindex [$cmd tag ranges $id] 1]
	    dict set state $path insert $end
	}

	default {
	    # Ignore it
	}

    }

    return $end
}

# domtext::SerializeAttributeList --
#
#	Produce textual representation of an attribute list.
#
#	NB. This is copied from TclDOM's domimpl.tcl,
#	but with the namespace handling removed.
#
# Arguments:
#	atlist	name/value list of attributes
#
# Results:
#	Returns string

proc domtext::SerializeAttributeList atlist {

    set result {}
    foreach {name value} $atlist {

	append result { } $name =

	# Handle special characters
	regsub -all & $value {\&amp;} value
	regsub -all < $value {\&lt;} value

	if {![string match *\"* $value]} {
	    append result \"$value\"
	} elseif {![string match *'* $value]} {
	    append result '$value'
	} else {
	    regsub -all \" $value {\&quot;} value
	    append result \"$value\"
	}

    }

    return $result
}

# domtext::Encode --
#
#	Protect XML special characters
#
#	NB. This is copied from TclDOM's domimpl.tcl.
#
# Arguments:
#	value	text
#
# Results:
#	Returns string

proc domtext::Encode value {
    array set Entity {
	$ $
	< &lt;
	> &gt;
	& &amp;
	\" &quot;
	' &apos;
    }

    regsub -all {([$<>&"'])} $value {$Entity(\1)} value ;# " for emacs

    return [subst -nocommand -nobackslash $value]
}

# domtext::ElementBackgroundSetAll --
#
#	Recurse node hierarchy setting element background color property
#
# Arguments:
#	path	widget path
#	node	DOM node
#
# Results:
#	Text widget tag configured

proc domtext::ElementBackgroundSetAll {path node} {
    variable state

    if {$node == {}} {
	return {}
    }

    set cmd [dict get $state $path cmd]
    if {[catch {set id [$node cget -id]}]} {
	# node is the document
	set node [$node cget -documentElement]
	set id [$node cget -id]
    }

    $cmd tag configure $id -background [ElementBackgroundCycle $path]

    switch [$node cget -nodeType] {
	document -
	documentFragment -
	element {
	    foreach child [$node children] {
		ElementBackgroundSetAll $path $child
	    }
	}
	default {
	    # No more to do here
	}
    }

    return {}
}
proc domtext::ElementBackgroundCycle path {
    variable state

    set list [dict get $state $path tag_backgrounds]
    set colour [lindex $list [dict get $state $path nextColor]]

    dict set state $path nextColor [expr ([dict get $state $path nextColor] + 1) % [llength $$list]]

    return $colour
}

# domtext::NodeInserted --
#
#	React to addition of a node
#
# Arguments:
#	path	widget path
#	evid	DOM event node
#
# Results:
#	Display updated to reflect change to DOM structure

proc domtext::NodeInserted {path evid} {
    variable state

    set node [dom::event cget $evid -target]
    set id [$node cget -id]

    set cmd [dict get $state $path cmd]

    # Remove parent's content and then render new content
    set parent [$node parent]
    set tags [$cmd tag ranges [$parent cget -id]]
    set start [lindex $tags 0]
    set end [lindex $tags end]
    if {[string length $start]} {
	$cmd delete $start $end
    } else {
	set start end
    }

    dict set state $path insert $start
    set end [Refresh $path $parent]

    # Restore grandparent element tags
    set parent [$parent parent]
    while {[string length $parent]} {
	set ranges [$cmd tag ranges [$parent cget -id]]
	catch {$cmd tag remove [$parent cget -id] {*}$ranges}
	catch {$cmd tag add [$parent cget -id] [lindex $ranges 0] [lindex $ranges end]}
	# Also do content tag for elements
	if {![string compare [$parent cget -nodeType] "element"]} {
	    set ranges [$cmd tag ranges content:[$parent cget -id]]
	    catch {$cmd tag remove [$parent cget -id] {*}$ranges}
	    catch {$cmd tag add content:[$parent cget -id] [lindex $ranges 0] [lindex $ranges end]}
	}

	set parent [$parent parent]
    }

    return {}
}

# domtext::NodeRemoved --
#
#	React to removal of a node.
#	This is almost identical to node insertion,
#	except that we must get the parent from the event.
#
# Arguments:
#	path	widget path
#	evid	DOM event node
#
# Results:
#	Display updated to reflect change to DOM structure

proc domtext::NodeRemoved {path evid} {
    variable state

    set node [dom::event cget $evid -target]

    set cmd [dict get $state $path cmd]

    if {[dict exists $state $path selected]} {
	dict unset $state $path selected
    }

    # Remove parent's content and then render new content
    set parent [dom::event cget $evid -relatedNode]
    set tags [$cmd tag ranges [$parent cget -id]]
    set start [lindex $tags 0]
    set end [lindex $tags end]
    if {[string length $start]} {
	$cmd delete $start $end
    } else {
	set start end
    }

    dict set state $path insert $start
    set end [Refresh $path $parent]

    # Restore grandparent element tags
    set parent [$parent parent]
    while {[string length $parent]} {
	set ranges [$cmd tag ranges [$parent cget -id]]
	catch {$cmd tag remove [$parent cget -id] {*}$ranges}
	catch {$cmd tag add [$parent cget -id] [lindex $ranges 0] [lindex $ranges end]}
	# Also do content tag for elements
	if {![string compare [::dom::node cget $parent -nodeType] "element"]} {
	    set ranges [$cmd tag ranges content:[$parent cget -id]]
	    catch {$cmd tag remove [$parent cget -id] {*}$ranges}
	    catch {$cmd tag add content:[$parent cget -id] [lindex $ranges 0] [lindex $ranges end]}
	}

	set parent [$parent parent]
    }

    return {}
}

# domtext::NodeAttrModified --
#
#	React to a change in the attribute list for a node
#
# Arguments:
#	path	widget path
#	evid	DOM event node
#
# Results:
#	Display updated to reflect change to DOM structure

proc domtext::NodeAttrModified {path evid} {
    variable state

    set node [dom::event cget $evid -target]
    set id [$node cget -id]

    set cmd [dict get $state $path cmd]

    set tags [$cmd tag ranges attrs:$id]
    if {[llength $tags]} {

	# Remove previously defined attributes

	foreach {start end} $tags break
	set existingTags [$cmd tag names $start]
	$cmd delete $start $end
	$cmd tag delete attrs:$id

    } else {
	set tagStartEnd [lindex [$cmd tag ranges tag:start:$id] end]
	set start [$cmd index "$tagStartEnd - 1 char"]
	set existingTags [$cmd tag names $start]
    }

    # Replace with current attributes

    lappend existingTags attrs:$id
    # TODO: make sure this works with TclDOM/libxml2
    $cmd insert $start [SerializeAttributeList [array get [::dom::node cget $node -attributes]]] $existingTags

    return {}
}

# domtext::NodeAttrRemoved --
#
#	React to a change in the attribute list for a node
#
# Arguments:
#	path	widget path
#	evid	DOM event node
#
# Results:
#	Display updated to reflect change to DOM structure

proc domtext::NodeAttrRemoved {path evid} {
    NodeAttrModified $path $evid
}

# domtext::NodePCDATAModified --
#
#	React to a change in character data
#
# Arguments:
#	path	widget path
#	evid	DOM event node
#
# Results:
#	Display updated to reflect change to DOM structure

proc domtext::NodePCDATAModified {path evid} {
    variable state

    set node [dom::event cget $evid -target]
    set id [$node cget -id]

    set cmd [dict get $state $path cmd]

    if {[string compare [$node cget -nodeType] "textNode"]} {
	return -code error "node is not a text node"
    }

    # Remember where the insertion point is
    set insert [$cmd index insert]

    # Remove previous text
    set ranges [$cmd tag ranges $id]
    set tags [$cmd tag names [lindex $ranges 0]]
    $cmd delete {*}$ranges

    # Replace with new text
    $cmd insert [lindex $ranges 0] [dom::event cget $evid -newValue] $tags

    # Restore insertion point
    $cmd mark set insert $insert

    return {}
}

# domtext::NodeSelected --
#
#	A node has been selected.
#
# Arguments:
#	path	widget path
#	evid	DOM event node
#
# Results:
#	Node's text is selected

proc domtext::NodeSelected {path evid} {
    variable state

    set node [dom::event cget $evid -target]
    set id [$node cget -id]
    dict set state $path selected $node

    set cmd [dict get $state $path cmd]

    catch {$cmd tag remove sel {*}[$cmd tag ranges sel]}

    set ranges [$cmd tag ranges $id]
    if {[llength $ranges]} {
	$cmd tag add sel {*}$ranges
	$cmd mark set insert [lindex $ranges end]
	$cmd see [lindex $ranges 0]
    }

    return {}
}

# domtext::TkeventOverride --
#
#	Certain Text widget class bindings must be prevented from firing
#
# Arguments:
#	path	widget path
#	x	x coord
#	y	y coord
#
# Results:
#	Return break error code

proc domtext::TkeventOverride {w x y} {
    return -code break
}

# domtext::TkeventSelect --
#
#	Single click.  We only want the highest priority tag to fire.
#
# Arguments:
#	path	widget path
#	node	DOM node
#	x
#	y	Coordinates
#
# Results:
#	DOM event posted

proc domtext::TkeventSelect {path node x y} {
    variable state
    variable tkeventid

    set cmd [dict get $state $path cmd]

    catch {after cancel $tkeventid}
    set tkeventid [after idle "
    dom::event postUIEvent [list $node] DOMActivate -detail 1
    dom::event postMouseEvent [list $node] click -detail 1
    [namespace current]::TkeventSelectSetinsert [list $path] [list $node] [tk::TextClosestGap $cmd $x $y]
"]
    return {}
}

# Helper routine for above proc

proc domtext::TkeventSelectSetinsert {path node idx} {
    variable state

    set cmd [dict get $state $path cmd]
    set id [$node cget -id]

    switch [$node cget -nodeType] {
	textNode {
	    # No need to change where the insertion point is going
	}
	element {
	    # Set the insertion point to the end of the first
	    # child textNode, or if none to immediately following
	    # the start tag.
	    set fc [$node cget -firstChild]
	    if {[string length $fc] && [$fc cget -nodeType] == "textNode"} {
		set idx [lindex [$cmd tag ranges [$fc cget -id]] end]
	    } else {
		set idx [lindex [$cmd tag ranges tag:start:$id] end]
	    }
	}
	default {
	    # Set the insertion point following the node
	    set idx [lindex [$cmd tag ranges $id] end]
	}
    }

    $cmd mark set insert $idx
    dict set state $path insert $idx
    $cmd mark set anchor insert
    focus $path

    return {}
}

# domtext::TkeventOpen --
#
#	Double click
#
# Arguments:
#	path	widget path
#	node	DOM node
#
# Results:
#	DOM event posted

proc domtext::TkeventOpen {path node} {
    variable tkeventid

    catch {after cancel $tkeventid}
    set tkeventid [after idle "
    dom::event postUIEvent [list $node] DOMActivate -detail 2
    dom::event postMouseEvent [list $node] click -detail 2
"]
    return {}
}

# domtext::KeySelect --
#
#	Select a node in which a key event has occurred.
#
# Arguments:
#	path	widget path
#	spec	the event specifier
#
# Results:
#	Appropriate node is selected.  Returns node id.

proc domtext::KeySelect {path spec} {
    variable state

    set root [dict get $state $path rootnode]
    set cmd [dict get $state $path cmd]
    set selected $root
    catch {set selected [dict get $state $path selected]}

    # If selected node is a textNode move around the text itself
    # Otherwise markup has been selected.
    # Move around the nodes

    switch -glob [$selected cget -nodeType],$spec {
	textNode,<Key-Up> {
	    set ranges [$cmd tag ranges $selected]
	    foreach {line char} [split [lindex $ranges 0] .] break
	    set index [$cmd index insert]
	    foreach {iline ichar} [split [lindex $index 0] .] break
	    if {$line == $iline} {
		set new [dom::node parent $selected]
	    } else {
		::tk::TextSetCursor $cmd [::tk::TextUpDownLine $cmd -1]
		# The insertion point may now be in another node
		set newnode [InsertToNode $path]
		if {[string compare $newnode $selected]} {
		    dom::event postUIEvent $newnode DOMActivate -detail 1
		}
		return -code break
	    }
	}
	textNode,<Key-Down> {
	    set ranges [$cmd tag ranges $selected]
	    foreach {line char} [split [lindex $ranges end] .] break
	    set index [$cmd index insert]
	    foreach {iline ichar} [split [lindex $index 0] .] break
	    if {$line == $iline} {
		bell
		return {}
	    } else {
		::tk::TextSetCursor $cmd [::tk::TextUpDownLine $cmd 1]
		# The insertion point may now be in another node
		set newnode [InsertToNode $path]
		if {[string compare $newnode $selected]} {
		    dom::event postUIEvent $newnode DOMActivate -detail 1
		}
		return -code break
	    }
	}
	textNode,<Key-Left> {
	    set ranges [$cmd tag ranges $selected]
	    set index [$cmd index insert]
	    if {[$cmd compare $index == [lindex $ranges 0]]} {
		set new [$selected cget -previousSibling]
		if {![string length $new]} {
		    set new [dom::node parent $selected]
		}
	    } else {
		::tk::TextSetCursor $cmd insert-1c
		return -code break
	    }
	}
	textNode,<Key-Right> {
	    set ranges [$cmd tag ranges $selected]
	    set index [$cmd index insert]
	    if {[$cmd compare $index == [lindex $ranges end]]} {
		set new [$selected cget -nextSibling]
		if {![string length $new]} {
		    set new [dom::node parent $selected]
		}
	    } else {
		::tk::TextSetCursor $cmd insert+1c
		return -code break
	    }
	}

	*,<Key-Up>	{
	    set new [dom::node parent $selected]
	}
	*,<Key-Down>	{
	    set new [$selected cget -firstChild]
	    if {![string length $new]} {
		bell
		return {}
	    }
	}
	*,<Key-Left>	{
	    if {[dom::node parent $selected] == $root} {
		bell
		return {}
	    }
	    set new [$selected cget -previousSibling]
	    if {![string length $new]} {
		set new [dom::node parent $selected]
	    }
	}
	*,<Key-Right>	{
	    set new [$selected cget -nextSibling]
	    if {![string length $new]} {
		set new [dom::node parent $selected]
	    }
	}
    }
    if {![string length $new]} {
	bell
    }

    dom::event postUIEvent $new DOMActivate -detail 1

    return -code break
}

# domtext::TkeventFilter_* --
#
#	React to editing events to keep the DOM structure
#	synchronised
#
# Arguments:
#	path	widget path
#	detail	key pressed
#
# Results:
#	Either event is blocked or passed through to the Text class binding
#	DOM events may be generated if text is inserted or deleted

proc domtext::TkeventFilter_<Key> {path detail} {
    variable state

    set cmd [dict get $state $path cmd]
    set selected [dict get $state $path selected]

    set index [$cmd index insert]

    $cmd tag remove sel 0.0 end

    # Take action depending upon which node type the event has occurred.
    # Possibilities are:
    #	text node			insert the text, update node
    #	element				If a text node exists as first child,
    #					redirect event to it and make it active.
    #					Otherwise create a text node
    #	Document Type Declaration	ignore
    #	XML Declaration			ignore

    switch [$selected cget -nodeType] {
	element {
	    set child [$selected cget -firstChild]
	    if {[string length $child]} {
		if {[$child cget -nodeType] == "textNode"} {
		    dom::event postUIEvent $child DOMActivate -detail 1
		    dom::node configure $child -nodeValue [$child cget -nodeValue]$detail
		    ::tk::TextSetCursor $cmd insert+1c
		    focus $path
		    return -code $code {}
		} else {
		    bell
		    return -code $code {}
		}
	    } else {
		set child [dom::document createTextNode $selected $detail]
		dom::event postUIEvent $child DOMActivate -detail 1
		# When we return the new text node will have been
		# inserted into the Text widget
		set end [lindex [$cmd tag ranges $child] 1]
		$cmd mark set insert $end
		$cmd tag remove sel 0.0 end
		focus $path
		return -code $code {}
	    }
	}
	textNode {

	    # We need to know where in the character data to insert the
	    # character.  This is hard, so instead allow the Text widget
	    # to do the insertion then take all of the text and
	    # set that as the node's value

	    $cmd insert insert $detail $selected
	    $cmd see insert
	    focus $path
	    set ranges [$cmd tag ranges $selected]
	    set newvalue [$cmd get [lindex $ranges 0] [lindex $ranges end]]
	    $selected configure -nodeValue $newvalue
	    return -code $code {}

	}
	default {
	    bell
	    return -code $code {}
	}
    }

    return -code $code {}
}

proc domtext::TkeventFilter_<Key-Return> {path detail} {
    set code [catch {TkeventFilter_<Key> $path \n} msg]
    return -code $code $msg
}
proc domtext::TkeventFilter_<Control-Key-i> {path detail} {
    set code [catch {TkeventFilter_<Key> $path \t} msg]
    return -code $code $msg
}
# Don't support transposition (yet)
proc domtext::TkeventFilter_<Control-Key-t> {path detail} {
    return -code break
}

proc domtext::TkeventFilter_<Control-Key-h> {path detail} {
    set code [catch {TkeventFilter_<Key-Backspace> $path $detail} msg]
    return -code $code $msg
}
proc domtext::TkeventFilter_<Key-BackSpace> {path detail} {
    variable state

    set cmd [dict get $state $path cmd]
    set selected [dict get $state $path selected]

    switch [$selected cget -nodeType] {
	textNode {
	    # If we're at the beginning of the text node stop here
	    set ranges [$cmd tag ranges $selected]
	    if {![llength $ranges] || [$cmd compare insert <= [lindex $ranges 0]]} {
		bell
		return -code break
	    }
	}
	default {
	    switch [tk_messageBox -parent [winfo toplevel $path] -title [mc {Confirm Delete Node}] -message [format [mc {Are you sure you want to delete a node of type %s?}] [$selected cget -nodeType]] -type okcancel] {
		ok {
		    dom::node removeNode [dom::node parent $selected] $selected
		}
		cancel {
		    return -code break
		}
	    }
	}
    }

    $cmd delete insert-1c
    $cmd see insert

    TkeventFilterUpdate $path

    return -code break
}
proc domtext::TkeventFilter_<Key-Delete> {path detail} {
    variable state

    set cmd [dict get $state $path cmd]
    set selected [dict get $state $path selected]

    switch [$selected cget -nodeType] {
	textNode {
	    # If we're at the beginning of the text node stop here
	    set ranges [$cmd tag ranges $selected]
	    if {[$cmd compare insert >= [lindex $ranges end]]} {
		bell
		return -code break
	    }
	}
	default {
	    switch [tk_messageBox -parent [winfo toplevel $path] -title [mc {Confirm Delete Node}] -message [format [mc {Are you sure you want to delete a node of type %s?}] [$selected cget -nodeType]] -type okcancel] {
		ok {
		    dom::node removeNode [dom::node parent $selected] $selected
		}
		cancel {
		    return -code break
		}
	    }
	}
    }

    $cmd delete insert
    $cmd see insert

    TkeventFilterUpdate $path

    return -code break
}
proc domtext::TkeventFilterUpdate path {
    variable state

    set cmd [dict get $state $path cmd]
    set selected [dict get $state $path selected]

    # Now update the DOM node's value

    set ranges [$cmd tag ranges $selected]

    # If all text has been deleted then remove the node
    if {[llength $ranges]} {
	set newtext [$cmd get [lindex $ranges 0] [lindex $ranges end]]
	$selected configure -nodeValue $newtext
    } else {
	set parent [dom::node parent $selected]
	dom::node removeNode [dom::node parent $selected] $selected
	# Move selection to parent element, rather than removing selection
	#unset selected
	dom::event postUIEvent $parent DOMActivate -detail 1
    }

    return {}
}

# This will delete from the insertion point to the end of the line
# or text node, whichever is shorter
# TODO: implement this
proc domtext::TkeventFilter_<Control-Key-k> {path detail} {
    return -code break
}
# TODO: this will delete the word to the left of the insertion point
# (only within the text node)
proc domtext::TkeventFilter_<Meta-Key-Delete> {path detail} {
    return -code break
}
proc domtext::TkeventFilter_<Meta-Key-BackSpace> {path detail} {
    TkeventFilter_<Meta-Key-Delete> $path $detail
}

### Utilities

# domtext::InsertToNode --
#
#	Finds the DOM node for the insertion point
#
# Arguments:
#	path	widget path
#
# Results:
#	Returns DOM token

proc domtext::InsertToNode path {
    variable state

    set cmd [dict get $state $path cmd]

    set tags [$cmd tag names insert]
    set newnode [lindex $tags end]
    while {![dom::DOMImplementation isNode $newnode]} {
	set tags [lreplace $tags end end]
	set newnode [lindex $tags end]
    }
    return $newnode
}

### Inlined images

image create photo ::domtext::starttab -data {
R0lGODlhEAAYAPcAAP//////zP//mf//Zv//M///AP/M///MzP/Mmf/MZv/M
M//MAP+Z//+ZzP+Zmf+ZZv+ZM/+ZAP9m//9mzP9mmf9mZv9mM/9mAP8z//8z
zP8zmf8zZv8zM/8zAP8A//8AzP8Amf8AZv8AM/8AAMz//8z/zMz/mcz/Zsz/
M8z/AMzM/8zMzMzMmczMZszMM8zMAMyZ/8yZzMyZmcyZZsyZM8yZAMxm/8xm
zMxmmcxmZsxmM8xmAMwz/8wzzMwzmcwzZswzM8wzAMwA/8wAzMwAmcwAZswA
M8wAAJn//5n/zJn/mZn/Zpn/M5n/AJnM/5nMzJnMmZnMZpnMM5nMAJmZ/5mZ
zJmZmZmZZpmZM5mZAJlm/5lmzJlmmZlmZplmM5lmAJkz/5kzzJkzmZkzZpkz
M5kzAJkA/5kAzJkAmZkAZpkAM5kAAGb//2b/zGb/mWb/Zmb/M2b/AGbM/2bM
zGbMmWbMZmbMM2bMAGaZ/2aZzGaZmWaZZmaZM2aZAGZm/2ZmzGZmmWZmZmZm
M2ZmAGYz/2YzzGYzmWYzZmYzM2YzAGYA/2YAzGYAmWYAZmYAM2YAADP//zP/
zDP/mTP/ZjP/MzP/ADPM/zPMzDPMmTPMZjPMMzPMADOZ/zOZzDOZmTOZZjOZ
MzOZADNm/zNmzDNmmTNmZjNmMzNmADMz/zMzzDMzmTMzZjMzMzMzADMA/zMA
zDMAmTMAZjMAMzMAAAD//wD/zAD/mQD/ZgD/MwD/AADM/wDMzADMmQDMZgDM
MwDMAACZ/wCZzACZmQCZZgCZMwCZAABm/wBmzABmmQBmZgBmMwBmAAAz/wAz
zAAzmQAzZgAzMwAzAAAA/wAAzAAAmQAAZgAAM+4AAN0AALsAAKoAAIgAAHcA
AFUAAEQAACIAABEAAADuAADdAAC7AACqAACIAAB3AABVAABEAAAiAAARAAAA
7gAA3QAAuwAAqgAAiAAAdwAAVQAARAAAIgAAEe7u7t3d3bu7u6qqqoiIiHd3
d1VVVURERCIiIhEREQAAACwAAAAAEAAYAAcIgwABCBxIsKBAfAjx2TNYMCHC
hQwPOrwHkaFDhRQjXtR3L6PBix3teSR4USRHexUlJuTY8WRFkBQ7dsQ3sOS9
kzNrOmR5M6dKhCFl3qP5EyPOoTpXymRJFABMkTKb2sSZL19ShDz1WSU5MeZW
rglNfgWL9d5YsvjMRgRQte3ZtXABAggIADs=
}
image create photo ::domtext::endtab -data {
R0lGODlhEAAYAPcAAP//////zP//mf//Zv//M///AP/M///MzP/Mmf/MZv/M
M//MAP+Z//+ZzP+Zmf+ZZv+ZM/+ZAP9m//9mzP9mmf9mZv9mM/9mAP8z//8z
zP8zmf8zZv8zM/8zAP8A//8AzP8Amf8AZv8AM/8AAMz//8z/zMz/mcz/Zsz/
M8z/AMzM/8zMzMzMmczMZszMM8zMAMyZ/8yZzMyZmcyZZsyZM8yZAMxm/8xm
zMxmmcxmZsxmM8xmAMwz/8wzzMwzmcwzZswzM8wzAMwA/8wAzMwAmcwAZswA
M8wAAJn//5n/zJn/mZn/Zpn/M5n/AJnM/5nMzJnMmZnMZpnMM5nMAJmZ/5mZ
zJmZmZmZZpmZM5mZAJlm/5lmzJlmmZlmZplmM5lmAJkz/5kzzJkzmZkzZpkz
M5kzAJkA/5kAzJkAmZkAZpkAM5kAAGb//2b/zGb/mWb/Zmb/M2b/AGbM/2bM
zGbMmWbMZmbMM2bMAGaZ/2aZzGaZmWaZZmaZM2aZAGZm/2ZmzGZmmWZmZmZm
M2ZmAGYz/2YzzGYzmWYzZmYzM2YzAGYA/2YAzGYAmWYAZmYAM2YAADP//zP/
zDP/mTP/ZjP/MzP/ADPM/zPMzDPMmTPMZjPMMzPMADOZ/zOZzDOZmTOZZjOZ
MzOZADNm/zNmzDNmmTNmZjNmMzNmADMz/zMzzDMzmTMzZjMzMzMzADMA/zMA
zDMAmTMAZjMAMzMAAAD//wD/zAD/mQD/ZgD/MwD/AADM/wDMzADMmQDMZgDM
MwDMAACZ/wCZzACZmQCZZgCZMwCZAABm/wBmzABmmQBmZgBmMwBmAAAz/wAz
zAAzmQAzZgAzMwAzAAAA/wAAzAAAmQAAZgAAM+4AAN0AALsAAKoAAIgAAHcA
AFUAAEQAACIAABEAAADuAADdAAC7AACqAACIAAB3AABVAABEAAAiAAARAAAA
7gAA3QAAuwAAqgAAiAAAdwAAVQAARAAAIgAAEe7u7t3d3bu7u6qqqoiIiHd3
d1VVVURERCIiIhEREQAAACwAAAAAEAAYAAcIgwABCBxIsKDBgvbwKcR3cGDC
hQwb2rsHMaLBiQ8XHpx4T1/Fi/c4fiRob6K+kCMBlOx4r6VHiAPxtWwpEqZA
mSFZZlQY0+XMlxpvzsxJ0SYAnCZRGsV50mVKnDRbpsyXL+fJnRYF5mvaMeXA
qjWDFtyqVOzYrkYNVvWqlqrbhg0BAggIADs=
}

