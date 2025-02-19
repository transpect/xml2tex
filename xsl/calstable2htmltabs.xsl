<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:xs="http://www.w3.org/2001/XMLSchema" 
  xmlns:css="http://www.w3.org/1996/css"
  xmlns:xml2tex="http://transpect.io/xml2tex"
  xmlns:tr="http://transpect.io"
  xmlns="http://www.w3.org/1999/xhtml" 
  xpath-default-namespace="http://www.w3.org/1999/xhtml"
  exclude-result-prefixes="css xs xml2tex" 
  version="2.0">

  <!-- this stylesheets converts CALS tables 
       to htmltabs 
  -->
  
  <xsl:import href="functions.xsl"/>
  <xsl:import href="http://transpect.io/xslt-util/cals2htmltable/xsl/cals2htmltables.xsl"/>
  
  <xsl:param name="table-col-declaration" select="''" as="xs:string"/>
  <xsl:param name="table-first-col-declaration" select="''" as="xs:string"/>
  <xsl:param name="table-last-col-declaration" select="''" as="xs:string"/>
  
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
  
  <xsl:template match="*:informaltable/@role | *:table/@role | *:entry/@role" mode="cals2html-table">
    <xsl:attribute name="class" select="."/>
    <xsl:attribute name="role" select="."/>
  </xsl:template>
  
  <xsl:template match="*:entry[not(*) and not(normalize-space())]/@*[matches(name(), '^css:padding-(left|right)')]" mode="cals2html-table">
    <xsl:attribute name="{name()}" select="'0pt'"/>
   <!-- set padding on empty cells to zero to avoid errors if padding exceeds col width, https://redmine.le-tex.de/issues/15094 -->
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
        <xsl:value-of select="xml2tex:atts-to-option(@*)"/>
        <xsl:text>&#xa;</xsl:text>
      </xsl:processing-instruction>
      <xsl:apply-templates select="* except (*:tfoot, *:tbody), *:tfoot, *:tbody" mode="#current"/>
      <xsl:processing-instruction name="htmltabs" 
                                  select="'&#xa;\end{htmltab}&#xa;'"/>
    </xsl:copy>
  </xsl:template>
  
  <xsl:template match="caption" mode="htmltabs">
    <xsl:processing-instruction name="htmltabs" 
                                select="'\HTcaption{'"/>
    <xsl:apply-templates mode="#current"/>
    <xsl:processing-instruction name="htmltabs" 
                                select="'}&#xa;'"/>
  </xsl:template>
  
  <xsl:template match="colgroup" mode="html2tabs">
    <xsl:copy>
      <xsl:processing-instruction name="htmltabs"
                                  select="concat('\begin{colgroup}', xml2tex:atts-to-option(@*), '&#xa;')"/>
      <xsl:apply-templates select="@*, *" mode="#current"/>
      <xsl:processing-instruction name="htmltabs"
                                  select="'\end{colgroup}&#xa;'"/>
    </xsl:copy>
  </xsl:template>
  
  <xsl:template match="col[@css:width]" mode="html2tabs">
    <xsl:variable name="pos" select="position()" as="xs:integer"/>
    <xsl:variable name="col-count" select="count(parent::*/col)" as="xs:integer"/>
    <xsl:variable name="col-override" as="xs:string?" 
                  select="($table-first-col-declaration[$pos = 1][normalize-space()],
                           $table-last-col-declaration[$pos = $col-count][normalize-space()],
                           $table-col-declaration)[1]"/>
    <xsl:copy>
      <xsl:apply-templates select="@*" mode="#current"/>
      <xsl:processing-instruction name="htmltabs" 
                                  select="concat('\HTcol[',
                                                 ($col-override[normalize-space()],
                                                  concat('width=',
                                                         xml2tex:absolute-to-relative-col-width(@css:width, parent::*/col/@css:width) * 100))[1],
                                                 '\%]&#xa;')"/>
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
  
  <xsl:variable name="strut-element-names" select="'^((itemized|ordered)list|inlinemediaobject|mediaobject)$'"/>
  
  <xsl:template match="td|th" mode="html2tabs">
    <xsl:copy>
      <xsl:apply-templates select="@*" mode="#current"/>
        <xsl:variable name="additional-atts" as="attribute()*">
          <xsl:apply-templates select="." mode="html2tabs_atts"/>
        </xsl:variable>
      <xsl:processing-instruction name="htmltabs" 
                                  select="concat('\HT', local-name(),
                                                 xml2tex:atts-to-option((@*, $additional-atts)),
                                                 '{')"/>
      <xsl:apply-templates select="node()" mode="#current"/>
      <xsl:processing-instruction name="htmltabs" 
                                  select="'}&#xa;'"/>
    </xsl:copy>
  </xsl:template>
  
   <!--  normalize trailing spaces -->
  <xsl:template match="*[self::td or self::th]/*:para[last()][matches(string-join(descendant::text(),''),'\p{Zs}+$')]/text()[last()][not(following-sibling::node())][matches(.,'\p{Zs}+$')]" mode="html2tabs">
    <xsl:sequence select="replace(.,'\p{Zs}+$','')"/>
  </xsl:template>
  
  <xsl:template match="td[node()][every $el in * satisfies matches($el/local-name(),$strut-element-names)]"  mode="html2tabs_atts">
    <xsl:attribute name="no-strut" select="'both'" />
  </xsl:template>
  
  <xsl:template match="td[not(every $el in * satisfies matches($el/local-name(),$strut-element-names))]
                         [*[1][self::*[matches(local-name(),$strut-element-names)]]]"  mode="html2tabs_atts">
    <xsl:attribute name="no-strut" select="'top'" />
  </xsl:template>
  
  <xsl:template match="td[not(every $el in * satisfies matches($el/local-name(),$strut-element-names))]
                         [*[last()][self::*[matches(local-name(),$strut-element-names)]]]"  mode="html2tabs_atts">
    <xsl:attribute name="no-strut" select="'bottom'" />
  </xsl:template>
  
  <xsl:template match="node()| @*" mode="html2tabs_atts"/>
  
  <xsl:variable name="no-css-atts-in-style" select="'no-strut'"/>
  
  <xsl:function name="xml2tex:atts-to-option" as="xs:string?">
    <xsl:param name="atts" as="attribute()*"/>
    <xsl:if test="$atts">
      <xsl:sequence select="concat('[',
                                  if ($atts[local-name() = 'width']) 
                                  then concat('width=', xml2tex:escape-for-tex($atts[local-name() = 'width']),',') else '',
                                  string-join(
                                    (xml2tex:css-atts-to-style-att($atts[namespace-uri() eq 'http://www.w3.org/1996/css' or local-name() = $no-css-atts-in-style]
                                                                        [local-name() ne 'width']
                                     ),
                                     $atts[local-name() = ('id', 'class', 'colspan', 'rowspan')]/concat(local-name(), '=', ., '')),
                                    ','),
                                  ']')"/>
    </xsl:if>
  </xsl:function>
  
  <xsl:function name="xml2tex:css-atts-to-style-att" as="xs:string?">
    <xsl:param name="css-atts" as="attribute()*"/>
    <xsl:variable name="prelim" as="attribute(*)*">
      <xsl:apply-templates select="$css-atts" mode="xml2tex:css-atts-to-style-att"/>
    </xsl:variable>
    <xsl:sequence select="if(exists($css-atts)) 
                          then concat('style={',
                                      string-join($prelim/concat(local-name(), ':', .), 
                                      ';'),
                                      '}')
                          else ()"/>
  </xsl:function>
  
  <xsl:template match="@*" mode="xml2tex:css-atts-to-style-att">
    <xsl:copy/>
  </xsl:template>
  
  <xsl:template match="@*[contains(., '#')]" mode="xml2tex:css-atts-to-style-att">
    <xsl:attribute name="{name()}" select="replace(., '(^|[^\\])#', '\\#')"/>
  </xsl:template>
  
  <xsl:template match="@*[contains(., '%')]" mode="xml2tex:css-atts-to-style-att">
    <xsl:attribute name="{name()}" select="replace(., '%', '\\%')"/>
  </xsl:template>
  
  <xsl:template match="@*[. = 'outset']" mode="xml2tex:css-atts-to-style-att">
    <xsl:attribute name="{name()}" select="'solid'"/>
  </xsl:template>

  <xsl:template match="@*[matches(., '^auto$')]" mode="xml2tex:css-atts-to-style-att"/>
  
  <xsl:variable name="css-atts-to-dissolve" select="'^line-height$'"/>
  
    
  <xsl:template match="@css:*[matches(local-name(),$css-atts-with-generic-values)]
                             [not(matches(.,$css-generic-values))]" mode="xml2tex:css-atts-to-style-att"/>
  
  <xsl:template match="@css:*[matches(local-name(), $css-atts-to-dissolve)]" mode="xml2tex:css-atts-to-style-att"/>
  
  <xsl:variable name="css-generic-values" select="'(sans-)?serif|monospace|bold|normal|center|left|right|justify|bottom|top|(x?x-)?small(-caps)?|(x?x-)?large|auto|none|collapse|separate'"/>
  <xsl:variable name="css-atts-with-generic-values" select="'font-(weight|family|style|variant)|hyphens|border-collapse'"/>
  
  <xsl:template match="@css:writing-mode" mode="xml2tex:css-atts-to-style-att">
     <xsl:attribute name="{if (. = ('bt-lr', 'vertical-rl', 'vertical-lr', 'sideways-rl', 'sideways-lr')) then 'css:transform' else name()}" 
                  select="if (. = ('vertical-rl', 'vertical-lr', 'sideways-rl')) 
                          then 'rotate(90deg)' 
                          else if (. = ('bt-lr','sideways-lr')) then 'rotate(-90deg)'
                          else ."/>
  </xsl:template>
  
  
</xsl:stylesheet>
