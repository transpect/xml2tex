<?xml version="1.0" encoding="UTF-8"?>
<p:declare-step xmlns:p="http://www.w3.org/ns/xproc"
  xmlns:c="http://www.w3.org/ns/xproc-step"
  xmlns:cx="http://xmlcalabash.com/ns/extensions"
  xmlns:tr="http://transpect.io"
  xmlns:xml2tex="http://transpect.io/xml2tex"
  version="1.0" 
  name="xml2tex-load-config" 
  type="xml2tex:load-config">
  
  <p:input port="source" sequence="true">
    <p:empty/>
  </p:input>
  <p:output port="result"/>
  
  <p:option name="href" select="''"/>
  <p:option name="fail-on-error" select="'no'"/>
  
  <p:import href="http://transpect.io/xproc-util/load/xpl/load.xpl"/>
  <p:import href="http://xmlcalabash.com/extension/steps/library-1.0.xpl"/>
  
  <p:count name="count"/>
  
  <p:choose>
    <p:when test="/c:result eq '0'">
      
      <tr:load>
        <p:with-option name="href" select="$href"/>
        <p:with-option name="fail-on-error" select="'yes'"/>
      </tr:load>
      
    </p:when>
    <p:otherwise>
      
      <p:identity>
        <p:input port="source">
          <p:pipe port="source" step="xml2tex-load-config"/>
        </p:input>
      </p:identity>
      
    </p:otherwise>
  </p:choose>
  
  <p:choose>
    <p:when test="//xml2tex:import">
      
      <p:viewport match="xml2tex:import">
        <p:variable name="resolved-uri" 
                    select="resolve-uri(xml2tex:import/@href, xml2tex:import/base-uri())"/>
        
        <tr:load>
          <p:with-option name="href" select="$resolved-uri"/>
          <p:with-option name="fail-on-error" select="$fail-on-error"/>
        </tr:load>
        
      </p:viewport>
      
      <p:xslt>
        <p:input port="stylesheet">
          <p:inline>
            <xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" 
              xmlns="http://transpect.io/xml2tex"
              version="2.0" 
              exclude-result-prefixes="#all">
              
              <xsl:variable name="imports" select="/xml2tex:set/xml2tex:set" as="element(xml2tex:set)+"/>
              
              <xsl:template match="/xml2tex:set">
                <xsl:copy>
                  <xsl:copy-of select="@*"/>
                  <xsl:for-each select="xml2tex:import, $imports/xml2tex:import">
                    <xsl:copy>
                      <xsl:attribute name="href" select="resolve-uri(@href, base-uri())"/>
                      <xsl:copy-of select="@* except @href, node()"/>
                    </xsl:copy>
                  </xsl:for-each>
                  <xsl:copy-of select="xsl:import, $imports/xsl:import,
                                       (xml2tex:preamble, $imports/xml2tex:preamble)[1],
                                       xml2tex:ns, $imports/xml2tex:ns,
                                       $imports/xml2tex:template,
                                       $imports/xml2tex:regex, 
                                       xml2tex:template, 
                                       xml2tex:regex"/>
                  <charmap>
                    <xsl:copy-of select="xml2tex:charmap/xml2tex:char,
                                         $imports/xml2tex:charmap/xml2tex:char[not(@character = /xml2tex:set/xml2tex:charmap/xml2tex:char/@character)]"/>
                  </charmap>
                </xsl:copy>
              </xsl:template>
              
            </xsl:stylesheet>
          </p:inline>
        </p:input>
        <p:input port="parameters">
          <p:empty/>
        </p:input>
      </p:xslt>
      
      <xml2tex:load-config>
        <p:with-option name="fail-on-error" select="$fail-on-error"/>
      </xml2tex:load-config>
      
    </p:when>
    <p:otherwise>
      
      <p:identity/>
      
    </p:otherwise>
  </p:choose>
  
</p:declare-step>
