<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet 
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:xs="http://www.w3.org/2001/XMLSchema"
  xmlns:calstable="http://docs.oasis-open.org/ns/oasis-exchange/table"
  xmlns:cals2tabular="http://transpect.io/cals2tabular"
  xmlns:dbk="http://docbook.org/ns/docbook"
  version="2.0">
  
  <!-- this template expects a hub file with normalized tables -->
  
  <xsl:param name="grid" select="'yes'" as="xs:string"/>
  <xsl:param name="line-separator" select="if($grid eq 'yes') then '|' else ''" as="xs:string"/>
  
  <xsl:param name="debug" select="'no'"/>
  <xsl:param name="debug-dir-uri" select="'debug'"/>
  
  <!-- identity template -->
  
  <xsl:template match="node() | @*" priority="-10" mode="#all">
    <xsl:copy>
      <xsl:apply-templates select="@*, node()" mode="#current"/>
    </xsl:copy>
  </xsl:template>
  
  <!-- mode variables -->
  
  <xsl:variable name="cals2tabular-multirow">
    <xsl:apply-templates select="/" mode="cals2tabular:multirow"/>
  </xsl:variable>

  <xsl:variable name="cals2tabular-multicolumn">
    <xsl:apply-templates select="$cals2tabular-multirow" mode="cals2tabular:multicolumn"/>
  </xsl:variable>
  
  <xsl:variable name="cals2tabular-final">
    <xsl:apply-templates select="$cals2tabular-multicolumn" mode="cals2tabular:final"/>
  </xsl:variable>

  <!-- main template -->

  <xsl:template name="main">
    <xsl:sequence select="$cals2tabular-final"/>
    <xsl:if test="$debug eq 'yes'">
      <xsl:result-document indent="yes" method="xml" href="{$debug-dir-uri}/cals2tabular/mml2tex.xml">
        <xsl:apply-templates select="/*"/>
      </xsl:result-document>
    </xsl:if>
  </xsl:template>
  
  <!-- MODE cals2tabular:multirow -->
  
  <xsl:template match="*:entry[@xml:id]" mode="cals2tabular:multirow">
    <xsl:variable name="entry-id" select="@xml:id" as="xs:string"/>
    <!-- count following rows which contain an entry with a linkend att that is equal to the xml:id of the current entry-->
    <xsl:variable name="rowspan" 
      select="count(for $i in parent::*:row/following-sibling::*:row[*:entry[@linkend][$entry-id eq @linkend]] return $i)" as="xs:integer"/>
    <xsl:copy>
      <xsl:choose>
        <xsl:when test="$rowspan gt 0">
          <xsl:apply-templates select="@*" mode="#current"/>
          <xsl:processing-instruction name="cals2tabular" select="concat('\multirow{', $rowspan, '}{*}{' )"/>
          <xsl:apply-templates select="node()" mode="#current"/>
          <xsl:processing-instruction name="cals2tabular" select="'}'"/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:apply-templates select="@*, node()" mode="#current"/>    
        </xsl:otherwise>
      </xsl:choose>
    </xsl:copy>
  </xsl:template>
  
  <xsl:template match="*:entry[@linkend]" mode="cals2tabular:multirow">
    <xsl:variable name="entry-idref" select="@linkend" as="xs:string"/>
    <!-- check if preceding rows contains entries with a corresponding xml:id -->
    <xsl:variable name="is-rowspan-ref" 
      select="boolean(parent::*:row/preceding-sibling::*:row[*:entry[@xml:id][$entry-idref eq @xml:id]])" as="xs:boolean"/>
    <xsl:variable name="is-last" select="position() eq last()" as="xs:boolean"/>
    <xsl:copy>
      <xsl:choose>
        <xsl:when test="$is-rowspan-ref">
          <xsl:apply-templates select="@*" mode="#current"/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:apply-templates select="@*, node()" mode="#current"/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:copy>
  </xsl:template>
  
  <!-- MODE cals2tabular:multicolumn -->
  
  <xsl:template match="*:entry[@xml:id]" mode="cals2tabular:multicolumn">
    <xsl:variable name="entry-id" select="@xml:id" as="xs:string"/>
    <!-- count sibling entries with a corresponding id reference -->
    <xsl:variable name="colspan" select="count(following-sibling::*:entry[$entry-id eq @linkend]) + 1" as="xs:integer"/>
    <xsl:variable name="cell-declaration" select="concat(
      $line-separator, 'l', $line-separator)" as="xs:string"/>
    <xsl:copy>
      <xsl:choose>
        <xsl:when test="$colspan gt 1">
          <xsl:apply-templates select="@*" mode="#current"/>
          <xsl:processing-instruction name="cals2tabular" select="concat('\multicolumn{', $colspan, '}{', $cell-declaration , '}{')"/>
          <xsl:apply-templates select="node()" mode="#current"/>
          <xsl:processing-instruction name="cals2tabular" select="'}'"/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:apply-templates select="@*, node()" mode="#current"/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:copy>
  </xsl:template>
  
  <xsl:template match="*:entry[@linkend]" mode="cals2tabular:multicolumn">
    <xsl:variable name="entry-idref" select="@linkend" as="xs:string"/>
    <!-- check for preceding-sibling entries with a corresponding xml:id -->
    <xsl:variable name="is-colspan-ref" select="boolean(preceding-sibling::*:entry[$entry-idref eq @xml:id ])" as="xs:boolean"/>
    <xsl:copy>
      <xsl:apply-templates select="@*, node()" mode="#current"/>
    </xsl:copy>
  </xsl:template>

  <!-- MODE cals2tabular:final -->
  
  <xsl:template match="*:entry[not(@linkend or @xml:id)]" mode="cals2tabular:final">
    <xsl:variable name="is-last" select="position() eq last()" as="xs:boolean"/>
    <xsl:copy>
      <xsl:apply-templates select="@*, node()" mode="#current"/>
    </xsl:copy>
    <xsl:if test="not($is-last)">
      <xsl:text>&#x20;</xsl:text>
      <xsl:processing-instruction name="cals2tabular" select="'&amp;&#x20;'"/>
    </xsl:if>
  </xsl:template>
  
  <xsl:template match="*:entry[@xml:id]" mode="cals2tabular:final">
    <xsl:variable name="entry-id" select="@xml:id" as="xs:string"/>
    <xsl:variable name="is-last" select="position() eq last()" as="xs:boolean"/>
    <xsl:variable name="is-colspan" 
      select="boolean(following-sibling::*:entry[$entry-id eq @linkend])" as="xs:boolean"/>
    <xsl:variable name="is-rowspan" 
      select="boolean(for $i in parent::*:row/following-sibling::*:row[*:entry[@linkend][$entry-id eq @linkend]] return $i)" as="xs:boolean"/>
    <xsl:copy>
      <xsl:apply-templates select="@*, node()" mode="#current"/>
    </xsl:copy>
    <xsl:if test="not($is-last or $is-colspan)">
      <xsl:processing-instruction name="cals2tabular" select="'&#x20;&amp;&#x20;'"/>
    </xsl:if>
  </xsl:template>
  
  <xsl:template match="*:entry[@linkend]" mode="cals2tabular:final">
    <xsl:variable name="entry-idref" select="@linkend" as="xs:string"/>
    <xsl:variable name="is-last-colspan-ref" 
      select="boolean(preceding-sibling::*:entry[$entry-idref eq @xml:id ]
      and not(following-sibling::*:entry[$entry-idref eq @linkend])
      )" as="xs:boolean"/>
    <xsl:variable name="is-rowspan-ref" 
      select="boolean(parent::*:row/preceding-sibling::*:row[*:entry[@xml:id][$entry-idref eq @xml:id]])" as="xs:boolean"/>
    <xsl:variable name="is-last" select="position() eq last()" as="xs:boolean"/>
    <xsl:copy>
      <xsl:apply-templates select="@*, node()" mode="#current"/>
    </xsl:copy>
    <xsl:if test="($is-rowspan-ref and not($is-last)) or ($is-last-colspan-ref and not($is-last))">
      <xsl:text>&#x20;</xsl:text>
      <xsl:processing-instruction name="cals2tabular" select="'&amp;&#x20;'"/>
    </xsl:if>
  </xsl:template>  
  
  <xsl:template match="*:row" mode="cals2tabular:final">
    <xsl:copy>
      <xsl:apply-templates select="@*, node()" mode="#current"/>
    </xsl:copy>
    <xsl:text>&#x20;</xsl:text>
    <xsl:processing-instruction name="cals2tabular" select="'\\'"/>    
    <xsl:text>&#xa;</xsl:text>
    <!-- test if a rowspan by @xml:id with reference to next row or an @linkend with reference to an @xml:id in previous row-->
    <xsl:variable name="rowspan-previous-row" 
      select="for $i in *:entry[@linkend] return $i[parent::*:row/preceding-sibling::*:row[*:entry[@xml:id][$i/@linkend eq @xml:id]] ]
      "/>
    <xsl:variable name="rowspan-exists" 
      select="exists(for $i in *:entry[@xml:id or @linkend] return $i[parent::*:row/following-sibling::*:row[*:entry[(@xml:id, @linkend)[1]][$i/(@xml:id, @linkend)[1] eq @linkend]] ])"/>
    <xsl:choose>
      <xsl:when test="$rowspan-exists">
        <xsl:for-each select="*:entry">
          <xsl:variable name="id" select="(@xml:id, @linkend)[1]" as="xs:string?"/>
          <xsl:variable name="pos" select="position()" as="xs:integer"/>
          <xsl:if test="not(parent::*:row/following-sibling::*:row[*:entry[@linkend][$id eq @linkend]])">
            <xsl:processing-instruction name="cals2tabular" select="concat('&#x20;\cline{', $pos, '-', $pos, '}')"/>
          </xsl:if>
        </xsl:for-each>    
      </xsl:when>
      <xsl:otherwise>
        <xsl:text>&#x20;</xsl:text>
        <xsl:processing-instruction name="cals2tabular" select="if($grid eq 'yes') then '\hline&#x20;&#xa;' else ''"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>
  
  <xsl:template match="*:tgroup" mode="cals2tabular:final">
    <xsl:variable name="col-count" select="count(*:colspec)" as="xs:integer"/>
    <xsl:variable name="col-declaration" select="concat($line-separator, string-join(for $i in (1 to $col-count) return 'l', $line-separator), $line-separator)" as="xs:string"/>
    <xsl:variable name="top-separator" select="if($grid eq 'yes') then '&#x20;\hline&#x20;&#xa;' else ''" as="xs:string"/>
    <xsl:copy>
      <xsl:apply-templates select="@*" mode="#current"/>
      <xsl:text>&#xa;</xsl:text>
      <xsl:processing-instruction name="cals2tabular" select="concat('\begin{tabular}{', $col-declaration, '}', $top-separator)"/>
      <xsl:text>&#xa;</xsl:text>
      <xsl:apply-templates mode="#current"/>
      <xsl:processing-instruction name="cals2tabular" select="'\end{tabular}'"/>
      <xsl:text>&#xa;&#xa;</xsl:text>
    </xsl:copy>
  </xsl:template>
  
</xsl:stylesheet>
