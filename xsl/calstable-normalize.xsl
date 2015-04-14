<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet 
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:calstable="http://docs.oasis-open.org/ns/oasis-exchange/table"
  version="2.0">
  
  <xsl:import href="http://transpect.io/xslt-util/calstable/xsl/normalize.xsl"/>
  
  <xsl:param name="debug" select="'no'"/>
  <xsl:param name="debug-dir-uri" select="'debug'"/>
  
  <xsl:template match="*[*:row]">
    <xsl:sequence select="calstable:check-normalized(
      calstable:normalize(.), 
      'no'
      )"/>
  </xsl:template>
  
  <xsl:template match="node() | @*">
    <xsl:copy copy-namespaces="no">
      <xsl:apply-templates select="@*, node()"/>
    </xsl:copy>
  </xsl:template>
  
  <xsl:template match="/">
    <xsl:copy>
      <xsl:apply-templates/>
    </xsl:copy>
    <!-- debugging -->
    <xsl:if test="$debug eq 'yes'">
      <xsl:result-document indent="yes" method="xml" href="{$debug-dir-uri}/calstable-normalize/mml2tex.xml">
        <xsl:apply-templates select="/*"/>
      </xsl:result-document>
    </xsl:if>
  </xsl:template>
  
</xsl:stylesheet>