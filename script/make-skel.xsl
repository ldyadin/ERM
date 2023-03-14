<?xml version="1.0" encoding="UTF-8"?>

<!--Creates sectional structure, attributes table, converts Content model and parent Elements to readable form-->

<xsl:stylesheet version="2.0" 
				xmlns:aux="http://www.wiley.com/namespaces/wiley/aux"
				xmlns:sch="http://purl.oclc.org/dsdl/schematron"
				xmlns:xlink="http://www.w3.org/1999/xlink/" 
				xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
				xmlns:xrv="http://ct.wiley.com/xrv"
				exclude-result-prefixes="#all">

<xsl:output method="xml" encoding="utf-8" indent="no"/>
	
<xsl:variable name="main-prefix" select="'wng:'"/>

<!-- structure for looking-up element ancestry -->
<xsl:variable name="ancestry">
	<xsl:for-each select="//model-item">
		<element name="{name[1]}">
			<xsl:variable name="cm" select="content-model/text() | content-model/*[not(descendant-or-self::attribute)]//text()"/>
			<xsl:for-each select="$cm[normalize-space(.)]">
				<xsl:for-each select="tokenize(.,'\s+')[normalize-space(.)]">
					<child><xsl:value-of select="normalize-space(.)"/></child>
				</xsl:for-each>
			</xsl:for-each>
		</element>
	</xsl:for-each>
</xsl:variable>


<!-- root template -->
<xsl:template match="/">
	<book>
		<chapter>
			<xsl:attribute name="source" select="/elements/@source"/>
			<xsl:for-each select="//model-item">
				<xsl:sort select="lower-case(if (contains(name[1],':')) then (if (starts-with(name[1], $main-prefix)) then substring-after(name[1],':') else concat('zzz',name[1])) else name[1])"/>
				<xsl:variable name="ename" select="name[1]"/>
				<xsl:variable name="ename-translated" select="translate($ename,':','_')"/>				
				<xsl:variable name="ename-unprefixed" select="if (contains($ename,':')) then substring-after($ename,':') else $ename"/>				
				<xsl:variable name="title" select="if (starts-with($ename, $main-prefix)) then substring-after($ename,':') else $ename"/>

				<sect1 id="{$ename-translated}" xreflabel="{$ename-unprefixed}">
					<title><xsl:value-of select="$title"/></title>
					<para><xsl:copy-of select="desc/node()"/></para>
					<xsl:apply-templates select="."/>
				</sect1>
			</xsl:for-each>
		</chapter>
	</book>
</xsl:template>

<xsl:template match="@*|*|processing-instruction()|comment()" mode="merge">
	<xsl:copy copy-namespaces="no">
		<xsl:apply-templates select="*|@*|text()|processing-instruction()|comment()"  mode="merge"/>
	</xsl:copy>
</xsl:template>


<xsl:template match="model-item">
	<xsl:variable name="ename" select="name[1]"/>
	<xsl:variable name="ename-unprefixed" select="if (contains($ename,':')) then substring-after($ename,':') else $ename"/>
	
	<sect2 id="{concat(translate($ename,':','_'),'_attributes')}">
		<title>Attributes</title>
		<xsl:variable name="atts-to-reveal" select=".//attribute[not(@name eq 'role') and not(desc eq '!suppress!')]"/>
		<xsl:choose>
			<xsl:when test="$atts-to-reveal">
				<xsl:call-template name="do-attributes">
					<xsl:with-param name="att-nodes" select="$atts-to-reveal"/>
					<xsl:with-param name="ename-unprefixed" select="$ename-unprefixed"/>
				</xsl:call-template>
			</xsl:when>
			<xsl:when test="$ename eq 'math'">
				<para>[Please refer to MathML documentation]</para>
			</xsl:when>			
			<xsl:otherwise>
				<para>[This element has no attributes declared]</para>
			</xsl:otherwise>
		</xsl:choose>
	</sect2>
	
	<sect2 role="content-model" id="{concat(translate($ename,':','_'),'_content_model')}">
		<title>Content Model</title>
		<xsl:variable name="cm">
			<xsl:apply-templates select="(content-model/*[not(descendant-or-self::attribute)]) | (content-model/text())"/>
		</xsl:variable>
		<para>
			<xsl:choose>
				<xsl:when test="$cm//xref or string-length(normalize-space($cm)) &gt; 0">
					<!-- <xsl:copy-of select="$cm"/> -->
					<xsl:for-each select="$cm/node()"> <!-- LD: A workaround to remove last ', ' -->
						<xsl:choose>
							<xsl:when test="position()=last() and self::text() and ends-with(.,', ')">
								<xsl:value-of select="replace(.,'(, )$','')"/>
							</xsl:when>
							<xsl:otherwise><xsl:copy-of select="."/></xsl:otherwise>
						</xsl:choose>
					</xsl:for-each>
				</xsl:when>
				<xsl:otherwise>
					<xsl:text>[This element must be empty]</xsl:text>
				</xsl:otherwise>
			</xsl:choose>
		</para>
	</sect2>
	
	<sect2 role="parent-elements" id="{concat(translate($ename,':','_'),'_parent_elements')}">
		<title>Parent Elements</title>
		<xsl:if test="not($ancestry//element[child=$ename])">
			<xsl:message>  Processing root element: <xsl:value-of select="$ename"/></xsl:message>
		</xsl:if>
		<xsl:variable name="unsorted-parents">
			<xsl:for-each select="$ancestry//element[child=$ename]">
				<xsl:call-template name="do-element">
					<xsl:with-param name="name" select="@name"/>
				</xsl:call-template>
				<xsl:text/>
			</xsl:for-each>
		</xsl:variable>
		<para>
			<xsl:for-each select="$unsorted-parents/xref">
				<xsl:sort select="lower-case(.)"/>
				<xsl:copy-of select="."/>
				<xsl:text>&#160; &#160;</xsl:text>
			</xsl:for-each>
		</para>
	</sect2>
</xsl:template>


<xsl:template name="do-attributes">
	<xsl:param name="att-nodes"/>
	<xsl:param name="ename-unprefixed"/>
	<informaltable frame="none" role="att-table">
		<tgroup cols="4">
			<colspec colwidth="3*"/>
			<colspec colwidth="2*"/>
			<colspec colwidth="3*"/>
			<colspec colwidth="5*"/>
			<tbody>
				<xsl:for-each select="$att-nodes">
					<xsl:sort select="lower-case(@name)"/>
					<xsl:call-template name="do-single-attribute">
						<xsl:with-param name="ename-unprefixed" select="$ename-unprefixed"/>
						<xsl:with-param name="att-node" select="."/>
					</xsl:call-template>
				</xsl:for-each>
			</tbody>
		</tgroup>
	</informaltable>
</xsl:template>


<xsl:template name="do-single-attribute">
	<xsl:param name="ename-unprefixed"/>
	<xsl:param name="att-node"/>
	<xsl:for-each select="$att-node">
		<!-- shift the context -->
		<xsl:variable name="attname" select="@name"/>
		<row>
			<entry>
				<sgmltag><xsl:value-of select="$attname"/></sgmltag>
			</entry>
			<entry>
				<xsl:choose>
					<xsl:when test="not(choice)"><xsl:value-of select="@type"/></xsl:when>
					<xsl:otherwise><xsl:value-of select="choice"/></xsl:otherwise>
				</xsl:choose>
			</entry>
			<entry>
				<xsl:choose>
					<xsl:when test="not(../../optional)"><emphasis>mandatory</emphasis></xsl:when>
					<xsl:otherwise>optional</xsl:otherwise>
				</xsl:choose>
			</entry>
			<entry><xsl:copy-of select="desc/node()"/></entry>
		</row>
	</xsl:for-each>
</xsl:template>


<!-- element content models -->
<xsl:template match="optional | zeroOrMore | choice | oneOrMore | group">
	<xsl:if test="self::choice or self::group"><xsl:text>(</xsl:text></xsl:if>
	<xsl:apply-templates/>
	<xsl:if test="self::choice or self::group"><xsl:text>)</xsl:text></xsl:if>
	
	<xsl:choose>
		<xsl:when test="self::optional"><xsl:text>?</xsl:text></xsl:when>
		<xsl:when test="self::zeroOrMore"><xsl:text>*</xsl:text></xsl:when>
		<xsl:when test="self::oneOrMore"><xsl:text>+</xsl:text></xsl:when>
		<xsl:otherwise/>
	</xsl:choose>
	
	<xsl:if test="following-sibling::* or normalize-space(following-sibling::text())">
		<xsl:choose>
			<xsl:when test="parent::choice"><xsl:text> | </xsl:text></xsl:when>
			<xsl:otherwise><xsl:text>, </xsl:text></xsl:otherwise>
		</xsl:choose>
	</xsl:if>
</xsl:template>

<xsl:template match="text">
	<emphasis>text</emphasis>
</xsl:template>

<!-- SPECIAL : handles mixed content models nicely -->
<xsl:template match="zeroOrMore[choice//text]">
	<xsl:text>( </xsl:text>
	<emphasis>text</emphasis>
	<xsl:variable name="elements" select="."/>
	<xsl:for-each select="tokenize(string(.),'\s+')[normalize-space(.)]">
		<xsl:sort select="lower-case(.)"/>
		<xsl:text> | </xsl:text>
		<xsl:call-template name="do-element">
			<xsl:with-param name="name" select="."/>
		</xsl:call-template>
	</xsl:for-each>
	<xsl:text> )*</xsl:text>
</xsl:template>

<!-- we've arrived at elements -->
<xsl:template match="text()">
	<xsl:variable name="this" select="."/>
	<xsl:variable name="elements" select="normalize-space(.)"/>
	<xsl:variable name="in-choice" select="parent::choice"/>
	<xsl:for-each select="tokenize(string(.),'\s+')[normalize-space(.)]">
		<xsl:call-template name="do-element">
			<xsl:with-param name="name" select="."/>
		</xsl:call-template>
		<xsl:if test="position()!=last() or $this/following-sibling::*">
			<xsl:choose>
				<xsl:when test="$in-choice"><xsl:text> | </xsl:text></xsl:when>
				<xsl:otherwise><xsl:text>, </xsl:text></xsl:otherwise>
			</xsl:choose>
		</xsl:if>
	</xsl:for-each>
</xsl:template>

<!-- links element -->
<xsl:template name="do-element">
	<xsl:param name="name" select="normalize-space(name)"/>
	<xsl:variable name="ename-unprefixed" select="if (contains($name,':')) then substring-after($name,':') else $name"/>
	<xsl:choose>
		<xsl:when test="contains($name,':')">
			<xref role="elem-link" linkend="{translate(normalize-space($name),':','_')}"/>
		</xsl:when>
		<xsl:otherwise>
			<xref role="elem-link" linkend="{normalize-space($name)}"/>
		</xsl:otherwise>
	</xsl:choose>
</xsl:template>

</xsl:stylesheet>
