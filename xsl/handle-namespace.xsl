<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet 
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:xs="http://www.w3.org/2001/XMLSchema"
  exclude-result-prefixes="xs"
  version="2.0">
  
  <xsl:template name="handle-namespace">
    <!-- experimental code from http://eccnet.eccnet.com/pipermail/schematron-love-in/2006-June/000104.html -->
    <!-- Handle namespaces differently for exslt systems,   and default, only using XSLT1 syntax -->
    <!-- For more info see  http://fgeorges.blogspot.com/2007/01/creating-namespace-nodes-in-xslt-10.html -->
    <xsl:choose>
      <!-- The following code workds for XSLT2 -->
      <xsl:when test="element-available('xsl:namespace')">
        <xsl:namespace name="{@prefix}" select="@uri" />
      </xsl:when>
      
      <xsl:when use-when="not(element-available('xsl:namespace'))" 
        test="function-available('exsl:node-set')">
        <xsl:variable name="ns-dummy-elements">
          <xsl:element name="{@prefix}:dummy" namespace="{@uri}"/>
        </xsl:variable>
        <xsl:variable name="p" select="@prefix"/>
        <xsl:copy-of select="exsl:node-set($ns-dummy-elements)
          /*/namespace::*[local-name()=$p]"/>
      </xsl:when>      
      <!-- end XSLT2 code -->      
      
      <xsl:when test="@prefix = 'xsl' ">
        <!-- Do not generate dummy attributes with the xsl: prefix, as these
                are errors against XSLT, because we presume that the output
                stylesheet uses the xsl prefix. In any case, there would already
                be a namespace declaration for the XSLT namespace generated
                automatically, presumably using "xsl:".
           -->
      </xsl:when>
      <xsl:when test="@uri = 'http://www.w3.org/1999/XSL/Transform'">
        <xsl:message terminate="yes" select="'The XSL namespace is reserved and it is not permitted to use it in the configuration file.', system-property('xsl:vendor')"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:attribute name="{concat(@prefix,':dummy-for-xmlns')}" namespace="{@uri}" />
      </xsl:otherwise>
    </xsl:choose>
    
  </xsl:template>
  
</xsl:stylesheet>