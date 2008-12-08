<xsl:stylesheet version='1.0'
		xmlns:xsl='http://www.w3.org/1999/XSL/Transform'
		xmlns:d='http://docbook.org/ns/docbook'
		xmlns:xlink='http://www.w3.org/1999/xlink'
		xmlns:tcl='http://tclxml.sourceforge.net/doc'
		exclude-result-prefixes='d xlink tcl'>

  <!--
     - html.xsl -
     -
     - Copyright (c) 2008 Explain
     - http://www.explain.com.au/
     - Copyright (c) 2000 Zveno Pty Ltd
     -
     -	XSLT stylesheet to convert TclXML docs to HTML.
     -
     - $Id: html.xsl,v 1.2 2002/06/11 13:37:45 balls Exp $
  -->

  <!-- Provide a template which adds a TOC -->

  <xsl:template match="d:refentry">
    <xsl:variable name="refmeta" select=".//d:refmeta"/>
    <xsl:variable name="refentrytitle" select="$refmeta//d:refentrytitle"/>
    <xsl:variable name="refnamediv" select=".//d:refnamediv"/>
    <xsl:variable name="refname" select="$refnamediv//d:refname"/>
    <xsl:variable name="title">
      <xsl:choose>
	<xsl:when test="$refentrytitle">
	  <xsl:apply-templates select="$refentrytitle[1]" mode="title"/>
	</xsl:when>
	<xsl:when test="$refname">
	  <xsl:apply-templates select="$refname[1]" mode="title"/>
	</xsl:when>
      </xsl:choose>
    </xsl:variable>

    <div class="{local-name(.)}">
      <h1 class="title">
	<a>
	  <xsl:attribute name="name">
	    <xsl:call-template name="object.id"/>
	  </xsl:attribute>
	  <xsl:copy-of select="$title"/>
	</a>
      </h1>
      <h2>Contents</h2>
      <ul>
	<xsl:if test="d:refsynopsisdiv">
	  <li><a href="#synopsis">Synopsis</a></li>
	</xsl:if>
	<xsl:for-each select="d:refsect1">
	  <xsl:variable name="sect1name"
			select="translate(d:info/d:title,' ','-')"/>
	  <li>
	    <a href="#{$sect1name}">
              <xsl:apply-templates select="d:info/d:title" mode='toc'/>
            </a>
	    <xsl:if test="d:refsect2">
	      <ul>
		<xsl:for-each select="d:refsect2">
		  <xsl:variable name="sect2name"
                    select="translate(d:info/d:title,' ','-')"/>
		  <li>
		    <a href="#{$sect1name}-{$sect2name}">
                      <xsl:apply-templates select="d:info/d:title" mode='toc'/>
                    </a>
		    <xsl:if test="d:refsect3">
		      <ul>
			<xsl:for-each select="d:refsect3">
			  <xsl:variable name="sect3name"
                            select="translate(d:info/d:title,' ','-')"/>
			  <li>
			    <a href="#{$sect1name}-{$sect2name}-{$sect3name}">
                              <xsl:apply-templates select="d:info/d:title"
                                mode='toc'/>
                            </a>
			  </li>
			</xsl:for-each>
		      </ul>
		    </xsl:if>
		  </li>
		</xsl:for-each>
	      </ul>
	    </xsl:if>
	  </li>
	</xsl:for-each>
      </ul>
      <xsl:apply-templates/>
      <xsl:call-template name="process.footnotes"/>
    </div>
  </xsl:template>

  <xsl:template match="d:refsynopsisdiv">
    <div class="{local-name(.)}">
      <a name="synopsis"/>
      <h2>Synopsis</h2>
      <xsl:apply-templates select="*[not(self::tcl:namespacesynopsis)]"/>
      <xsl:apply-templates select="tcl:namespacesynopsis"/>
    </div>
  </xsl:template>

  <xsl:template match="tclcmdsynopsis">
    <xsl:variable name="id"><xsl:call-template name="object.id"/></xsl:variable>

    <div class="{local-name(.)}" id="{$id}">
      <a name="{$id}"/>
      <xsl:apply-templates/>
    </div>
  </xsl:template>
  <xsl:template match="tcl:cmdsynopsis/d:command">
    <br/>
    <xsl:call-template name="inline.monoseq"/>
    <xsl:text> </xsl:text>
  </xsl:template>
  <xsl:template match="tcl:cmdsynopsis/d:command[1]">
    <xsl:call-template name="inline.monoseq"/>
    <xsl:text> </xsl:text>
  </xsl:template>

  <xsl:template match="d:refsynopsisdiv/tcl:cmdsynopsis/d:command">
    <xsl:variable name="id"><xsl:call-template name="object.id"/></xsl:variable>

    <br/>
    <span class="{local-name(.)}" id="{$id}">
      <a name="{translate(.,': ','__')}"/>
      <xsl:call-template name="inline.monoseq"/>
      <xsl:text> </xsl:text>
    </span>
  </xsl:template>
  <xsl:template match="d:refsynopsisdiv/tcl:cmdsynopsis/d:command[1]">
    <xsl:variable name="id"><xsl:call-template name="object.id"/></xsl:variable>

    <span class="{local-name(.)}" id="{$id}">
      <a name="{translate(.,': ','__')}"/>
      <xsl:call-template name="inline.monoseq"/>
      <xsl:text> </xsl:text>
    </span>
  </xsl:template>
  <xsl:template match="tcl:cmdsynopsis/d:option">
    <u><xsl:apply-templates/></u>
  </xsl:template>
  <xsl:template match="tcl:cmdsynopsis/d:group">
    <xsl:if test="@choice='opt'">
      <xsl:text>?</xsl:text>
    </xsl:if>
    <xsl:apply-templates/>
    <xsl:if test="@rep='repeat'">
      <xsl:text>...</xsl:text>
    </xsl:if>
    <xsl:if test="@choice='opt'">
      <xsl:text>?</xsl:text>
    </xsl:if>
  </xsl:template>
  <xsl:template match="tcl:cmdsynopsis//d:arg[1]">
    <xsl:apply-templates/>
  </xsl:template>
  <xsl:template match="tcl:cmdsynopsis//d:arg[position() > 1]">
    <xsl:text> </xsl:text>
    <xsl:apply-templates/>
  </xsl:template>

  <xsl:template match="tcl:command">
    <a href="#{translate(.,': ','__')}">
      <xsl:call-template name="inline.boldseq"/>
    </a>
  </xsl:template>

  <xsl:template match='tcl:package|tcl:namespace'>
    <xsl:call-template name='inline.monoseq'/>
  </xsl:template>

  <xsl:template match="tcl:pkgsynopsis">
    <br/>
    <span class="{name(.)}">
      <pre>package require <xsl:value-of select="tcl:package"/> ?<xsl:value-of select="tcl:version"/>?</pre>
    </span>
  </xsl:template>

  <xsl:template match="tcl:namespacesynopsis">
    <h3>Tcl Namespace Usage</h3>
    <xsl:apply-templates/>
    <p/>
  </xsl:template>

  <xsl:template match="tcl:namespacesynopsis/tcl:namespace[1]">
    <xsl:call-template name="inline.monoseq"/>
  </xsl:template>

  <xsl:template match="tcl:namespacesynopsis/tcl:namespace">
    <br/>
    <xsl:call-template name="inline.monoseq"/>
  </xsl:template>

  <xsl:template match="d:refsect1[d:info/d:title = 'Commands'][d:refsect2/d:info/d:title]//tcl:cmdsynopsis/*[position() = 1 and local-name() = 'option']">
    <tt>
      <xsl:choose>
	<xsl:when test="ancestor::d:refsect3//*[@role='subject']">
	  <i><xsl:value-of select="ancestor::d:refsect3//*[@role='subject']"/></i>
	</xsl:when>
        <xsl:when test="ancestor::d:refsect2/d:info/d:title">
          <xsl:value-of select="ancestor::d:refsect2/d:info/d:title"/>
	</xsl:when>
      </xsl:choose>
    </tt>
    <xsl:text> </xsl:text>
    <u><xsl:apply-templates/></u>
  </xsl:template>

  <xsl:template match="tcl:optionsynopsis">
    <p>
      <xsl:apply-templates/>
    </p>
  </xsl:template>

  <xsl:template match="tcl:optionsynopsis/d:option">
    <xsl:call-template name="inline.monoseq"/>
  </xsl:template>

  <xsl:template match="tcl:optionsynopsis/d:arg">
    <u>
      <xsl:apply-templates/>
    </u>
  </xsl:template>

  <!-- Do a segmentedlist as a table, instead of the poxy way DocBook does them -->

  <xsl:template match="d:segmentedlist">
    <table border="0">
      <xsl:apply-templates/>
    </table>
  </xsl:template>

  <xsl:template match="d:seglistitem">
    <tr>
      <xsl:apply-templates/>
    </tr>
  </xsl:template>

  <xsl:template match="d:seg">
    <td valign="top">
      <xsl:apply-templates/>
    </td>
  </xsl:template>

  <xsl:template match="d:seg/d:arg">
    <xsl:call-template name="inline.monoseq"/>
  </xsl:template>

  <xsl:template match='*'>
    <xsl:message>unmatched element "<xsl:value-of select='name()'/>" in "<xsl:value-of select='name(..)'/>"</xsl:message>
  </xsl:template>

</xsl:stylesheet>
