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

  <xsl:output method='html'/>
  <xsl:strip-space elements='*'/>
  <xsl:preserve-space elements='d:literallayout d:programlisting'/>

  <xsl:template match='d:article'>
    <html>
      <head>
        <meta http-equiv="Content-Type" content="text/html; charset=UTF-8"/>
        <title>
          <xsl:apply-templates select="d:info/d:title"
            mode='html-title'/>
        </title>
        <link rel='stylesheet' href='tclxml.css'/>
      </head>
      <body>
        <div class="{local-name(.)}">
          <h1 class="title">
            <a>
              <xsl:attribute name="name">
                <xsl:call-template name="object.id"/>
              </xsl:attribute>
              <xsl:apply-templates select="d:info/d:title/node()"/>
            </a>
          </h1>
          <xsl:apply-templates select='d:info/d:subtitle'/>
          <h2>Contents</h2>
          <ul>
            <xsl:if test="d:refsynopsisdiv">
              <li><a href="#synopsis">Synopsis</a></li>
            </xsl:if>
            <xsl:for-each select="d:sect1|d:section">
              <li>
                <a href="#{generate-id()}">
                  <xsl:apply-templates select="d:info/d:title" mode='toc'/>
                </a>
                <xsl:if test="d:sect2|d:section">
                  <ul>
                    <xsl:for-each select="d:sect2|d:section">
                      <li>
                        <a href="#{generate-id()}">
                          <xsl:apply-templates select="d:info/d:title" mode='toc'/>
                        </a>
                        <xsl:if test="d:sect3|d:section">
                          <ul>
                            <xsl:for-each select="d:sect3|d:section">
                              <li>
                                <a href="#{generate-id()}">
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

          <xsl:variable name='footnotes' select='//d:footnote'/>
          <xsl:if test='$footnotes'>
            <div id='footnotes'>
              <h2>Footnotes</h2>
              <xsl:apply-templates select='$footnotes' mode='footnote'/>
            </div>
          </xsl:if>
        </div>
      </body>
    </html>
  </xsl:template>

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

    <html>
      <head>
        <meta http-equiv="Content-Type" content="text/html; charset=UTF-8"/>
        <title>
          <xsl:copy-of select="$title"/>
        </title>
        <link rel='stylesheet' href='tclxml.css'/>
      </head>
      <body>
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
              <li>
                <a href="#{generate-id()}">
                  <xsl:apply-templates select="d:info/d:title" mode='toc'/>
                </a>
                <xsl:if test="d:refsect2">
                  <ul>
                    <xsl:for-each select="d:refsect2">
                      <li>
                        <a href="#{generate-id()}">
                          <xsl:apply-templates select="d:info/d:title" mode='toc'/>
                        </a>
                        <xsl:if test="d:refsect3">
                          <ul>
                            <xsl:for-each select="d:refsect3">
                              <li>
                                <a href="#{generate-id()}">
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

          <xsl:variable name='footnotes' select='//d:footnote'/>
          <xsl:if test='$footnotes'>
            <div id='footnotes'>
              <h2>Footnotes</h2>
              <xsl:apply-templates select='$footnotes' mode='footnote'/>
            </div>
          </xsl:if>
        </div>
      </body>
    </html>
  </xsl:template>

  <xsl:template match='d:article/d:info/d:title'/>

  <xsl:template match='d:subtitle'>
    <h3>
      <xsl:apply-templates/>
    </h3>
  </xsl:template>

  <xsl:template match='d:footnote' mode='footnote'>
    <div class='footnote'>
      <a name='fn_{generate-id()}'/>
      <div>
        <span class='footnote_label'>
          <xsl:number level='any'/>
        </span>
        <xsl:apply-templates select='*[self::d:para][1]/node()'/>
      </div>
      <xsl:apply-templates select='*[position() != 1]'/>
    </div>
  </xsl:template>

  <xsl:template match='d:footnote'>
    <span class='footnoteref'>
      <a href='fn_{generate-id()}'>
        <xsl:number level='any'/>
      </a>
    </span>
  </xsl:template>

  <xsl:template match='d:refmeta'/>

  <xsl:template match='d:keywordset'>
    <div class='keywordset'>
      <xsl:apply-templates/>
    </div>
  </xsl:template>
  <xsl:template match='d:keyword'>
    <xsl:if test='preceding-sibling::d:keyword'>, </xsl:if>
    <xsl:apply-templates/>
  </xsl:template>

  <xsl:template match='d:section |
                       d:refsect1 |
                       d:refsect2 |
                       d:refsect3 |
                       d:refnamediv'>
    <div class='{local-name()}'>
      <xsl:apply-templates/>
    </div>
  </xsl:template>
  <xsl:template match='d:refname'>
    <xsl:if test='preceding-sibling::d:refname'>, </xsl:if>
    <span class='{local-name()}'>
      <xsl:apply-templates/>
    </span>
  </xsl:template>
  <xsl:template match='d:refpurpose'>
    <xsl:text> &#x2014; </xsl:text>
    <span class='{local-name()}'>
      <xsl:apply-templates/>
    </span>
  </xsl:template>

  <xsl:template match="d:refsynopsisdiv">
    <div class="{local-name(.)}">
      <a name="synopsis"/>
      <h2>Synopsis</h2>
      <xsl:apply-templates select="*[not(self::tcl:namespacesynopsis)]"/>
      <xsl:apply-templates select="tcl:namespacesynopsis"/>
    </div>
  </xsl:template>

  <xsl:template match="tcl:cmdsynopsis">
    <xsl:variable name="id"><xsl:call-template name="object.id"/></xsl:variable>

    <div class="{local-name()}" id="{$id}">
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
  <xsl:template match="d:option">
    <xsl:text> </xsl:text>
    <em><xsl:apply-templates/></em>
  </xsl:template>
  <xsl:template match="d:group">
    <xsl:text> </xsl:text>
    <xsl:if test="@choice='opt'">
      <xsl:text>?</xsl:text>
    </xsl:if>
    <xsl:if test="not(@choice) and count(d:arg) > 1">
      <xsl:text>"</xsl:text>
    </xsl:if>

    <xsl:apply-templates/>

    <xsl:if test="@rep='repeat'">
      <xsl:text>...</xsl:text>
    </xsl:if>
    <xsl:if test="not(@choice) and count(d:arg) > 1">
      <xsl:text>"</xsl:text>
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

  <xsl:template match="tcl:command|d:command">
    <xsl:call-template name="inline.boldseq"/>
  </xsl:template>

  <xsl:template match='tcl:package|tcl:namespace|tcl:method|d:classname|d:application|d:tag|d:filename'>
    <xsl:call-template name='inline.monoseq'/>
  </xsl:template>

  <xsl:template match="tcl:pkgsynopsis">
    <br/>
    <span class="{name(.)}">
      <pre>package require <xsl:value-of select="d:package"/> ?<xsl:value-of select="d:version"/>?</pre>
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
    <xsl:text> </xsl:text>
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
    <xsl:text> </xsl:text>
    <xsl:call-template name="inline.monoseq"/>
  </xsl:template>

  <xsl:template match='d:replaceable'>
    <em>
      <xsl:apply-templates/>
    </em>
  </xsl:template>

  <xsl:template match='d:info'>
    <xsl:apply-templates select='d:title | d:subtitle'/>
  </xsl:template>
  <xsl:template match='d:refsect1/d:info/d:title'>
    <h2>
      <a name='{generate-id(../..)}'/>
      <xsl:apply-templates/>
    </h2>
  </xsl:template>
  <xsl:template match='d:refsect2/d:info/d:title'>
    <h3>
      <a name='{generate-id(../..)}'/>
      <xsl:apply-templates/>
    </h3>
  </xsl:template>
  <xsl:template match='d:refsect3/d:info/d:title'>
    <h4>
      <a name='{generate-id(../..)}'/>
      <xsl:apply-templates/>
    </h4>
  </xsl:template>
  <xsl:template match='d:section/d:info/d:title'>
    <xsl:element name='h{count(ancestor::d:section) + 2}'>
      <a name='{generate-id(../..)}'/>
      <xsl:apply-templates/>
    </xsl:element>
  </xsl:template>

  <xsl:template match='d:para'>
    <p>
      <xsl:apply-templates/>
    </p>
  </xsl:template>

  <xsl:template match='d:note'>
    <div class='note'>
      <xsl:apply-templates/>
    </div>
  </xsl:template>

  <xsl:template match='d:informalexample|d:programlisting|d:computeroutput'>
    <div class='{local-name()}'>
      <pre>
        <xsl:apply-templates/>
      </pre>
    </div>
  </xsl:template>
  <xsl:template match='d:example'>
    <h4>
      <xsl:apply-templates select='d:info/d:title/node() |
                                   d:title/node()'/>
    </h4>
    <div class='{local-name()}'>
      <pre>
        <xsl:apply-templates select='*[not(self::d:title|self::d:info)]'/>
      </pre>
    </div>
  </xsl:template>

  <xsl:template match='d:variablelist'>
    <dl>
      <xsl:apply-templates/>
    </dl>
  </xsl:template>
  <xsl:template match='d:varlistentry'>
    <xsl:apply-templates/>
  </xsl:template>
  <xsl:template match='d:term'>
    <dt>
      <xsl:apply-templates/>
    </dt>
  </xsl:template>
  <xsl:template match='d:varlistentry/d:listitem'>
    <dd>
      <xsl:apply-templates/>
    </dd>
  </xsl:template>

  <xsl:template match='d:itemizedlist'>
    <ul>
      <xsl:apply-templates/>
    </ul>
  </xsl:template>
  <xsl:template match='d:orderedlist'>
    <ol>
      <xsl:apply-templates/>
    </ol>
  </xsl:template>
  <xsl:template match='d:itemizedlist/d:listitem |
                       d:orderedlist/d:listitem'>
    <li>
      <xsl:apply-templates/>
    </li>
  </xsl:template>

  <xsl:template match='d:arg'>
    <xsl:choose>
      <xsl:when test='parent::d:group and preceding-sibling::d:arg'>
        <xsl:text> | </xsl:text>
        <span class='arg'>
          <xsl:apply-templates/>
        </span>
      </xsl:when>
      <xsl:when test='preceding-sibling::d:arg'>
        <xsl:text> </xsl:text>
        <span class='arg'>
          <xsl:apply-templates/>
        </span>
      </xsl:when>
      <xsl:otherwise>
        <span class='arg'>
          <xsl:apply-templates/>
        </span>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <xsl:template match='d:literal|d:term|d:methodname'>
    <span class='{local-name()}'>
      <xsl:apply-templates/>
    </span>
  </xsl:template>

  <xsl:template match='d:acronym'>
    <xsl:choose>
      <xsl:when test='@xlink:href'>
        <a href='{@xlink:href}'>
          <xsl:apply-templates/>
        </a>
      </xsl:when>
      <xsl:otherwise>
        <em>
          <xsl:apply-templates/>
        </em>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>
  <xsl:template match='d:link'>
    <a href='{@xlink:href}'>
      <xsl:apply-templates/>
    </a>
  </xsl:template>

  <xsl:template match='d:emphasis'>
    <em>
      <xsl:apply-templates/>
    </em>
  </xsl:template>

  <xsl:template name='inline.boldseq'>
    <strong>
      <xsl:apply-templates/>
    </strong>
  </xsl:template>

  <xsl:template name='inline.monoseq'>
    <tt>
      <xsl:apply-templates/>
    </tt>
  </xsl:template>

  <!-- Borrowed from DocBook XSL stylesheets: common/common.xsl -->
  <xsl:template name="object.id">
    <xsl:param name="object" select="."/>
    <xsl:choose>
      <xsl:when test="$object/@id">
        <xsl:value-of select="$object/@id"/>
      </xsl:when>
      <xsl:when test="$object/@xml:id">
        <xsl:value-of select="$object/@xml:id"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:value-of select="generate-id($object)"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <xsl:template match='*'>
    <xsl:message>unmatched element "<xsl:value-of select='name()'/>" in "<xsl:value-of select='name(../..)'/>/<xsl:value-of select='name(..)'/>"</xsl:message>
  </xsl:template>

</xsl:stylesheet>
