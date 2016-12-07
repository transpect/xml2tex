<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:xs="http://www.w3.org/2001/XMLSchema"
  xmlns:dbk="http://docbook.org/ns/docbook"
  xmlns:tr="http://transpect.io"
  version="2.0" 
  exclude-result-prefixes="xs dbk tr">
 
  
  <xsl:template match="@*|*|processing-instruction()">
    <xsl:copy>
      <xsl:apply-templates select="@*|node()"/>
    </xsl:copy>
  </xsl:template>

  <xsl:template match="*:footnote[parent::*[1][self::*:title]]" >
    <footnoteref>
      <xsl:attribute name="xml:refid">
	<xsl:value-of select="./@xml:id"/>
      </xsl:attribute>
      <xsl:attribute name="label">
	<xsl:value-of select="./@label"/>
      </xsl:attribute>
    </footnoteref>
  </xsl:template>
  
  <xsl:template match="*:para[preceding-sibling::*[1][self::*:title[child::*:footnote]]]">
    <xsl:copy>
      <footnotetext>
	<xsl:attribute name="xml:id">
	  <xsl:value-of select="preceding-sibling::*[1][self::*:title[child::*:footnote]]/*:footnote/@xml:id"/>
	</xsl:attribute>
	<xsl:attribute name="label">
	  <xsl:value-of select="preceding-sibling::*[1][self::*:title[child::*:footnote]]/*:footnote/@label"/>
	</xsl:attribute>
	<xsl:copy-of select="preceding-sibling::*[1][self::*:title[child::*:footnote]]/*:footnote/*:para" />
      </footnotetext>
      <xsl:apply-templates select="@*" />
      <xsl:apply-templates select="node()" />
    </xsl:copy>
  </xsl:template>
     
</xsl:stylesheet>
