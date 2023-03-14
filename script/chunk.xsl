<?xml version="1.0"?>
 
<!--Chunking fixed.xml to generate index pages, appendixes, and individual element pages-->

<xsl:stylesheet version="2.0" 
                xmlns="http://www.w3.org/1999/xhtml"
				xmlns:w="http://www.wiley.com/namespaces/wiley"
				xmlns:m="http://www.w3.org/1998/Math/MathML"				
                xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
				xmlns:aux="http://www.wiley.com/namespaces/wiley/aux"
				xmlns:xlink="http://www.w3.org/1999/xlink"
				xpath-default-namespace=""
                exclude-result-prefixes="#all">

				
<xsl:output method="xhtml"
			encoding="utf8" 
			omit-xml-declaration="yes"
			indent="yes"/>
							
<xsl:strip-space elements="sect1 sect2 informaltable tgroup tbody row link screen"/>
							
<xsl:param name="number-of-columns" select="5"/>
<xsl:param name="html_stylesheet" select="'doc.css'"/>
<xsl:param name="element-tree_js" select="'element-tree.js'"/>
<xsl:param name="index_file" select="'index.html'"/>
<xsl:param name="attributes_file" select="'attributes.html'"/>
<xsl:param name="tree_file" select="'element_tree.html'"/>
	
<xsl:variable name="main_title" select="concat(upper-case(//chapter/@source), ' Manual')"/>
						
<!-- ============================================================ main templates ================================================================ -->
<xsl:template match="/">	
	<xsl:call-template name="generate_attributes"/>
	<xsl:call-template name="generate_tree"/>
  	<xsl:call-template name="generate_index"/>
 	<xsl:call-template name="generate_individual_pages"/>
</xsl:template>


<xsl:template match="*">
	<xsl:message>  ERROR! Unknown XML element <xsl:value-of select="local-name()"/> in <xsl:value-of select="ancestor::sect1/title"/></xsl:message>
	<xsl:copy>
		<xsl:apply-templates select="@*, node()"/>
	</xsl:copy>
</xsl:template>


<xsl:template match="@*">
	<xsl:copy-of select="."/>
</xsl:template>
	
	
<xsl:template match="text()">
	<xsl:copy-of select="."/>
</xsl:template>


<xsl:template name="html5-declaration">
<xsl:text disable-output-escaping="yes">&lt;!DOCTYPE html&gt;
</xsl:text>
</xsl:template>
<!-- ========================================================= end of main templates ============================================================ -->


<!-- ============================================================== index.html ================================================================== -->
<xsl:template name="generate_index">
	<xsl:call-template name="html5-declaration"/>
	<html>
		<head>
			<title><xsl:value-of select="$main_title"/></title>
			<link rel="stylesheet" href="{$html_stylesheet}" type="text/css" />
		</head>
		<body class="index doc">
			<nav class="top">
				<table>
					<tr>
						<td class="nav"><a href="{$tree_file}">Element Tree</a> | <a href="{$attributes_file}">Attributes</a></td>
					</tr>
				</table>
			</nav>
			
			<article>
				<h1><xsl:value-of select="$main_title"/></h1>

	            <section class="toc">
					<xsl:variable name="per-column"><xsl:value-of select="ceiling(count(book/chapter/sect1) div $number-of-columns)"/></xsl:variable>
					<table>
						<tr>
							<xsl:for-each select="book/chapter/sect1[position() mod $per-column = 1]">
								<td width="200px">
									<xsl:for-each select=".|following-sibling::sect1[position() &lt; $per-column]">
										<a href="{concat(@id,'.html')}" shape="rect"><xsl:value-of select="title"/></a><br/>
									</xsl:for-each>
								</td>
							</xsl:for-each>
						</tr>
					</table>
				</section>
	        </article>
		</body>
	</html>	
	
	<xsl:message>&#xA0;&#xA0;<xsl:value-of select="$index_file"/> - done</xsl:message>	
</xsl:template>	
<!-- =========================================================== end of index.html ============================================================== -->


<!-- ============================================================ attributes.html =============================================================== -->
<xsl:template name="generate_attributes">
	<xsl:result-document method="xhtml" href="{$attributes_file}" encoding="utf8" indent="no" include-content-type="no">
		<xsl:call-template name="html5-declaration"/>
		<html>
			<head>
				<title><xsl:value-of select="$main_title"/> - Attributes</title>
				<link rel="stylesheet" href="{$html_stylesheet}" type="text/css"/>
			</head>
			<body class="apb doc">
				<nav class="top">
					<table>
						<tr>
							<td class="nav"><a href="{$index_file}">Index Page</a> | <a href="{$tree_file}">Element Tree</a></td>
						</tr>
					</table>
				</nav>
				<article>
					<h1><xsl:value-of select="$main_title"/> - Attributes</h1>
				
					<xsl:variable name="all_attributes" select="string-join(distinct-values(//sect2[title eq 'Attributes']//row/entry[1]/sgmltag/node()),' ')"/>
					<xsl:variable name="chapter" select="//chapter"/>

					<div class="informaltable">
						<table>
							<thead>
								<tr>
									<th>Attribute</th>
									<th>Elements on Which This Attribute Occurs</th>
								</tr>
							</thead>
							<tbody>
								<xsl:for-each select="tokenize($all_attributes,' ')">
									<xsl:sort select="."/>
									<xsl:variable name="name" select="."/>
									<tr id="{$name}">
										<td><xsl:value-of select="$name"/></td>
										<td>
											<xsl:variable name="elements_list">
												<xsl:for-each select="$chapter/sect1[sect2[title eq 'Attributes']//row/entry[1][sgmltag eq $name]]">
													<a class="xref" href="{concat(@id,'.html')}" title="{.//row[entry[1][sgmltag eq $name]]/entry[4]}"><xsl:value-of select="title"/></a>
													<xsl:if test="position() ne last()"><xsl:text>, </xsl:text></xsl:if>
												</xsl:for-each>
											</xsl:variable>
									
											<xsl:choose>
												<xsl:when test="count($chapter/sect1) = count($elements_list/*)">[Global attribute]</xsl:when> <!-- No such cases so far -->
												<xsl:otherwise><xsl:copy-of select="$elements_list"/></xsl:otherwise>												
											</xsl:choose>											
										</td>
									</tr>
								</xsl:for-each>
							</tbody>							
						</table>	
					</div>				
				</article>
			</body>
		</html>
	</xsl:result-document>
	<xsl:message>&#xA0;&#xA0;<xsl:value-of select="$attributes_file"/> - done</xsl:message>	
</xsl:template>
<!-- ========================================================= end of attributes.html =========================================================== -->


<!-- ========================================================== element_tree.html =============================================================== -->
<xsl:template name="generate_tree">
	<xsl:result-document method="xhtml" href="{$tree_file}" encoding="utf8" indent="no">
		<xsl:call-template name="html5-declaration"/>
		<html>
			<head>
				<title><xsl:value-of select="$main_title"/> - Tree</title>
				<link rel="stylesheet" href="{$html_stylesheet}" type="text/css"/>
				<script src="{$element-tree_js}"></script>
			</head>
			<body class="doc">
				<nav class="top">
					<table>
						<tr>
							<td class="nav"><a href="{$index_file}">Index Page</a> | <a href="{$attributes_file}">Attributes</a></td>
						</tr>
					</table>
				</nav>
				<article>
					<h1><xsl:value-of select="$main_title"/> - Element Tree</h1>
		            <div class="structure"> <!-- invisible list of all elements' content models -->
						<xsl:for-each select=".//sect1">
							<xsl:variable name="attributes" select="concat('&lt;', string-join(.//sect2[title eq 'Attributes']//row/entry[1]/sgmltag/text() ,'&#xA0;&#xA0;') ,'&gt;')"></xsl:variable>
							<div id="{concat(@xreflabel,'_parents')}">
								<xsl:for-each select="sect2[title eq 'Parent Elements']//xref">
									<xsl:variable name="element" select="//sect1[@id eq current()/@linkend]"/>
									<xsl:variable name="elementname" select="$element/title"/>
									<a class="parent" onclick="parentClick(this,'{concat($element/@xreflabel,'_content')}');"><xsl:value-of select="$elementname"/></a>
									<xsl:if test="position() ne last()"><xsl:text> | </xsl:text></xsl:if>
								</xsl:for-each>
							</div>

							<div id="{concat(@xreflabel,'_content')}">
								<xsl:choose>
									<xsl:when test="sect2[title eq 'Content Model']//(xref|emphasis)">
										<xsl:if test="sect2[title eq 'Content Model']//emphasis">
											<div><xsl:apply-templates select="sect2[title eq 'Content Model']//emphasis/node()"/></div>
										</xsl:if>
										<xsl:variable name="xrefs" select="sect2[title eq 'Content Model']//xref"/>
										<xsl:for-each select="sect2[title eq 'Content Model']//xref">
											<xsl:if test="not(preceding-sibling::xref[@linkend eq current()/@linkend])">
												<xsl:variable name="element" select="//sect1[@id eq current()/@linkend]"/>
												<xsl:variable name="elementname" select="$element/title"/>
												<xsl:variable name="CM">
													<xsl:apply-templates select="$element/sect2[title eq 'Content Model']/para" mode="CM"/>
												</xsl:variable>
												<xsl:variable name="title" select="concat(//sect1[@id eq current()/@linkend]/para,'&#10;',normalize-space($CM))"/>
												<div>
													<a class="unwrap" onclick="elementClick(this,'{concat($element/@xreflabel,'_content')}');" title="{string-join(($attributes, $title), '&#x0A;')}">
														<xsl:value-of select="$elementname"/>
													</a>
													<xsl:text>&#160;</xsl:text>
													<a class="go" href="{concat(@linkend,'.html')}" title="{concat('To &lt;',$elementname,'&gt; page...')}" target="_blank"><img src="link.gif"/></a>
												</div>
											</xsl:if>
										</xsl:for-each>
									</xsl:when>
									<xsl:otherwise>
										<div><xsl:value-of select="sect2[title eq 'Content Model']//para"/></div>
									</xsl:otherwise>
								</xsl:choose>								
							</div>
						</xsl:for-each>
					</div>
		            <div class="tree"> <!-- selecting root elementrs (with no parents) -->
						<xsl:for-each select=".//sect1[sect2[title eq 'Parent Elements'][para[not(node()) or count(*)=1 and sgmltag]]]">
							<xsl:variable name="CM">
								<xsl:apply-templates select="sect2[title eq 'Content Model']/para" mode="CM"/>
							</xsl:variable>
							<xsl:variable name="attributes" select="concat('&lt;', string-join(.//sect2[title eq 'Attributes']//row/entry[1]/sgmltag/text() ,'&#xA0;&#xA0;') ,'&gt;')"></xsl:variable>
							<xsl:variable name="elementname" select="title"/>
							<xsl:variable name="title" select="concat(para,'&#10;',normalize-space($CM))"/>
							<div>
								<a class="unwrap" onclick="elementClick(this,'{concat(@xreflabel,'_content')}');" title="{string-join(($attributes, $title), '&#x0A;')}">
									<xsl:value-of select="$elementname"/>
								</a>
								<xsl:text>&#160;</xsl:text>
								<a class="go" href="{concat(@id,'.html')}" title="{concat('To &lt;',$elementname,'&gt; page...')}" target="_blank"><img src="link.gif"/><!--&#x279C;--></a>
							</div>
						</xsl:for-each>
					</div>
		        </article>
			</body>
		</html>	
	</xsl:result-document>
	
	<xsl:message>&#xA0;&#xA0;<xsl:value-of select="$tree_file"/> - done</xsl:message>	
</xsl:template>	

<xsl:template match="*" mode="CM">
	<xsl:apply-templates select="node()" mode="CM"/>
</xsl:template>	

<xsl:template match="xref" mode="CM">
	<xsl:value-of select="//sect1[@id eq current()/@linkend]/title"/>
</xsl:template>	

<xsl:template match="text()" mode="CM">
	<xsl:value-of select="."/>
</xsl:template>	
<!-- ======================================================= end of element_tree.html =========================================================== -->


<!-- =========================================================== individual pages =============================================================== -->
<xsl:template name="generate_individual_pages">
	<xsl:for-each select="book/chapter/sect1">
		<xsl:variable name="page_name" select="title"/>
		<xsl:variable name="page_file" select="concat(@id,'.html')"/>
		
		<xsl:result-document method="xhtml" href="{$page_file}" encoding="utf8" indent="no">
			<xsl:call-template name="html5-declaration"/>
			<html>
				<head>
					<title><xsl:value-of select="$main_title"/> - <xsl:value-of select="$page_name"/></title>
					<link rel="stylesheet" href="{$html_stylesheet}" type="text/css"/>
				</head>
				<body class="doc">
					<nav class="top">
						<table>
							<tr>
								<td class="nav"><a href="{$index_file}">Index Page</a> | <a href="{concat($tree_file, '?xreflabel=', @xreflabel, '&amp;id=', @id, '&amp;title=', $page_name)}">Element Tree</a></td>
							</tr>
						</table>
					</nav>
					
					<xsl:apply-templates select="."/>
				</body>
			</html>		
		</xsl:result-document>
		<xsl:message>&#xA0;&#xA0;<xsl:value-of select="title"/>.html - done</xsl:message>
	</xsl:for-each>
</xsl:template>	
<!-- ======================================================= end of individual pages ============================================================ -->


<!-- ============================================================= templates ==================================================================== -->
<xsl:template match="para[not(normalize-space(.) or *)]" priority="1"/>

<xsl:template match="para | p">
	<p><xsl:apply-templates/></p>
</xsl:template>

<xsl:template match="i">
	<i><xsl:apply-templates/></i>
</xsl:template>

<xsl:template match="b | emphasis[@role eq 'bold']">
	<b><xsl:apply-templates/></b>
</xsl:template>

<xsl:template match="sect1">
	<section class="sect1" id="root">
		<xsl:apply-templates select="title"/>
		<section class="sect2" id="desc">	
			<xsl:apply-templates select="node() except (title, sect2)"/>
		</section>
		<xsl:apply-templates select="sect2"/>		
	</section>
</xsl:template>

<xsl:template match="sect1/title">
	<h2><xsl:value-of select="."/></h2>
</xsl:template>

<xsl:template match="sect2">
	<xsl:variable name="id">
		<xsl:choose>
			<xsl:when test="title eq 'Usage'">Us</xsl:when>
			<xsl:when test="title eq 'Attributes'">Att</xsl:when>
			<xsl:when test="title eq 'Content Model'">CM</xsl:when>
			<xsl:when test="title eq 'Parent Elements'">PE</xsl:when>
		</xsl:choose>		
	</xsl:variable>
	
	<section class="sect2" id="{$id}">
		<xsl:apply-templates/>
	</section>
</xsl:template>

<xsl:template match="sect2/title">
	<h3><xsl:apply-templates select="node()"/></h3>
</xsl:template>

<xsl:template match="informaltable[@role eq 'att-table']">
	<div class="informaltable">
		<table><xsl:apply-templates/></table>
	</div>
</xsl:template>

<xsl:template match="informaltable[@role eq 'att-table']//row/entry[1]/sgmltag">
	<a class="xref" href="{concat($attributes_file, '#', .)}"><xsl:apply-templates/></a>
</xsl:template>

<xsl:template match="informaltable[@frame=('topbot','all')]">
	<div class="informaltable">
		<table><xsl:apply-templates/></table>
	</div>
</xsl:template>

<xsl:template match="tgroup">
	<xsl:apply-templates/>
</xsl:template>

<xsl:template match="colspec"/>

<xsl:template match="tbody">
	<tbody><xsl:apply-templates/></tbody>
</xsl:template>

<xsl:template match="thead">
	<thead><xsl:apply-templates/></thead>
</xsl:template>

<xsl:template match="row">
	<tr><xsl:apply-templates/></tr>
</xsl:template>

<xsl:template match="entry">
	<xsl:element name="{if (ancestor::thead) then 'th' else 'td'}">
		<xsl:copy-of select="@*"/>
		<xsl:apply-templates/>
	</xsl:element>
</xsl:template>

<xsl:template match="informaltable[@role eq 'att-table']//entry[preceding-sibling::entry[1][sgmltag[text() = 'class']] and following-sibling::entry[1][emphasis[text() = 'mandatory']]]">
	<td><xsl:value-of select="substring-before(ancestor::sect1/title,'.')"/></td>		
</xsl:template>

<xsl:template match="informaltable[@role eq 'att-table']//entry[link[not(@role eq 'elem-link')]]">
	<xsl:element name="{if (ancestor::thead) then 'th' else 'td'}">
		<xsl:apply-templates select="link"/>
	</xsl:element>
</xsl:template>

<xsl:template match="emphasis">
	<span class="emphasis"><em><xsl:apply-templates/></em></span>
</xsl:template>

<xsl:template match="xref">
	<a class="xref" href="{concat(@linkend,'.html')}" title="{if (contains(@linkend,'wng_')) then substring-after(@linkend,'wng_') else if (contains(@linkend,'_')) then translate(@linkend,'_',':') else @linkend}">
		<xsl:value-of select="//sect1[@id eq current()/@linkend]/title"/>
	</a>
</xsl:template>

<xsl:template match="sgmltag">
	<code class="sgmltag-element"><xsl:apply-templates/></code>
</xsl:template>

<!-- ========================================================== end of templates ================================================================ -->

</xsl:stylesheet>