<?xml version="1.0" encoding="utf-8"?>

<xsl:stylesheet version="2.0"
				xmlns:rng="http://relaxng.org/ns/structure/1.0"
				xmlns:a="http://relaxng.org/ns/compatibility/annotations/1.0"
				xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
				xmlns:xlink="http://www.w3.org/1999/xlink"
				xmlns:xsl="http://www.w3.org/1999/XSL/Transform"	
				exclude-result-prefixes="#all">

    <xsl:output method="xml" indent="yes" encoding="utf-8"/>

    <xsl:param name="urlbase">../schema/rng/</xsl:param>
    <xsl:param name="file_name"/>

    <!-- collect all definitions in the schema -->
    <xsl:variable name="defines">
        <all-defines>
            <xsl:choose>
                <xsl:when test="//file">
                    <xsl:for-each select="//file">
                        <xsl:variable name="rng-url" select="concat($urlbase, replace(@src, '.xsd', '.rng'))"/>
                        <xsl:variable name="rng" select="if (doc-available($rng-url)) then document($rng-url) else ()"/>
                        <xsl:if test="$rng">
                            <xsl:copy-of select="$rng//rng:define"/>
                        </xsl:if>
                    </xsl:for-each>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:copy-of select=".//rng:define"/>
                </xsl:otherwise>
            </xsl:choose>   
        </all-defines>
    </xsl:variable>
    
    
    <!-- root template -->
    <xsl:template match="/">
        <!--<xsl:message>=<xsl:copy-of select="$defines"/>=</xsl:message>-->
        <elements>
            <xsl:attribute name="source" select="$file_name"/>
            <xsl:choose>
                <xsl:when test="//file">
                    <xsl:for-each select="//file">
                        <xsl:variable name="src" select="replace(@src, '.xsd', '.rng')"/>
                        <xsl:variable name="rng-url" select="concat($urlbase, $src)"/>
                        <xsl:variable name="rng" select="if (doc-available($rng-url)) then document($rng-url) else ()"/>
                        <xsl:choose>
                            <xsl:when test="$rng"> 
                                <xsl:message>  Processing <xsl:value-of select="$src"/></xsl:message>                         	
                                <xsl:call-template name="process-file">
                                    <xsl:with-param name="rng" select="$rng"/>
                                </xsl:call-template>
                            </xsl:when>
                            <xsl:otherwise>
                                <xsl:message>  File <xsl:value-of select="$rng-url"/> wasn't found</xsl:message>
                            </xsl:otherwise>
                        </xsl:choose>
                    </xsl:for-each>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:call-template name="process-file">
                        <xsl:with-param name="rng" select="."/>
                    </xsl:call-template>
                </xsl:otherwise>
            </xsl:choose>            
        </elements>
    </xsl:template>


    <xsl:template name="process-file">
        <xsl:param name="rng"/>
        <xsl:for-each select="$rng//rng:element">
            <model-item>
                <name><xsl:value-of select="@name"/></name>
                <xsl:if test="a:documentation">
                    <desc><xsl:copy-of select="a:documentation/text()"/></desc>
                </xsl:if>
                <content-model><xsl:apply-templates/></content-model>
            </model-item>
        </xsl:for-each>
    </xsl:template>
    
    
    <!-- suppress annotations -->
    <xsl:template match="a:documentation">
        <desc><xsl:copy-of select="text()"/></desc>
    </xsl:template>
    
    
    <!-- clean up spurious ws -->
    <xsl:template match="text()"/>
    
    
    <!-- all refs must be recursively processed -->
    <xsl:template match="rng:ref">
        <xsl:variable name="rname" select="@name"/>
        <xsl:variable name="def" select="$defines//rng:define[@name eq $rname]"/>
        <xsl:apply-templates select="$def/*"/>
    </xsl:template>
    
    
    <!-- attributes -->
    <xsl:template match="rng:attribute">
        <attribute name="{@name}">
    		<xsl:if test="rng:data/@type">
    		    <xsl:attribute name="type" select="rng:data/@type"/>
    		</xsl:if>
            <xsl:if test="@a:defaultValue">
                <desc><xsl:value-of select="@a:defaultValue"/></desc>
            </xsl:if>
            <xsl:apply-templates/>
        </attribute>
    </xsl:template>
    
    
    <!-- elements -->
    <xsl:template match="rng:element">
        <xsl:value-of select="@name"/>
        <xsl:text> </xsl:text>
    </xsl:template>
    
    
    <!-- enumerated choices (for attributes) -->
    <xsl:template match="rng:choice[rng:value]">
        <choice>
            <xsl:value-of select="normalize-space(.)"/>
        </choice>
    </xsl:template>
    
    
    <!-- single values (for attributes) -->
    <xsl:template match="rng:attribute/rng:value">
        <choice>
            <xsl:value-of select="normalize-space(.)"/>
        </choice>
    </xsl:template>
    
    <!-- text gets its own element -->
    <xsl:template match="rng:text">
        <text/>
    </xsl:template>
    
    <!-- namespace strip RNG to ease processsing -->
    <xsl:template match="rng:oneOrMore | rng:zeroOrMore | rng:optional | rng:choice | rng:group">
    	<xsl:element name="{local-name(.)}">
    		<xsl:apply-templates/>
    	</xsl:element>
    </xsl:template>
    
    
    <!-- LD: to remove warning in XSLT 2.0 processor (template in no namespace) -->
    <xsl:template match="abrakadabra"/>

</xsl:stylesheet>
