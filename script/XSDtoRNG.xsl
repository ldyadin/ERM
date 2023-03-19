<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="2.0"
				xmlns:xsl="http://www.w3.org/1999/XSL/Transform" 
				xmlns:xs="http://www.w3.org/2001/XMLSchema" 
				xmlns:rng="http://relaxng.org/ns/structure/1.0" 
				xmlns:a="http://relaxng.org/ns/compatibility/annotations/1.0" 
				xpath-default-namespace="http://www.w3.org/2001/XMLSchema"
				exclude-result-prefixes="xs">

	<xsl:output indent="yes" method="xml"/>
	<xsl:preserve-space elements="*"/>

	<!--choice for batch or individual file processing-->
	<xsl:template match="/">
		<xsl:choose>
			<xsl:when test="//file">
				<xsl:for-each select="//file">
					<xsl:variable name="src" select="@src"/>
					<xsl:variable name="xsd-url" select="concat('../schema/xsd/', $src)"/>
					<xsl:variable name="xsd" select="if (doc-available($xsd-url)) then document($xsd-url) else ()"/>
					<xsl:choose>
						<xsl:when test="$xsd">
							<xsl:message>  Processing
								<xsl:value-of select="$src"/>
							</xsl:message>
							<xsl:variable name="rng-url" select="concat('schema/rng/', replace($src, '.xsd', '.rng'))"/>
							<xsl:result-document href="{$rng-url}" method="xml" indent="yes" encoding="utf-8">
								<xsl:apply-templates select="$xsd/xs:schema"/>
							</xsl:result-document>
						</xsl:when>
						<xsl:otherwise>
							<xsl:message>  File	<xsl:value-of select="$xsd-url"/> wasn't found</xsl:message>
						</xsl:otherwise>
					</xsl:choose>
				</xsl:for-each>
			</xsl:when>
			<xsl:otherwise>
				<xsl:apply-templates select="/xs:schema"/>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>

	<xsl:template match="/xs:schema">
		<rng:grammar>
			<xsl:for-each select="namespace::*">
				<xsl:if test="local-name() != 'xs'">
					<xsl:copy/>
				</xsl:if>
			</xsl:for-each>
			<xsl:if test="@targetNamespace">
				<xsl:attribute name="ns">
					<xsl:value-of select="@targetNamespace"/>
				</xsl:attribute>
			</xsl:if>
			<xsl:attribute name="datatypeLibrary">http://www.w3.org/2001/XMLSchema-datatypes</xsl:attribute>
			<xsl:apply-templates/>
		</rng:grammar>
	</xsl:template>

	<!-- in order to manage occurrences (and default) attributes goes there before going to mode="content" templates -->
	<xsl:template match="xs:*">
		<xsl:call-template name="occurrences"/>
	</xsl:template>

	<xsl:template match="comment()">
		<xsl:copy/>
	</xsl:template>

	<xsl:template match="xs:import | xs:include | xs:redefine">
		<rng:include>
			<xsl:if test="@schemaLocation">
				<xsl:attribute name="href">
					<xsl:value-of select="concat(substring-before(@schemaLocation, '.xsd'),'.rng')"/>
				</xsl:attribute>
			</xsl:if>
			<xsl:if test="@namespace">
				<xsl:attribute name="ns">
					<xsl:value-of select="@namespace"/>
				</xsl:attribute>
			</xsl:if>
			<xsl:apply-templates/>
		</rng:include>
	</xsl:template>

	<xsl:template match="@default">
		<a:documentation>default value is: <xsl:value-of select="."/></a:documentation>
	</xsl:template>

	<!-- unique and key are not supported in RelaxNG, must be done in schematron -->
	<xsl:template match="xs:unique | xs:key"/>

	<xsl:template match="xs:annotation">
		<a:documentation>
			<xsl:apply-templates/>
		</a:documentation>
	</xsl:template>

	<xsl:template match="xs:documentation">
		<xsl:copy-of select="child::node()"/>
	</xsl:template>

	<xsl:template match="xs:appinfo">
		<xsl:copy-of select="child::node()"/>
	</xsl:template>

	<xsl:template match="xs:union"> <!--no-->
		<rng:choice>
			<xsl:apply-templates select="@memberTypes"/>
			<xsl:apply-templates/>
		</rng:choice>
	</xsl:template>

	<xsl:template match="@memberTypes"> <!--no-->
		<xsl:call-template name="declareMemberTypes">
			<xsl:with-param name="memberTypes" select="."/>
		</xsl:call-template>
	</xsl:template>

	<xsl:template match="xs:list"> <!--no-->
		<rng:list>
			<xsl:apply-templates select="@itemType"/>
			<xsl:apply-templates/>
		</rng:list>
	</xsl:template>

	<xsl:template match="@itemType"> <!--no-->
		<xsl:call-template name="type">
			<xsl:with-param name="type" select="."/>
		</xsl:call-template>
	</xsl:template>

	<xsl:template match="xs:group[@name] | xs:attributeGroup[@name]">
		<rng:define name="{@name}">
			<xsl:apply-templates/>
		</rng:define>
	</xsl:template>

	<xsl:template match="xs:complexType[@name]">
		<rng:define name="{@name}">
			<xsl:if test="@mixed eq 'true'  and (xs:element or xs:attribute)"> <!--LD--><xsl:message>=<xsl:value-of select="@name"/>=</xsl:message>
				<rng:text/>
			</xsl:if>		
			<xsl:apply-templates/>
		</rng:define>
	</xsl:template>

	<xsl:template match="xs:simpleType[@name]">
		<rng:define name="{@name}">
			<rng:text/>  <!--LD-->		
			<xsl:apply-templates/>
		</rng:define>
	</xsl:template>

	<!-- when finds a ref attribute replace it by its type call (ref name="" or type) -->
	<xsl:template match="xs:*[@ref]" mode="content">
		<xsl:call-template name="type">
			<xsl:with-param name="type" select="@ref"/>
		</xsl:call-template>
	</xsl:template>

	<!-- the <xs:simpleType> and <xs:complexType without name attribute are ignored -->
	<xsl:template match="xs:complexType | xs:simpleType | xs:complexContent">
		<xsl:apply-templates/>
	</xsl:template>

	<xsl:template match="xs:simpleContent">
		<xsl:if test="parent::xs:complexType"> <!--LD-->
			<rng:text/>
		</xsl:if>
		<xsl:apply-templates/>
	</xsl:template>

	<xsl:template match="xs:sequence">		
		<xsl:if test="parent::xs:complexType[@mixed eq 'true'] and xs:element"> <!--LD-->
			<rng:text/>
		</xsl:if>
		<xsl:apply-templates/>
	</xsl:template>

	<xsl:template match="xs:extension[@base]">
		<xsl:call-template name="type">
			<xsl:with-param name="type" select="@base"/>
		</xsl:call-template>
	</xsl:template>

	<xsl:template match="xs:element[@name]">
		<xsl:choose>
			<!-- case of element defined at root of schema, must be surrounded by rng:define with a rng:start reference if is the root element -->
			<xsl:when test="parent::xs:schema">
				<rng:define name="{@name}">
					<xsl:apply-templates select="current()" mode="content"/>
				</rng:define>
			</xsl:when>
			<xsl:otherwise>
				<xsl:call-template name="occurrences"/>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>

	<xsl:template match="xs:restriction[@base]">
		<xsl:choose>
			<xsl:when test="xs:enumeration[@value]">
				<rng:choice>
					<xsl:apply-templates/>
				</rng:choice>
			</xsl:when>
			<xsl:otherwise>
				<xsl:call-template name="type">
					<xsl:with-param name="type" select="@base"/>
				</xsl:call-template>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>

	<xsl:template match="xs:enumeration[@value]">
		<rng:value>
			<xsl:value-of select="@value"/>
		</rng:value>
		<xsl:apply-templates/>
	</xsl:template>

	<!-- support for fractionDigits, length, maxExclusive, maxInclusive, maxLength, minExclusive, minInclusive, minLength, pattern, totalDigits, whiteSpace
	param is only allowed inside data element explicit removal of enumeration as not all the XSLT processor respect templates priority -->
	<xsl:template match="xs:*[not(self::xs:enumeration)][@value]" mode="data">
		<rng:param name="{local-name()}">
			<xsl:value-of select="@value"/>
		</rng:param>
	</xsl:template>

	<xsl:template match="node()" mode="data"/>

	<xsl:template match="xs:all">
		<rng:interleave>
			<xsl:for-each select="child::text()[normalize-space(.) != ''] | child::*">
				<xsl:apply-templates select="current()"/>
			</xsl:for-each>
		</rng:interleave>
	</xsl:template>
	

	<xsl:template match="xs:attribute">
		<xsl:choose>
			<!-- attributes specified at schema level -->
			<xsl:when test="parent::xs:schema">
				<rng:define name="{@name}">
					<xsl:apply-templates select="current()" mode="content"/>
				</rng:define>
			</xsl:when>
			<xsl:otherwise>
				<xsl:apply-templates select="current()" mode="occurrences"/>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template> 

	<xsl:template match="xs:attribute" mode="occurrences">
		<xsl:choose>
			<xsl:when test="@use and @use='prohibited'"/>
			<xsl:when test="@use and @use='required'">
				<xsl:apply-templates select="current()" mode="content"/>
			</xsl:when>
			<!-- by default, attributes are optional -->
			<xsl:otherwise>
				<rng:optional>
					<xsl:apply-templates select="current()" mode="content"/>
				</rng:optional>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>

	<xsl:template match="xs:attribute[@name]" mode="content">
		<rng:attribute name="{@name}">
			<xsl:apply-templates select="@default" mode="attributeDefaultValue"/>
			<!-- there can be no type attribute to <xs:attribute>, in this case, the type is defined in 
                                    a <xs:simpleType> or a <xs:complexType> inside -->
			<xsl:choose>
				<xsl:when test="@type">
					<xsl:call-template name="type">
						<xsl:with-param name="type" select="@type"/>
					</xsl:call-template>
				</xsl:when>
				<xsl:otherwise>
					<xsl:apply-templates/>
				</xsl:otherwise>
			</xsl:choose>
		</rng:attribute>
	</xsl:template>
	<xsl:template match="@default" mode="attributeDefaultValue">
		<xsl:attribute name="defaultValue" namespace="http://relaxng.org/ns/compatibility/annotations/1.0">
			<xsl:value-of select="."/>
		</xsl:attribute>
	</xsl:template>
	<xsl:template match="xs:any" mode="content">
		<rng:element>
			<rng:anyName/>
			<rng:text/>
		</rng:element>
	</xsl:template>
	<xsl:template match="xs:anyAttribute" mode="content">
		<rng:attribute>
			<rng:anyName/>
			<rng:text/>
		</rng:attribute>
	</xsl:template>
	<xsl:template match="xs:choice" mode="content">
		<rng:choice>
			<xsl:if test="parent::xs:complexType[@mixed='true'] or //xs:group[@ref eq current()/parent::xs:group/@name]/parent::xs:complexType[@mixed='true']"> <!--LD-->
				<rng:text/>
			</xsl:if>
			<xsl:apply-templates/>
		</rng:choice>
	</xsl:template>
	<xsl:template match="xs:element" mode="content">
		<rng:element name="{@name}">
			<xsl:choose>
				<xsl:when test="@type">
					<xsl:call-template name="type">
						<xsl:with-param name="type" select="@type"/>
					</xsl:call-template>
				</xsl:when>
				<!-- work-around for empty issue -->
				<xsl:when test="not(*[local-name() != 'annotation']) and not(@type)">
					<rng:empty/>
					<xsl:apply-templates/>
				</xsl:when>
				<!-- An empty xsd:complexType with @mixed='true' is equivalent to text -->
				<xsl:when test="not(@type) and *[local-name() = 'complexType' and @mixed = 'true' and not(*)]">
					<xsl:apply-templates/>
					<!-- Allow text but no elements -->
					<rng:text/>
				</xsl:when>
				<xsl:otherwise>
					<xsl:apply-templates/>
				</xsl:otherwise>
			</xsl:choose>
		</rng:element>
	</xsl:template>
	<xsl:template name="occurrences">
		<xsl:apply-templates select="@default"/>
		<xsl:choose>
			<xsl:when test="@maxOccurs and @maxOccurs='unbounded'">
				<xsl:choose>
					<xsl:when test="@minOccurs and @minOccurs='0'">
						<rng:zeroOrMore>
							<xsl:apply-templates select="current()" mode="content"/>
						</rng:zeroOrMore>
					</xsl:when>
					<xsl:otherwise>
						<rng:oneOrMore>
							<xsl:apply-templates select="current()" mode="content"/>
						</rng:oneOrMore>
					</xsl:otherwise>
				</xsl:choose>
			</xsl:when>
			<xsl:when test="@minOccurs and @minOccurs='0'">
				<rng:optional>
					<xsl:apply-templates select="current()" mode="content"/>
				</rng:optional>
			</xsl:when>
			<!-- here minOccurs is present but not = 0 -->
			<xsl:when test="@minOccurs">
				<xsl:call-template name="loopUntilZero">
					<xsl:with-param name="nbLoops" select="@minOccurs"/>
				</xsl:call-template>
			</xsl:when>
			<xsl:otherwise>
				<xsl:apply-templates select="current()" mode="content"/>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>
	<xsl:template name="loopUntilZero">
		<xsl:param name="nbLoops"/>
		<xsl:if test="$nbLoops > 0">
			<xsl:apply-templates select="current()" mode="content"/>
			<xsl:call-template name="loopUntilZero">
				<xsl:with-param name="nbLoops" select="$nbLoops - 1"/>
			</xsl:call-template>
		</xsl:if>
	</xsl:template>

	<xsl:template name="type">
		<xsl:param name="type"/>
		<xsl:choose>
			<xsl:when test="contains($type, 'anyType')"> <!--no-->
				<rng:data type="string">
					<xsl:apply-templates mode="data"/>
				</rng:data>
				<xsl:apply-templates/>
			</xsl:when>
			<xsl:when test="starts-with($type, 'xs:') or starts-with($type, 'xsd:')">
				<xsl:if test="substring-after($type, ':') = ('string', 'decimal', 'integer', 'date', 'time', 'duration', 'boolean')">
					<rng:text/>
				</xsl:if>
				<rng:data type="{substring-after($type, ':')}">
					<xsl:apply-templates select="*" mode="data"/>
				</rng:data>
				<xsl:apply-templates select="*"/>
			</xsl:when>
			<xsl:when test="starts-with($type, 'xml:')"> <!--no-->
				<xsl:variable name="localName" select="substring-after($type, ':')"/>
				<rng:attribute name="{$localName}" ns="http://www.w3.org/XML/1998/namespace">
					<xsl:choose>
						<xsl:when test="$localName='lang'">
							<rng:data type="language"/>
						</xsl:when>
						<xsl:when test="$localName='space'">
							<rng:choice>
								<rng:value>default</rng:value>
								<rng:value>preserve</rng:value>
							</rng:choice>
						</xsl:when>
						<xsl:otherwise>
							<rng:text/>
						</xsl:otherwise>
					</xsl:choose>
				</rng:attribute>
			</xsl:when>
			<xsl:otherwise>
				<rng:ref name="{$type}"/>
				<xsl:apply-templates/>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>

	<xsl:template name="declareMemberTypes"> <!--no-->
		<xsl:param name="memberTypes"/>
		<xsl:choose>
			<xsl:when test="contains($memberTypes, ' ')">
				<xsl:call-template name="type">
					<xsl:with-param name="type" select="substring-before($memberTypes, ' ')"/>
				</xsl:call-template>
				<xsl:call-template name="declareMemberTypes">
					<xsl:with-param name="memberTypes" select="substring-after($memberTypes, ' ')"/>
				</xsl:call-template>
			</xsl:when>
			<xsl:otherwise>
				<xsl:call-template name="type">
					<xsl:with-param name="type" select="$memberTypes"/>
				</xsl:call-template>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>
</xsl:stylesheet>