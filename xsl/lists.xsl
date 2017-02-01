<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:xs="http://www.w3.org/2001/XMLSchema"
  xmlns:dbk="http://docbook.org/ns/docbook"
  xmlns:tr="http://transpect.io"
  version="2.0" 
  exclude-result-prefixes="xs">
  
  <xsl:import href="http://transpect.io/xslt-util/roman-numerals/xsl/roman2int.xsl"/>
  
  <xsl:template match="*:orderedlist">
    <xsl:variable name="list-type"
		  select="tr:enumerate-list-type((@numeration, 'arabic')[1], *:listitem[1]/@override)" as="xs:string"/>
    <!-- use 1st override or if empty 1st override of sublist -->
    <xsl:variable name="override"
		  select="(*:listitem[1], *:listitem[1]/*:orderedlist[1]/*:listitem[1])[string-length(@override) gt 0][1]/@override" as="xs:string?"/>
    <xsl:variable name="start" select="if(string-length($override) gt 0 and @numeration) 
                                       then tr:list-number-to-integer($override, @numeration) - 1
                                       else 0" as="xs:integer"/>
    <xsl:variable name="level" select="count(ancestor::*:orderedlist) + 1" as="xs:integer"/>
    <xsl:variable name="level-roman" as="xs:string">
      <xsl:number value="$level" format="i"/>
    </xsl:variable>
    <xsl:copy>
      <xsl:apply-templates select="@*"/>
      <xsl:processing-instruction name="latex" 
      select="concat('\begin{enumerate}[',
                     $list-type,']&#xa;',
                     if($start gt 0) 
                     then concat('\setcounter{enum', $level-roman, '}{', $start, '}') 
                     else ''
              )"/>
      <xsl:text>&#xa;&#xa;</xsl:text>
      <xsl:apply-templates/>
      <xsl:processing-instruction name="latex" select="'\end{enumerate}'"/>
      <xsl:text>&#xa;&#xa;</xsl:text>
    </xsl:copy>
  </xsl:template>
  
  <xsl:template match="@*|*|processing-instruction()">
    <xsl:copy>
      <xsl:apply-templates select="@*|node()"/>
    </xsl:copy>
  </xsl:template>
  
  <xsl:function name="tr:enumerate-list-type" as="xs:string">
    <xsl:param name="numeration" as="xs:string"/>
    <xsl:param name="override" as="xs:string?"/>
    <xsl:variable name="list-type" 
                  select="if($numeration eq 'loweralpha') then 'a'
                          else if($numeration eq 'upperalpha') then 'A'
                          else if($numeration eq 'lowerroman') then 'i'
                          else if($numeration eq 'upperroman') then 'I'
                          else if($numeration eq 'arabic' and matches($override, '(\d+)(\.\d+)+')) then replace($override, '^(.+)\.\d+\.?$', '{$1}.1')
                          else '1'" as="xs:string"/>
    <xsl:value-of select="$list-type"/>
  </xsl:function>
  
  <xsl:function name="tr:list-number-to-integer" as="xs:integer">
    <xsl:param name="override" as="xs:string"/>
    <xsl:param name="list-type" as="xs:string"/>
    <xsl:variable name="counter"
		  select="tokenize(
		                   replace(
		                           replace($override, '[\s\(\)\]\[\{\}&#xa0;]', '', 'i'), 
		                           '\p{P}$', ''),
                                   '\.')[last()]" as="xs:string"/>
    <xsl:choose>
      <xsl:when test="$list-type = ('upperroman', 'lowerroman')">
        <xsl:value-of select="tr:roman-to-int($counter)"/>
      </xsl:when>
      <xsl:when test="$list-type = ('upperalpha', 'loweralpha')">
        <xsl:value-of select="string-length(substring-before('abcdefghijklmnopqrstuvwxyz', $counter)) + 1"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:value-of select="xs:integer(normalize-space($counter))"/>
      </xsl:otherwise>
    </xsl:choose> 
  </xsl:function>
  
</xsl:stylesheet>
