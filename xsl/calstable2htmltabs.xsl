<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:xs="http://www.w3.org/2001/XMLSchema" 
  xmlns:css="http://www.w3.org/1996/css"
  xmlns:xml2tex="http://transpect.io/xml2tex"
  xmlns="http://www.w3.org/1999/xhtml" 
  xpath-default-namespace="http://www.w3.org/1999/xhtml"
  exclude-result-prefixes="css xs xml2tex" 
  version="2.0">

  <!-- this stylesheets converts CALS tables 
       to htmltabs 
  -->
  
  <xsl:import href="http://transpect.io/xslt-util/cals2htmltable/xsl/cals2htmltables.xsl"/>  

  <xsl:param name="table-model" select="'tabularx'" as="xs:string"/>
  <!-- tabularx | tabular -->
  <xsl:param name="table-grid" select="''" as="xs:string"/>
  <xsl:param name="line-separator" select="''" as="xs:string"/>
  <xsl:param name="no-table-grid-att" select="'role'"/>
  <xsl:param name="no-table-grid-style" select="'blind-table'"/>

  <xsl:param name="debug" select="'no'"/>
  <xsl:param name="debug-dir-uri" select="'debug'"/>
  
  <!-- mode variables -->
  
  <xsl:variable name="cals2html-table">
    <xsl:apply-templates select="/" mode="cals2html-table"/>
  </xsl:variable>
  
  <xsl:variable name="html2tabs">
    <xsl:apply-templates select="$cals2html-table" mode="html2tabs"/>
  </xsl:variable>
  
  <xsl:template name="main">
    <xsl:sequence select="$html2tabs"/>
    <xsl:if test="$debug eq 'yes'">
      <xsl:result-document indent="yes" method="xml" 
                           href="{$debug-dir-uri}/cals2htmltabs/03_cals2htmltable.xml">
        <xsl:sequence select="$cals2html-table"/>
      </xsl:result-document>
      <xsl:result-document indent="yes" method="xml" 
                           href="{$debug-dir-uri}/cals2htmltabs/05html2tabs.xml">
        <xsl:sequence select="$cals2html-table"/>
      </xsl:result-document>
    </xsl:if>
  </xsl:template>
  
  <xsl:template match="@* | node()" mode="html2tabs">
    <xsl:copy>
      <xsl:apply-templates select="@*, node()" mode="#current"/>
    </xsl:copy>
  </xsl:template>

  <xsl:template match="table" mode="html2tabs">
    <xsl:copy>
      <xsl:apply-templates select="@*" mode="#current"/>
      <xsl:processing-instruction name="htmltabs">
        <xsl:text>&#xa;\begin{htmltab}</xsl:text>
        <xsl:value-of select="@class/concat('[class=', . , ']')"/>
        <xsl:text>&#xa;</xsl:text>
      </xsl:processing-instruction>
      <xsl:apply-templates select="*" mode="#current"/>
      <xsl:processing-instruction name="htmltabs" 
                                  select="'&#xa;\end{htmltab}&#xa;'"/>
    </xsl:copy>
  </xsl:template>
  
  <xsl:template match="caption" mode="htmltabs">
    <xsl:processing-instruction name="htmltabs" 
                                select="'\caption{'"/>
    <xsl:apply-templates mode="#current"/>
    <xsl:processing-instruction name="htmltabs" 
                                select="'}&#xa;'"/>
  </xsl:template>
  
  <xsl:template match="tgroup|colgroup" mode="html2tabs">
    <xsl:copy>
      <xsl:apply-templates select="@*, *" mode="#current"/>
    </xsl:copy>
  </xsl:template>
  
  <xsl:template match="col" mode="html2tabs">
    <xsl:copy>
      <xsl:apply-templates select="@*" mode="#current"/>
      <xsl:processing-instruction name="htmltabs" 
                                    select="concat('\HTcol', 
                                                   xml2tex:atts-to-option(@*), 
                                                   '&#xa;')"/>
    </xsl:copy>
  </xsl:template>
  
  <xsl:template match="thead|tbody|tfoot" mode="html2tabs">
    <xsl:copy>
      <xsl:apply-templates select="@*" mode="#current"/>
      <xsl:processing-instruction name="htmltabs" 
                                  select="concat('\begin{', local-name(), '}&#xa;')"/>
      <xsl:apply-templates select="*" mode="#current"/>
      <xsl:processing-instruction name="htmltabs" 
                                  select="concat('\end{', local-name(), '}&#xa;')"/>
    </xsl:copy>
  </xsl:template>
  
  <xsl:template match="tr" mode="html2tabs">
    <xsl:copy>
      <xsl:apply-templates select="@*" mode="#current"/>
      <xsl:processing-instruction name="htmltabs" 
                                  select="concat('\HTtr',
                                                 xml2tex:atts-to-option(@*),
                                                 '{%&#xa;')"/>
      <xsl:apply-templates select="*" mode="#current"/>
      <xsl:processing-instruction name="htmltabs" 
                                  select="'}&#xa;'"/>
    </xsl:copy>
  </xsl:template>
  
  <xsl:template match="td" mode="html2tabs">
    <xsl:copy>
      <xsl:apply-templates select="@*" mode="#current"/>
      <xsl:processing-instruction name="htmltabs" 
                                  select="concat('\HTtd',
                                                 xml2tex:atts-to-option(@*),
                                                 '{')"/>
      <xsl:apply-templates select="node()" mode="#current"/>
      <xsl:processing-instruction name="htmltabs" 
                                  select="'}&#xa;'"/>
    </xsl:copy>
  </xsl:template>
  
  <xsl:function name="xml2tex:atts-to-option" as="xs:string?">
    <xsl:param name="atts" as="attribute()*"/>
    <xsl:if test="$atts">
      <xsl:sequence select="concat('[',
                                  string-join(
                                              (xml2tex:css-atts-to-style-att($atts[namespace-uri() eq 'http://www.w3.org/1996/css']),
                                               $atts[local-name() = ('id', 'class', 'colspan', 'rowspan')]/concat(local-name(), '={', ., '}')),
                                               ','),
                                  ']')"/>
    </xsl:if>
  </xsl:function>
  
  <xsl:function name="xml2tex:css-atts-to-style-att" as="xs:string?">
    <xsl:param name="css-atts" as="attribute()*"/>
    <xsl:sequence select="if(exists($css-atts)) 
                          then concat('style={',
                                      string-join($css-atts/concat(local-name(), ':', .), 
                                                  ';'),
                                      '}')
                          else ()"/>
  </xsl:function>
  
</xsl:stylesheet>