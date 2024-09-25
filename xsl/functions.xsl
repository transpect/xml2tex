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
  
  <xsl:variable name="xml2tex:bad-chars-regex" as="xs:string"
                select="'([\{\}%_&amp;\$#])'"/>
    
  <xsl:function name="xml2tex:escape-for-tex" as="xs:string">
    <xsl:param name="string" as="xs:string"/>
    <xsl:value-of select="replace(
                            replace(
                              $string, $xml2tex:bad-chars-regex, '\\$1'
                            ), '([\[\]])', '{$1}'
                          )"/>
  </xsl:function>
  
  <xsl:function name="xml2tex:escape-for-xslt" as="xs:string">
    <xsl:param name="string" as="xs:string"/>
    <xsl:sequence select="replace(
                            replace(
                              $string, '\{', '{{'
                            ), '\}', '}}'
                          )"/>
  </xsl:function>
  
  <!-- replace unicode characters with latex from charmap -->
  
  <xsl:function name="xml2tex:utf2tex" as="xs:string+">
    <xsl:param name="context" as="element(*)?"/>
    <xsl:param name="string" as="xs:string"/>
    <xsl:param name="charmap" as="element(xml2tex:char)*"/>
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
          <xsl:if test="$context">
            <xsl:apply-templates select="root($context), $context/ancestor-or-self::*" mode="char-context">
              <xsl:with-param name="char-in-doc" select="."/>
            </xsl:apply-templates>
          </xsl:if>
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
                              and not(   $pattern = $seen 
                                      or matches($result, '^[a-z0-9A-Z\$\\%_&amp;\{\}\[\]#\|]+$')
                                      )">
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
  
  <xsl:function name="xml2tex:apply-regexes" as="xs:string+">
    <xsl:param name="string" as="xs:string"/>
    <xsl:param name="regex-map" as="element(xml2tex:regex)*"/>
    <xsl:variable name="regex-candidate" as="element(xml2tex:regex)?" 
                  select="$regex-map[matches($string, @regex)][1]"/>
    <xsl:variable name="regex-candidate-index" as="xs:integer" 
                  select="index-of($regex-map/generate-id(), $regex-candidate/generate-id())"/>
    <xsl:variable name="regex-map-minus-current-regex" as="element(xml2tex:regex)*"
                  select="remove($regex-map, $regex-candidate-index)"/>
    <xsl:variable name="normalize-unicode" as="xs:boolean" 
                  select="$regex-candidate/@normalize-unicode = 'true'"/>
    <xsl:choose>
      <xsl:when test="exists($regex-candidate)">
        <xsl:analyze-string select="$string" regex="{$regex-candidate/@regex}">
          <xsl:matching-substring>
            <xsl:variable name="match" select="." as="xs:string"/>
            <xsl:for-each select="$regex-candidate/xml2tex:rule">
              <xsl:value-of select="xml2tex:rule-start(.)"/>
              <xsl:for-each select="xml2tex:param
                                   |xml2tex:option
                                   |xml2tex:text">
                <xsl:variable name="select-evaluated" as="item()*">
                  <xsl:if test="@select-evaluated = 'true'">
                    <xsl:apply-templates/>
                  </xsl:if>
                </xsl:variable>
                <xsl:sequence select="string-join(
                                        (xml2tex:get-delimiters(.)[1],
                                         if(node())
                                         then $select-evaluated
                                         else xml2tex:apply-regexes(
                                                if($normalize-unicode) then normalize-unicode($match, 'NFD') else $match, 
                                                $regex-map-minus-current-regex
                                              ),
                                         xml2tex:get-delimiters(.)[2]
                                        ), ''
                                      )"/>
              </xsl:for-each>
              <xsl:value-of select="xml2tex:rule-end(.)"/>
            </xsl:for-each>
          </xsl:matching-substring>
          <xsl:non-matching-substring>
            <xsl:sequence select="xml2tex:apply-regexes(., $regex-map-minus-current-regex)"/>
          </xsl:non-matching-substring>
        </xsl:analyze-string>
      </xsl:when>
      <xsl:otherwise>
        <xsl:value-of select="$string"/>    
      </xsl:otherwise>
    </xsl:choose>
  </xsl:function>
  
  <xsl:function name="xml2tex:rule-start" as="xs:string">
    <xsl:param name="rule" as="element(xml2tex:rule)"/>
    <!-- three types: 
            env   ==> environment, eg. e.g. begin{bla} ... end{bla}
            cmd   ==> commands, e.g. \bla ...
            none  ==> no tex markup, needed for simple paras or other stuff you want to simply tunnel through the process -->
    <xsl:variable name="rule-start" as="xs:string?"
                  select="concat($rule[@break-before]/string-join(for $i in (1 to @break-before) 
                                                                  return '&#xa;', ''),
                                      if($rule/@type eq 'env') then concat($rule[not(@break-before)]/'&#xa;', 
                                                                           '\begin{',$rule/@name,'}')
                                 else if(not($rule/@type))     then ()             
                                 else                               concat('\', $rule/@name),
                                 $rule[@mathmode eq 'true']/'$')"/>
    <xsl:value-of select="$rule-start"/>
  </xsl:function>
    
  <xsl:function name="xml2tex:rule-end" as="xs:string">
    <xsl:param name="rule" as="element(xml2tex:rule)"/>
    <xsl:variable name="closing-tag" as="xs:string?"
                  select="concat($rule[@mathmode eq 'true']/'$',
                                 if($rule/@type eq 'env') 
                                 then concat('&#xa;\end{',$rule/@name,'}', $rule[not(@break-after)]/'&#xa;')
                                 else (),
                                 $rule[@break-after]/string-join(for $i in (1 to @break-after) 
                                 return '&#xa;', ''))"/>
    <xsl:value-of select="$closing-tag"/>
  </xsl:function>
  
  
  <!--  replace regex ranges -->
  <!--<xsl:function name="xml2tex:apply-regexes" as="xs:string+">
    <xsl:param name="context" as="element(*)?"/>
    <xsl:param name="string" as="xs:string"/>
    <xsl:param name="regex-map" as="element(xml2tex:regex)*"/>
    <xsl:param name="seen" as="xs:string*"/>
    <xsl:param name="regex-regex" as="xs:string"/>
    <xsl:analyze-string select="$string" regex="{$regex-regex}">
      <xsl:matching-substring>
        <xsl:variable name="pattern" select="functx:escape-for-regex(regex-group(1))" as="xs:string"/>
        <xsl:variable name="macro-candidates" as="xs:string*"
                      select="$regex-map[matches($string, xml2tex:range)]/xml2tex:macro/string(.)"/>
        <xsl:variable name="macro-candidates-regex" as="xs:string*" 
                      select="$regex-map[matches($string, xml2tex:range)]/xml2tex:range/string(.)"/>
        <xsl:variable name="macro-candidates-text" as="xs:string*" 
                      select="$regex-map[matches($string, xml2tex:range)]/xml2tex:text/string(.)"/>
        <xsl:variable name="macro-candidates-regex-group" as="xs:string*"
                      select="$regex-map[matches($string, xml2tex:range)]/xml2tex:regex-group/string(.)"/>
        <xsl:variable name="normalize-unicode-output" as="xs:boolean*"
                      select="$regex-map[matches($string, xml2tex:range)][1]/@normalize-unicode = 'true'"/>
        <xsl:choose>
          <xsl:when test="empty($macro-candidates) and empty($macro-candidates-text)">
            <xsl:value-of select="."/>
          </xsl:when>
          <xsl:otherwise>
            <xsl:variable name="replacement-group" 
                          select=" replace(.,$macro-candidates-regex[1], concat('$',($macro-candidates-regex-group[1][. ne ''], '0')[1]))" />
            <xsl:variable name="replacement" select="if ($macro-candidates-text[normalize-space()]) 
                                                    then replace($macro-candidates-text[last()],'([\$\\])', '\\$1')
                                                    else replace(concat($macro-candidates[last()], '{',$replacement-group, '}'),'([\$\\])', '\\$1')" as="xs:string"/>
            <xsl:variable name="result" select="replace(., $pattern, $replacement)" as="xs:string"/>
            <xsl:variable name="seen" select="concat($seen, $pattern)" as="xs:string"/>
            <xsl:choose>
              <xsl:when test="matches($result, $regex-regex)
                              and not(   ($string = $seen)
                                      or matches($result, '^[a-z0-9A-Z\$\\%_&amp;\{\}\[\]#\|]+$')
                                      )">
                <xsl:value-of select="string-join(xml2tex:apply-regexes($context, $result, $regex-map, ($seen, $string), $regex-regex), '')"/>
              </xsl:when>
              <xsl:otherwise>
                <xsl:value-of select="if ($normalize-unicode-output) then normalize-unicode($result) else $result"/>
              </xsl:otherwise>
            </xsl:choose>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:matching-substring>
      <xsl:non-matching-substring>
        <xsl:value-of select="."/>
      </xsl:non-matching-substring>
    </xsl:analyze-string>
  </xsl:function>-->
  
  <xsl:variable name="xml2tex:diacrits" as="element(diacrits)">
    <diacrits>
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
      <mark hex="&#x342;" tex="\~"/>          <!-- greek perispomeni -->
      <mark hex="&#x2044;" tex="\frac"/>      <!-- fraction slash -->
      <mark hex="&#x363;" tex="\overset{{\mathrm{{a}}}}"/>
      <mark hex="&#x364;" tex="\overset{{\mathrm{{e}}}}"/>
      <mark hex="&#x365;" tex="\overset{{\mathrm{{i}}}}"/>
      <mark hex="&#x366;" tex="\overset{{\mathrm{{o}}}}"/>
      <mark hex="&#x367;" tex="\overset{{\mathrm{{u}}}}"/>
      <mark hex="&#x368;" tex="\overset{{\mathrm{{c}}}}"/>
      <mark hex="&#x369;" tex="\overset{{\mathrm{{d}}}}"/>
      <mark hex="&#x36a;" tex="\overset{{\mathrm{{h}}}}"/>
      <mark hex="&#x36b;" tex="\overset{{\mathrm{{m}}}}"/>
      <mark hex="&#x36c;" tex="\overset{{\mathrm{{r}}}}"/>
      <mark hex="&#x36d;" tex="\overset{{\mathrm{{t}}}}"/>
      <mark hex="&#x36e;" tex="\overset{{\mathrm{{v}}}}"/>
      <mark hex="&#x36a;" tex="\overset{{\mathrm{{x}}}}"/>
    </diacrits>
  </xsl:variable>
  
  <xsl:variable name="xml2tex:base-chars-regex" as="xs:string"
                select="'[a-zA-Z&#x410;&#x44f;]'" />
  <xsl:variable name="xml2tex:diacritical-marks-regex" as="xs:string"
                select="'[&#x300;-&#x36F;]'" />
  <xsl:variable name="xml2tex:diacrits-regex" as="xs:string"
                select="concat('(', $xml2tex:base-chars-regex, ')(', $xml2tex:diacritical-marks-regex, ')')" />
  <xsl:variable name="xml2tex:fraction-regex" select="'(\d)([&#x2044;])(\d+)'" as="xs:string"/>
  
  <!-- convert unicode characters combined with diacritical marks -->
  
  <xsl:function name="xml2tex:convert-diacrits" as="xs:string+">
    <xsl:param name="string" as="xs:string"/>
    <xsl:param name="texregex" as="xs:string"/>
    <xsl:param name="diacritical-marks" as="element()"/>
    <xsl:param name="charmap" as="element(xml2tex:char)*"/><!-- avoid that characters in the character map are replaced -->
    <!-- decompose diacritical marks -->
    <xsl:variable name="split-string-to-chars" as="xs:string+"
                  select="xml2tex:pair-char-and-diacrits(for $char in string-to-codepoints($string) 
                                                         return codepoints-to-string($char),
                                                         $xml2tex:base-chars-regex,
                                                         $xml2tex:diacritical-marks-regex)"/>
    <xsl:variable name="replace-per-char">
      <xsl:for-each select="$split-string-to-chars[not(substring(., 1, 1) = $charmap/xml2tex:char/@string)]">
        <xsl:variable name="context" select="."/>
        <xsl:variable name="normalize-unicode-NFD" select="normalize-unicode(., 'NFD')" as="xs:string"/>
        <xsl:variable name="normalize-unicode-NFKD" select="normalize-unicode(., 'NFKD')" as="xs:string"/>
        <xsl:variable name="overset-letter-regex" select="'[&#x363;-&#x36f;]'" as="xs:string"/>
        <xsl:choose>
          <xsl:when test="matches($normalize-unicode-NFD, $xml2tex:diacrits-regex)">
            <xsl:analyze-string select="$normalize-unicode-NFD" regex="{$xml2tex:diacrits-regex}" flags="i">
              <xsl:matching-substring>
                <xsl:variable name="mark" select="regex-group(2)" as="xs:string"/>
                <xsl:variable name="mark-is-overset-letter" select="matches($mark, $overset-letter-regex)" as="xs:boolean"/>
              
                <xsl:variable name="char" as="xs:string" 
                              select="if($mark-is-overset-letter)
                                      then concat('{\mathrm{', regex-group(1), '}}')
                                      else concat('{', regex-group(1), '}')"/>
                <xsl:variable name="tex-instr" select="$xml2tex:diacrits//mark[@hex eq $mark]/@tex" as="xs:string*"/>
                <xsl:variable name="is-special-for-href" select="$mark = '&#x301;' and  contains($char, '&#x75;')" as="xs:boolean">
                  <!-- ú has to be quoted three times for hrefs-->
                </xsl:variable>
                <xsl:value-of select="if(string-length($tex-instr) gt 0 and not(matches($context, $texregex)))
                                      then concat('{'[$is-special-for-href], '{', '$'[$mark-is-overset-letter], 
                                                  $tex-instr, 
                                                  $char, 
                                                  '$'[$mark-is-overset-letter], '}', '}'[$is-special-for-href])
                                      else normalize-unicode(.)"/>
                          </xsl:matching-substring>
              <xsl:non-matching-substring>
                <xsl:value-of select="."/>
              </xsl:non-matching-substring>
            </xsl:analyze-string>    
          </xsl:when>
          <!-- simple fractions -->
          <xsl:when test="matches($normalize-unicode-NFKD, $xml2tex:fraction-regex)">
            <xsl:analyze-string select="$normalize-unicode-NFKD" regex="{$xml2tex:fraction-regex}" flags="i">
              <xsl:matching-substring>
                <xsl:variable name="args" select="concat('{', regex-group(1), '}{', regex-group(3), '}')" as="xs:string"/>
                <xsl:variable name="mark" select="'&#x2044;'" as="xs:string"/>
                <xsl:variable name="tex-instr" select="$xml2tex:diacrits//mark[@hex eq $mark]/@tex" as="xs:string*"/>
                <xsl:value-of select="concat('$', $tex-instr, $args, '$')"/>
              </xsl:matching-substring>
              <xsl:non-matching-substring>
                <xsl:value-of select="."/>
              </xsl:non-matching-substring>
            </xsl:analyze-string>
          </xsl:when>
          <xsl:otherwise>
            <xsl:value-of select="."/>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:for-each>
    </xsl:variable>
    <xsl:value-of select="string-join($replace-per-char, '')"/>
  </xsl:function>
  
  <!-- function takes a sequence of characters like and combine 
       character and diacritial mark to one string, e.g.
       ('a', '&#x308;', 'b' ) => ('a&#x308;', 'b')  -->
  
  <xsl:function name="xml2tex:pair-char-and-diacrits" as="xs:string+">
    <xsl:param name="char-seq" as="xs:string+"/>
    <xsl:param name="base-chars-regex" as="xs:string"/>
    <xsl:param name="diacritical-marks-regex" as="xs:string"/>
    <xsl:for-each select="$char-seq">
      <xsl:variable name="pos" select="position()" as="xs:integer"/>
      <xsl:variable name="prev-char" select="$char-seq[$pos - 1]" as="xs:string?"/>
      <xsl:variable name="next-char" select="$char-seq[$pos + 1]" as="xs:string?"/>
      <xsl:variable name="joined" as="xs:string?" 
                    select="if(matches(., $xml2tex:base-chars-regex) and matches($next-char, $diacritical-marks-regex))
                                        then concat(., $next-char)
                                        else .[not(matches(., $diacritical-marks-regex))]"/>
      <xsl:value-of select="$joined"/>
    </xsl:for-each>
  </xsl:function>

  <xsl:variable name="xml2tex:root-regex" select="'([&#x221a;&#x221b;&#x221c;])(\d+)'" as="xs:string"/>
  <xsl:variable name="xml2tex:simpleeq-regex" select="'(\p{L}|\d+([\.,]\d+)*)((\s*[=\-+/]\s*)+(\p{L}|\d+([\.,]\d+)*)){2,}'" as="xs:string"/>

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
    <xsl:choose>
      <!-- simple root -->
      <xsl:when test="matches($string, $xml2tex:root-regex)">
        <xsl:analyze-string select="$string" regex="{$xml2tex:root-regex}" flags="i">
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
      <xsl:when test="matches($string, concat('(^|\p{Zs})', $xml2tex:simpleeq-regex, '($|\p{Zs}|\p{P})'))
        and not(matches($string, '\d{4}(-\d{2}){2}'))
        and not(matches($string, '(\d{2}\.\s?){2}\d{4}'))
        and matches($string, '=')">
        <xsl:analyze-string select="$string" regex="{$xml2tex:simpleeq-regex}" flags="i">
          <xsl:matching-substring>
            <xsl:value-of select="concat('$', ., '$')"/>
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
  
  <xsl:function name="xml2tex:get-delimiters" as="xs:string*">
    <xsl:param name="argument" as="element()"/>
    <xsl:variable name="delimiters" as="xs:string*"  
                  select="     if($argument/local-name() eq 'param')  then ('{', '}')
                          else if($argument/local-name() eq 'option') then ('[', ']')
                          else ()"/>
    <xsl:sequence select="$delimiters"/>
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
  
  <xsl:function name="xml2tex:langs-to-latex-pkg" as="xs:string+">
    <xsl:param name="langs" as="xs:string*"/>
    <xsl:variable name="babel-langs" as="xs:string*"
                  select="distinct-values(for $i in $langs 
                                          return xml2tex:lang-to-babel-lang($i))"/>
    <xsl:if test="$langs = 'es-MX'">
      <xsl:value-of select="'\def\spanishoptions{mexico}'"/>
    </xsl:if>
    <xsl:value-of select="concat('\usepackage[',
                                 string-join(($babel-langs[position() ne 1], 
                                              $babel-langs[1]), (: 1st lang is main lang and comes last :)
                                              ','),
                                 ']{babel}')"/>
    <xsl:if test="$langs = 'zh'">
      <xsl:value-of select="'\usepackage{CJK}'"/>
    </xsl:if>
  </xsl:function>

  <xsl:function name="xml2tex:lang-to-babel-lang" as="xs:string?">
    <xsl:param name="lang" as="xs:string?"/>
    <xsl:value-of select="     if(matches($lang, '^(af|nl)'))       then 'dutch'
                          else if(starts-with($lang, 'ar'))         then 'arabic'
                          else if(starts-with($lang, 'am'))         then 'amharic'
                          else if(starts-with($lang, 'az'))         then 'azerbaijani'
                          else if(starts-with($lang, 'bg'))         then 'bulgarian'
                          else if(starts-with($lang, 'ca'))         then 'catalan'
                          else if(starts-with($lang, 'cs'))         then 'czech'
                          else if(starts-with($lang, 'cy'))         then 'welsh'
                          else if(starts-with($lang, 'da'))         then 'danish'
                          else if($lang eq           'de-CH')       then 'nswissgerman'
                          else if($lang eq           'de-AT')       then 'naustrian'
                          else if(starts-with($lang, 'de'))         then 'ngerman'
                          else if(starts-with($lang, 'el'))         then 'greek'
                          else if($lang eq           'en-GB')       then 'british'
                          else if(starts-with($lang, 'en'))         then 'english'
                          else if(starts-with($lang, 'eo'))         then 'esperanto'
                          else if(starts-with($lang, 'es'))         then 'spanish'
                          else if(starts-with($lang, 'et'))         then 'estonian'
                          else if(starts-with($lang, 'eu'))         then 'basque'
                          else if(starts-with($lang, 'fi'))         then 'finnish'
                          else if(starts-with($lang, 'fr'))         then 'french'
                          else if(starts-with($lang, 'ga'))         then 'irish'
                          else if(starts-with($lang, 'gd'))         then 'scottish'
                          else if(starts-with($lang, 'gl'))         then 'galician'
                          else if(starts-with($lang, 'he'))         then 'hebrew'
                          else if(starts-with($lang, 'hr'))         then 'croatian'
                          else if(starts-with($lang, 'hu'))         then 'magyar'
                          else if(starts-with($lang, 'hy'))         then 'armenian'
                          else if(starts-with($lang, 'ia'))         then 'interlingua'
                          else if(matches($lang, '^(id|ms)'))       then 'bahasa'
                          else if(matches($lang, '^(is|fo)'))       then 'icelandic'
                          else if(starts-with($lang, 'it'))         then 'italian'
                          else if(starts-with($lang, 'jp'))         then 'japanese'
                          else if(starts-with($lang, 'ka'))         then 'georgian'
                          else if(starts-with($lang, 'la'))         then 'latin'
                          else if(matches($lang, '^(no|nb)'))       then 'norsk'
                          else if(starts-with($lang, 'is'))         then 'icelandic'
                          else if(starts-with($lang, 'pl'))         then 'polish'
                          else if(starts-with($lang, 'pt'))         then 'portuguese'
                          else if(starts-with($lang, 'ru'))         then 'russian'
                          else if(starts-with($lang, 'ro'))         then 'romanian'
                          else if(starts-with($lang, 'se'))         then 'samin'
                          else if(starts-with($lang, 'sl'))         then 'slovene'
                          else if(matches($lang, '^(sr|bs|hr|sr)')) then 'serbian'
                          else if(starts-with($lang, 'sk'))         then 'slovak'
                          else if(starts-with($lang, 'sv'))         then 'swedish'
                          else if(starts-with($lang, 'syr'))        then 'syriac'
                          else if(starts-with($lang, 'th'))         then 'thai'
                          else if(starts-with($lang, 'tr'))         then 'turkish'
                          else if(starts-with($lang, 'uk'))         then 'ukrainian'
                          else if(starts-with($lang, 'vi'))         then 'vietnamese'
                          else ()"/>
  </xsl:function>
  
  <xsl:function name="xml2tex:rgb-to-tex-color">
    <xsl:param name="colors" as="xs:string*"/>
    <xsl:variable name="colors-filtered" select="distinct-values($colors)"/>
    <xsl:for-each select="$colors-filtered">
      <xsl:value-of select="concat('color{',        
                                   if(exists(tr:color-hex-rgb-to-keyword(.)))
                                   then tr:color-hex-rgb-to-keyword(.)[1]
                                   else concat('color-', upper-case(substring-after(., '#'))),
                                   '}{rgb}{',
                                   string-join(for $i in tr:hex-rgb-color-to-ints(.) 
                                               return xs:string(round-half-to-even($i div 255, 2)),
                                               ','),
                                  '}')"/>
    </xsl:for-each>
  </xsl:function>

</xsl:stylesheet>
