<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:xs="http://www.w3.org/2001/XMLSchema"
  xmlns:map="http://www.w3.org/2005/xpath-functions/map"
  xmlns:tr="http://transpect.io"
  xmlns:calstable="http://docs.oasis-open.org/ns/oasis-exchange/table"
  xmlns:cals2tabular="http://transpect.io/cals2tabular"
  xmlns:dbk="http://docbook.org/ns/docbook"
  xmlns:css="http://www.w3.org/1996/css"
  version="3.0">
  
  <xsl:import href="http://transpect.io/xslt-util/num/xsl/num.xsl"/>
  
  <!-- this template expects a hub file with normalized tables -->
  
  <xsl:param name="table-model" select="'tabularx'" as="xs:string"/><!-- tabularx | tabular -->
  <xsl:param name="table-grid" select="'yes'" as="xs:string"/>
  <xsl:param name="line-separator" select="if($table-grid eq 'yes') then '|' else ''" as="xs:string"/>
  <xsl:param name="no-table-grid-att" select="'role'"/>
  <xsl:param name="no-table-grid-style" select="'blind-table'"/>
  
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
      select="count(for $i in parent::*:row/following-sibling::*:row[*:entry[@linkend][$entry-id eq @linkend]] 
                    return $i) + 1" as="xs:integer"/>
    <xsl:variable name="vertical-align" as="xs:string?"
                  select="if(not(@css:vertical-align)) then '[t]'
                          else if(@css:vertical-align eq 'bottom') then '[b]'
                          else ()"/>
    <xsl:copy>
      <xsl:choose>
        <xsl:when test="$rowspan gt 1">
          <xsl:apply-templates select="@*" mode="#current"/>
          <xsl:processing-instruction name="cals2tabular" 
                                      select="concat('\multirow', $vertical-align, '{', $rowspan, '}{=}{' )"/>
          <xsl:sequence select="cals2tabular:cell-align(@css:text-align)"/>
          <xsl:choose>
            <xsl:when test="count(*:para) lt 2">
              <xsl:apply-templates mode="#current"/>    
            </xsl:when>
            <xsl:otherwise>
              <xsl:processing-instruction name="cals2tabular" 
                                          select="'\parbox{\textwidth}{'"/>
              <xsl:for-each select="*:para">
                <xsl:copy>
                  <xsl:apply-templates select="@*, node()" mode="#current"/>  
                </xsl:copy>                
                <xsl:processing-instruction name="cals2tabular" 
                                            select="if(position() ne last()) then ' \\ ' else ''"/>
              </xsl:for-each>
              <xsl:processing-instruction name="cals2tabular" 
                                          select="'}'"/>
            </xsl:otherwise>
          </xsl:choose>
          <xsl:processing-instruction name="cals2tabular" select="'} '"/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:apply-templates select="@*" mode="#current"/>
          <xsl:sequence select="cals2tabular:cell-align(@css:text-align)"/>
          <xsl:apply-templates mode="#current"/>
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
          <xsl:apply-templates select="@*" mode="#current"/>
          <xsl:sequence select="cals2tabular:cell-align(@css:text-align)"/>
          <xsl:apply-templates mode="#current"/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:copy>
  </xsl:template>
  
  <!-- MODE cals2tabular:multicolumn -->
  
  <xsl:template match="*:entry[@xml:id]" mode="cals2tabular:multicolumn">
    <xsl:variable name="pos" select="count(preceding-sibling::*:entry) + 1" as="xs:integer"/>
    <xsl:variable name="entry-id" select="@xml:id" as="xs:string"/>
    <xsl:variable name="line-separator" select="if (ancestor::*/@*[name()=$no-table-grid-att] = $no-table-grid-style) then '' else $line-separator"/>
    <xsl:variable name="table-grid" select="if (ancestor::*/@*[name()=$no-table-grid-att] = $no-table-grid-style) then 'no' else $table-grid"/>
    <!-- count sibling entries with a corresponding id reference -->
    <xsl:variable name="colspan" select="count(following-sibling::*:entry[$entry-id eq @linkend]) + 1" as="xs:integer"/>
    <xsl:copy>
      <xsl:choose>
        <xsl:when test="$colspan gt 1">
          <xsl:variable name="col-count" select="cals2tabular:col-count(ancestor::*[3][self::*:tgroup])" as="xs:integer"/>
          <xsl:variable name="col-widths" select="cals2tabular:col-widths(ancestor::*[3][self::*:tgroup]/*:colspec)" as="xs:decimal*"/>
          <xsl:variable name="multicol-width" as="xs:decimal" 
                        select="sum(for $i in ($pos to $pos + $colspan - 1) return $col-widths[$i])"/>
          <xsl:variable name="cell-declaration" as="xs:string"
                        select="concat(if(not(preceding-sibling::*[1])) then $line-separator else (), 
                                       cals2tabular:cell-declaration($multicol-width, $table-grid eq 'yes', $pos),
                                       $line-separator)"/>
          <xsl:apply-templates select="@*" mode="#current"/>
          <xsl:processing-instruction name="cals2tabular" 
                                      select="concat('\multicolumn{', $colspan, '}{', $cell-declaration , '}{')"/>
          <xsl:sequence select="cals2tabular:cell-align(@css:text-align)"/>
          <xsl:apply-templates select="node()" mode="#current"/>
          <xsl:processing-instruction name="cals2tabular" select="'}'"/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:apply-templates select="@*" mode="#current"/>
          <xsl:sequence select="cals2tabular:cell-align(@css:text-align)"/>
          <xsl:apply-templates select="node()" mode="#current"/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:copy>
  </xsl:template>
  
  <xsl:template match="*:entry[@linkend]" mode="cals2tabular:multicolumn">
    <xsl:variable name="line-separator" select="if (ancestor::*/@*[name()=$no-table-grid-att] = $no-table-grid-style) then '' else $line-separator"/>
    <xsl:variable name="table-grid" select="if (ancestor::*/@*[name()=$no-table-grid-att] = $no-table-grid-style) then 'no' else $table-grid"/>
    <xsl:variable name="entry-idref" select="@linkend" as="xs:string"/>
    <xsl:variable name="is-rowspan-and-colspan-ref" as="xs:boolean"
                  select="@morerows 
                          and not(preceding-sibling::*[1][@linkend eq $entry-idref])
                          and     following-sibling::*[1][@linkend eq $entry-idref]"/>
    <xsl:variable name="colspan" select="count(following-sibling::*:entry[@linkend eq $entry-idref]) + 1" as="xs:integer"/>
    <xsl:variable name="cell-declaration" as="xs:string"
                  select="concat(if(not(preceding-sibling::*[1])) then $line-separator else (),
                                 'l', 
                                 $line-separator)"/>
    <xsl:if test="$is-rowspan-and-colspan-ref">
      <xsl:processing-instruction name="cals2tabular" 
                                  select="concat('\multicolumn{', $colspan, '}{', $cell-declaration , '}{')"/>
    </xsl:if>
    <xsl:copy>
      <xsl:apply-templates select="@*, node()" mode="#current"/>
    </xsl:copy>
    <xsl:if test="$is-rowspan-and-colspan-ref">
      <xsl:processing-instruction name="cals2tabular" 
                                  select="'}'"/>
    </xsl:if>
  </xsl:template>

  <!-- MODE cals2tabular:final -->
  
  <xsl:template match="*:entry[not(@linkend or @xml:id)]" mode="cals2tabular:final">
    <xsl:sequence select="cals2tabular:cell-align(@css:text-align)"/>
    <xsl:copy>
      <xsl:apply-templates select="@*, node()" mode="#current"/>
    </xsl:copy>
    <xsl:if test="position() ne last()">
      <xsl:text>&#x20;</xsl:text>
      <xsl:processing-instruction name="cals2tabular" select="'&amp;&#x20;'"/>
    </xsl:if>
  </xsl:template>
  
  <xsl:template match="*:entry[@xml:id]" mode="cals2tabular:final">
    <xsl:variable name="entry-id" select="@xml:id" as="xs:string"/>
    <xsl:variable name="is-colspan" as="xs:boolean"
                  select="boolean(following-sibling::*:entry[$entry-id eq @linkend])"/>
    <xsl:variable name="is-rowspan" as="xs:boolean"
                  select="boolean(for $i in parent::*:row/following-sibling::*:row[*:entry[@linkend][$entry-id eq @linkend]] 
                                  return $i)"/>
    <xsl:copy>
      <xsl:apply-templates select="@*, node()" mode="#current"/>
    </xsl:copy>
    <xsl:if test="not(position() eq last() or $is-colspan)">
      <xsl:text>&#x20;</xsl:text>
      <xsl:processing-instruction name="cals2tabular" select="'&amp;&#x20;'"/>
    </xsl:if>
  </xsl:template>
  
  <xsl:template match="*:entry[@linkend]" mode="cals2tabular:final">
    <xsl:variable name="entry-idref" select="@linkend" as="xs:string"/>
    <xsl:variable name="is-last-colspan-ref" as="xs:boolean"
                  select="preceding-sibling::*:entry[$entry-idref eq @xml:id ] 
                          and not(following-sibling::*:entry[$entry-idref eq @linkend])"/>
    <xsl:variable name="is-rowspan-ref" as="xs:boolean"
                  select="exists(parent::*:row/preceding-sibling::*:row[*:entry[@xml:id][$entry-idref eq @xml:id]])"/>
    <xsl:variable name="is-rowspan-and-colspan-ref" as="xs:boolean"
                  select="@morerows 
                          and not(preceding-sibling::*[1][@linkend eq $entry-idref]) 
                          and     following-sibling::*[1][@linkend eq $entry-idref]"/>
    <xsl:variable name="is-last" select="position() eq last()" as="xs:boolean"/>
    <xsl:copy>
      <xsl:apply-templates select="@*, node()" mode="#current"/>
    </xsl:copy>
    <xsl:if test="($is-rowspan-ref or $is-last-colspan-ref)
                  and not($is-last or $is-rowspan-and-colspan-ref)">
      <xsl:text>&#x20;</xsl:text>
      <xsl:processing-instruction name="cals2tabular" select="'&amp;&#x20;'"/>
    </xsl:if>
  </xsl:template>
  
  <xsl:function name="cals2tabular:cell-align" as="processing-instruction()?">
    <xsl:param name="text-align" as="attribute(css:text-align)?"/>
    <xsl:if test="$text-align">
      <xsl:processing-instruction name="cals2tabular"
                                select="if($text-align eq 'center') then '\centering\arraybackslash{}'
                                        else if($text-align eq 'right') then '\raggedleft\arraybackslash{}'
                                        else '\raggedright\arraybackslash{}'"/>  
    </xsl:if>
  </xsl:function>
  
  <xsl:template match="*:row" mode="cals2tabular:final">
    <xsl:variable name="table-grid" select="if (ancestor::*/@*[name()=$no-table-grid-att] = $no-table-grid-style) then 'no' else $table-grid"/>
    <xsl:copy>
      <xsl:apply-templates select="@*, node()" mode="#current"/>
    </xsl:copy>
    <xsl:text>&#x20;</xsl:text>
    <xsl:processing-instruction name="cals2tabular" select="'\\'"/>
    <!-- test if a rowspan by @xml:id with reference to next row or an @linkend with reference to an @xml:id in previous row-->
    <xsl:variable name="rowspan-exists" 
                  select="exists(for $i in *:entry[@xml:id or @linkend]
                                 return $i[parent::*:row/following-sibling::*:row[*:entry[(@xml:id, @linkend)[1]][$i/(@xml:id, @linkend)[1] eq @linkend]]])"/>
    <xsl:choose>
      <xsl:when test="$rowspan-exists">
        <xsl:variable name="col-indices" as="xs:integer*">
          <xsl:for-each select="*:entry">
            <xsl:variable name="id" select="(@xml:id, @linkend)[1]" as="xs:string?"/>
            <xsl:variable name="index" select="position()" as="xs:integer"/>
            <xsl:if test="not(parent::*:row/following-sibling::*:row[*:entry[@linkend][$id eq @linkend]])">
              <xsl:value-of select="$index"/>
            </xsl:if>
          </xsl:for-each>
        </xsl:variable>
        <xsl:variable name="col-range-map" select="tr:get-adjacent-integers-from-seq($col-indices)" as="map(xs:integer, xs:integer*)"/>
        <xsl:for-each select="1 to map:size($col-range-map)">
          <xsl:variable name="col-range" 
                        select="$col-range-map(position())" as="xs:integer*"/>
          <xsl:if test="exists($col-range)">
            <xsl:processing-instruction name="cals2tabular" 
                                        select="concat('\cline{', 
                                                       min($col-range), 
                                                       '-',
                                                       max($col-range),
                                                       '}'
                                                       )[$table-grid eq 'yes']"/>
          </xsl:if>
        </xsl:for-each>
      </xsl:when>
      <xsl:otherwise>
        <xsl:processing-instruction name="cals2tabular" 
                                    select="'\hline&#x20;'[$table-grid eq 'yes']"/>
      </xsl:otherwise>
    </xsl:choose>
    <xsl:text>&#xa;</xsl:text>
  </xsl:template>
  
  <xsl:template match="*:tgroup" mode="cals2tabular:final">
    <xsl:variable name="line-separator" select="if (ancestor::*/@*[name()=$no-table-grid-att] = $no-table-grid-style) then '' else $line-separator"/>
    <xsl:variable name="table-grid" select="if (ancestor::*/@*[name()=$no-table-grid-att] = $no-table-grid-style) then 'no' else $table-grid"/>
    <xsl:variable name="col-count" select="cals2tabular:col-count(.)" as="xs:integer"/>
    <xsl:variable name="col-widths" select="cals2tabular:col-widths(*:colspec)" as="xs:decimal*"/>
    <xsl:variable name="col-declaration" as="xs:string"
                  select="concat($line-separator,
                                 string-join(for $i in (1 to $col-count)
                                             return if(exists($col-widths))
                                                    then concat('&#xa;',
                                                                cals2tabular:cell-declaration($col-widths[$i], $table-grid eq 'yes', $i))
                                                    else 'l', 
                                             $line-separator), 
                                 $line-separator)"/>
    <xsl:variable name="top-separator" select="if($table-grid eq 'yes') then '&#x20;\hline&#x20;' else ''" as="xs:string"/>
    <xsl:copy>
      <xsl:apply-templates select="@*" mode="#current"/>
      <xsl:text>&#xa;</xsl:text>
      <xsl:processing-instruction name="cals2tabular" 
                                  select="concat('\begin{', 
                                                 if($table-model eq 'tabular') then 'tabular' else 'tabularx}{\textwidth', 
                                                 '}{', 
                                                 $col-declaration, 
                                                 '}', 
                                                 $top-separator)"/>
      <xsl:text>&#xa;</xsl:text>
      <xsl:apply-templates mode="#current"/>
      <xsl:processing-instruction name="cals2tabular" 
                                  select="concat('\end{', 
                                                 if($table-model eq 'tabular') then 'tabular' else 'tabularx',
                                                 '}')"/>
    </xsl:copy>
  </xsl:template>
  
  <xsl:function name="cals2tabular:col-count" as="xs:integer">
    <xsl:param name="tgroup" as="element()"/>
    <xsl:sequence select="((count($tgroup/*:colspec), 
                            $tgroup/@cols[. castable as xs:integer]/xs:integer($tgroup/@cols),
                            xs:integer(max(for $rows in $tgroup/*/*:row
                                           return count($rows/*)))
                            ), 
                           0)[1]"/>
  </xsl:function>
  
  <xsl:function name="cals2tabular:col-widths" as="xs:decimal*">
    <xsl:param name="colspec" as="element()*"/>
    <xsl:variable name="col-widths" as="xs:decimal*"
                  select="for $i in $colspec/@colwidth
                          return xs:decimal(replace(replace($i, '[a-z\*%]', ''), '^\.', '0.'))"/>
    <xsl:variable name="table-width" select="sum($col-widths)" as="xs:decimal"/>
    <xsl:variable name="rel-col-widths" as="xs:decimal*"
                  select="for $i in $col-widths[not(position() eq last())]
                          return round-half-to-even($i div $table-width, 2)"/>
    <xsl:variable name="last-col-width" select="1 - sum($rel-col-widths)" as="xs:decimal*"/>
    <xsl:variable name="final-col-widths" select="($rel-col-widths, $last-col-width)" as="xs:decimal*"/>
    <xsl:sequence select="$final-col-widths"/>
  </xsl:function>
  
  <xsl:function name="cals2tabular:cell-declaration" as="xs:string">
    <xsl:param name="col-width" as="xs:decimal"/>
    <xsl:param name="table-grid" as="xs:boolean"/>
    <xsl:param name="pos" as="xs:integer"/>
    <xsl:sequence select="concat('p{\dimexpr ', 
                                 $col-width,
                                 '\linewidth-2\tabcolsep',
                                 if($table-grid) 
                                 then concat('-', 
                                             if($pos eq 1) then '2' else (),
                                             '\arrayrulewidth')
                                 else (),
                                 '}')"/>
  </xsl:function>
  
</xsl:stylesheet>
