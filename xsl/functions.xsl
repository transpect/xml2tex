<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:xs="http://www.w3.org/2001/XMLSchema"
  xmlns:xlink="http://www.w3.org/1999/xlink"
  xmlns:tr="http://transpect.io"  
  xmlns:xml2tex="http://transpect.io/xml2tex"
  xmlns:c="http://www.w3.org/ns/xproc-step"
  xmlns:functx="http://www.functx.com"
  xmlns:xso="tobereplaced" 
  version="2.0">
  
  <xsl:import href="http://transpect.io/xslt-util/functx/xsl/functx.xsl"/>
  <xsl:import href="http://transpect.io/xslt-util/colors/xsl/colors.xsl"/>
  
  <!-- escape special characters for tex -->
  
  <xsl:function name="xml2tex:escape-for-tex" as="xs:string">
    <xsl:param name="string" as="xs:string"/>
    <xsl:value-of select="replace( $string, '([\{\}%_&amp;\$#])', '\\$1' )"/>
  </xsl:function>
  
  <!-- replace unicode characters with latex from charmap -->
  
  <xsl:function name="xml2tex:utf2tex" as="xs:string+">
    <xsl:param name="context" as="element(*)"/>
    <xsl:param name="string" as="xs:string"/>
    <xsl:param name="charmap" as="element(xml2tex:char)+"/>
    <xsl:param name="seen" as="xs:string*"/>
    <xsl:param name="texregex" as="xs:string"/>
    <xsl:analyze-string select="$string" regex="{$texregex}">
      <xsl:matching-substring>      
        <xsl:variable name="pattern" select="functx:escape-for-regex(regex-group(1))" as="xs:string"/>
        <xsl:variable name="replacement-candidates" as="xs:string*">
          <xsl:sequence select="for $i in $charmap[matches(xml2tex:character, 
                                                           concat($pattern, '$'))][not(@context)][1]/xml2tex:string
                                return string($i)"/>
          <!-- Test whether there was a context restriction for the mapping of the current char.
              The last item is the replacement string that will be output in the most specific context. --> 
          <xsl:apply-templates select="root($context), $context/ancestor-or-self::*" mode="char-context">
            <xsl:with-param name="char-in-doc" select="."/>
          </xsl:apply-templates>
        </xsl:variable>
        <xsl:choose>
          <xsl:when test="empty($replacement-candidates)">
            <xsl:value-of select="."/>
          </xsl:when>
          <xsl:otherwise>
            <xsl:variable name="replacement" select="replace($replacement-candidates[last()], '([\$\\])', '\\$1')" as="xs:string"/>
            <xsl:variable name="result" select="replace(., $pattern, $replacement)" as="xs:string"/>
            <xsl:variable name="seen" select="concat($seen, $pattern)" as="xs:string"/>
            <xsl:choose>
              <xsl:when test="matches($result, $texregex)
                and not(($pattern = $seen) or matches($result, '^[a-z0-9A-Z\$\\%_&amp;\{\}\[\]#\|]+$'))">
                <xsl:value-of select="string-join(xml2tex:utf2tex($context, $result, $charmap, ($seen, $pattern), $texregex), '')"/>
              </xsl:when>
              <xsl:otherwise>
                <xsl:value-of select="$result"/>
              </xsl:otherwise>
            </xsl:choose>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:matching-substring>
      <xsl:non-matching-substring>
        <xsl:value-of select="."/>
      </xsl:non-matching-substring>
    </xsl:analyze-string>
  </xsl:function>
  
  <!-- convert unicode characters combined with diacritical marks -->
  
  <xsl:function name="xml2tex:convert-diacrits" as="xs:string+">
    <xsl:param name="string" as="xs:string"/>
    <xsl:param name="texregex" as="xs:string"/>
    <xsl:variable name="map" as="element(map)">
      <map>
        <mark hex="&#x300;" tex="\`"/>          <!-- grave accent -->
        <mark hex="&#x301;" tex="\'"/>          <!-- acute accent -->
        <mark hex="&#x302;" tex="\^"/>          <!-- circumflex accent -->
        <mark hex="&#x303;" tex="\~"/>          <!-- tilde -->
        <mark hex="&#x304;" tex="\="/>          <!-- macron -->
        <mark hex="&#x305;" tex="\="/>          <!-- overline -->
        <mark hex="&#x306;" tex="\u"/>          <!-- breve -->
        <mark hex="&#x307;" tex="\."/>          <!-- dot above -->
        <mark hex="&#x308;" tex="\&quot;"/>     <!-- diaeresis -->
        <mark hex="&#x30a;" tex="\r"/>          <!-- ring above -->
        <mark hex="&#x30b;" tex="\H"/>          <!-- double acute accent -->
        <mark hex="&#x30c;" tex="\v"/>          <!-- caron/háček -->
        <mark hex="&#x30d;" tex="\="/>          <!-- vertical line above, not we misuse the macron for this -->
        <mark hex="&#x30e;" tex="\v"/>          <!-- double vertical line above -->
        <mark hex="&#x323;" tex="\d"/>          <!-- dot below -->
        <mark hex="&#x327;" tex="\c"/>          <!-- cedilla -->
        <mark hex="&#x328;" tex="\k"/>          <!-- ogonek -->
        <mark hex="&#x331;" tex="\b"/>          <!-- macron below -->
        <mark hex="&#x332;" tex="\b"/>          <!-- low line -->
        <mark hex="&#x324;" tex="\~"/>          <!-- greek perispomeni -->
        <mark hex="&#x2044;" tex="\frac"/>      <!-- fraction slash -->
      </map>
    </xsl:variable>
    <xsl:variable name="normalize-unicode" select="normalize-unicode($string, 'NFKD')" as="xs:string"/>
    <xsl:variable name="diacritica-regex" select="'([a-zA-Z])([&#x300;-&#x36F;])'" as="xs:string"/>
    <xsl:variable name="fraction-regex" select="'(\d)([&#x2044;])(\d+)'" as="xs:string"/>
    <!-- decompose diacritical marks -->
    <xsl:choose>
      <xsl:when test="matches($normalize-unicode, $diacritica-regex)">
        <xsl:analyze-string select="$normalize-unicode" regex="{$diacritica-regex}" flags="i">
          <xsl:matching-substring>
            <xsl:variable name="char" select="concat('{', regex-group(1), '}')" as="xs:string"/>
            <xsl:variable name="mark" select="regex-group(2)" as="xs:string"/>
            <xsl:variable name="tex-instr" select="$map//mark[@hex eq $mark]/@tex" as="xs:string*"/>
            <xsl:value-of select="if(string-length($tex-instr) gt 0 and not(matches(normalize-unicode(.), $texregex)))
              then concat($tex-instr, $char)
              else normalize-unicode(.)"/>
          </xsl:matching-substring>
          <xsl:non-matching-substring>
            <xsl:value-of select="."/>
          </xsl:non-matching-substring>
        </xsl:analyze-string>    
      </xsl:when>
      <!-- simple fractions -->
      <xsl:when test="matches($normalize-unicode, $fraction-regex)">
        <xsl:analyze-string select="$normalize-unicode" regex="{$fraction-regex}" flags="i">
          <xsl:matching-substring>
            <xsl:variable name="args" select="concat('{', regex-group(1), '}{', regex-group(3), '}')" as="xs:string"/>
            <xsl:variable name="mark" select="'&#x2044;'" as="xs:string"/>
            <xsl:variable name="tex-instr" select="$map//mark[@hex eq $mark]/@tex" as="xs:string*"/>
            <xsl:value-of select="concat('$', $tex-instr, $args, '$')"/>
          </xsl:matching-substring>
          <xsl:non-matching-substring>
            <xsl:value-of select="."/>
          </xsl:non-matching-substring>
        </xsl:analyze-string>
      </xsl:when>
      <xsl:otherwise>
        <xsl:value-of select="$string"/>
      </xsl:otherwise>
    </xsl:choose>
    
  </xsl:function>
  
  <!-- set simple math expressions in math mode -->
  
  <xsl:function name="xml2tex:convert-simplemath" as="xs:string+">
    <xsl:param name="string" as="xs:string"/>
    <xsl:variable name="map" as="element(map)">
      <map>
        <mark hex="&#x221a;" tex="\sqrt"/>      <!-- radical -->
        <mark hex="&#x221b;" tex="\sqrt[3]"/>   <!-- cube root -->
        <mark hex="&#x221c;" tex="\sqrt[4]"/>   <!-- fourth root -->          
      </map>
    </xsl:variable> 
    <!--  -->
    <xsl:variable name="root-regex" select="'([&#x221a;&#x221b;&#x221c;])(\d+)'" as="xs:string"/>
    <xsl:variable name="simpleeq-regex" select="'(\p{L}|\d+([\.,]\d+)*)((\s*[=\-+/]\s*)+(\p{L}|\d+([\.,]\d+)*)){2,}'" as="xs:string"/>
    <xsl:choose>
      <!-- simple root -->
      <xsl:when test="matches($string, $root-regex)">
        <xsl:analyze-string select="$string" regex="{$root-regex}" flags="i">
          <xsl:matching-substring>
            <xsl:variable name="args" select="concat('{', regex-group(2), '}')" as="xs:string"/>
            <xsl:variable name="mark" select="regex-group(1)" as="xs:string"/>
            <xsl:variable name="tex-instr" select="$map//mark[@hex eq $mark]/@tex" as="xs:string*"/>
            <xsl:value-of select="concat('$', $tex-instr, $args, '$')"/>
          </xsl:matching-substring>
          <xsl:non-matching-substring>
            <xsl:value-of select="."/>
          </xsl:non-matching-substring>
        </xsl:analyze-string>
      </xsl:when>
      <!-- set simple equations automatically in math mode, e.g. 3 + 2 = a, exclude dates -->
      <xsl:when test="matches($string, concat('(^|\s)', $simpleeq-regex, '($|\s)'))
        and not(matches($string, '\d{4}(-\d{2}){2}'))
        and not(matches($string, '(\d{2}\.\s?){2}\d{4}'))
        and matches($string, '=')">
        <xsl:analyze-string select="$string" regex="{$simpleeq-regex}" flags="i">
          <xsl:matching-substring>
            <xsl:value-of select="concat(' $', ., '$ ')"/>
          </xsl:matching-substring>
          <xsl:non-matching-substring>
            <xsl:value-of select="."/>
          </xsl:non-matching-substring>
        </xsl:analyze-string>
      </xsl:when>
      <xsl:otherwise>
        <xsl:value-of select="$string"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:function>
  
  <xsl:function name="xml2tex:get-delimiter" as="xs:string">
    <xsl:param name="type" as="xs:string"/>
    <xsl:param name="start" as="xs:boolean"/>
    <xsl:variable name="open"  select="     if($type eq 'param')  then '{'
                                       else if($type eq 'option') then '['
                                       else ''" as="xs:string"/>
    <xsl:variable name="close" select="     if($type eq 'param')  then '}'
                                       else if($type eq 'option') then ']'
                                       else ''" as="xs:string"/>
    <xsl:value-of select="if($start) then $open else $close"/>
  </xsl:function>
  
  <xsl:function name="xml2tex:index-of" as="xs:integer">
    <xsl:param name="seq" as="node()*"/>
    <xsl:param name="node" as="node()?"/>
    <xsl:sequence select="index-of(for $n in $seq return generate-id($n), $node/generate-id())"/>
  </xsl:function>
  
  <xsl:function name="xml2tex:url-insert-break-point-symbol" as="xs:string">
    <xsl:param name="href" as="xs:string"/>
    <xsl:param name="symbol" as="xs:string"/>
    <xsl:value-of select="replace(
                                  replace(
                                          replace(
                                                  replace($href,
                                                          '([-_./=?])([^-_./=?]{3,})',
                                                          concat('$1', $symbol, '$2')),
                                                  '\\?(&amp;)',
                                                  concat($symbol, '\\$1')), 
                                          '\\?_',   
                                          '\\_'
                                          ),
                                  '-',
                                  '&#x2011;'
                                  )"/>
  </xsl:function>
  
  <xsl:function name="xml2tex:lang-to-latex-pkg" as="xs:string?">
    <xsl:param name="lang" as="xs:string"/>
    <xsl:value-of select="     if($lang eq 'de') then '\usepackage[ngerman]{babel}'
                          else if($lang eq 'fr') then '\usepackage[frenchb]{babel}'
                          else if($lang eq 'it') then '\usepackage[italian]{babel}'
                          else if($lang eq 'es') then '\usepackage[spanish]{babel}'
                          else if($lang eq 'cs') then '\usepackage[czech]{babel}'
                          else if($lang eq 'fi') then '\usepackage[finnish]{babel}'
                          else if($lang eq 'el') then '\usepackage[english,greek]{babel}'
                          else if($lang eq 'hu') then '\usepackage[magyar]{babel}'
                          else if($lang eq 'is') then '\usepackage[icelandic]{babel}'
                          else if($lang eq 'pl') then '\usepackage[polish]{babel}'
                          else if($lang eq 'pt') then '\usepackage[portuguese]{babel}'
                          else if($lang = ('ar', 'fa', 'ur', 'ps', 'ku', 'ug')) then '\usepackage{arabtex}'
                          else if($lang eq 'zh') then '\usepackage{CJK}'
                          else ()"/>
  </xsl:function>
  
  <xsl:function name="xml2tex:rgb-to-tex-color">
    <xsl:param name="colors" as="xs:string*"/>
    <xsl:variable name="colors-filtered" select="distinct-values($colors)"/>
    <xsl:for-each select="$colors-filtered">
      <xsl:value-of select="concat('color{',
                                   for $i in . return concat('color-', index-of($colors-filtered, $i)),
                                   '}{rgb}{',
                                   string-join(for $i in tr:hex-rgb-color-to-ints(.) 
                                               return xs:string(round-half-to-even($i div 255, 2)),
                                               ','),
                                  '}')"/>
    </xsl:for-each>
  </xsl:function>

</xsl:stylesheet>