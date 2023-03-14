<?xml version="1.0"?>

<!--Removes extra wrapers, namespaces etc.-->

<xsl:stylesheet version="2.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">

	<xsl:output method="xml" encoding="utf-8"/>
	
	<!-- identity behaviour -->
	<xsl:template match="@* | * | processing-instruction() | comment()">
		<xsl:copy>
			<xsl:apply-templates select="* | @* | text() | processing-instruction() | comment()"/>
		</xsl:copy>
	</xsl:template>
	
	<xsl:template match="choice[parent::choice][not(*)]">
		<xsl:choose>
			<xsl:when test="not(preceding-sibling::* or following-sibling::*) or preceding-sibling::choice or following-sibling::choice">
				<xsl:value-of select="."/>
			</xsl:when>
			<xsl:otherwise>
				<xsl:copy-of select="."/>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>
		
	<xsl:template match="optional[not(* or text()[normalize-space(.)])]"/>

</xsl:stylesheet>
