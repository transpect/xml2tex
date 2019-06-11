<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet 
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:xs="http://www.w3.org/2001/XMLSchema"
  xmlns:xlink="http://www.w3.org/1999/xlink"
  xmlns:xml2tex="http://transpect.io/xml2tex"
  xmlns:c="http://www.w3.org/ns/xproc-step"
  xmlns:functx="http://www.functx.com"
  xmlns:xso="tobereplaced" 
  version="2.0">
  
  <xsl:import href="http://transpect.io/xslt-util/functx/xsl/functx.xsl"/>
  <xsl:import href="functions.xsl"/>

  <xsl:namespace-alias stylesheet-prefix="xso" result-prefix="xsl"/>

  <xsl:output method="xml" media-type="text/xml" indent="yes" encoding="UTF-8"/>
  
  <xsl:param name="debug" select="'no'"/>
  <xsl:param name="debug-dir-uri" select="'debug'"/>
  <!-- output only tex body without preamble, \begin{document} and \end{document} -->
  <xsl:param name="only-tex-body" select="'no'"/>
  
  <xsl:include href="handle-namespace.xsl"/>

  <xsl:template match="/xml2tex:set">
        
    <!--  *
          * Generate XSLT from mapping instructions. 
          * -->
    
    <xso:stylesheet xmlns:xs="http://www.w3.org/2001/XMLSchema"
                    xmlns:xlink="http://www.w3.org/1999/xlink"
                    xmlns:tex="http://www-cs-faculty.st anford.edu/~uno/"
                    xmlns:html="http://www.w3c.org/1999/xhtml"
                    xmlns:c="http://www.w3.org/ns/xproc-step"
                    xmlns:xso="tobereplaced">
      
      <xsl:apply-templates select="xml2tex:ns"/>
      
      <xsl:attribute name="version">2.0</xsl:attribute>

      <xso:import href="http://transpect.io/xslt-util/functx/xsl/functx.xsl"/>
      <xso:import href="http://transpect.io/xml2tex/xsl/functions.xsl"/>

      <xsl:apply-templates select="xsl:import, xsl:param, xsl:key"/>

      <xso:output method="text" media-type="text/plain" encoding="UTF8"/>

      <xsl:apply-templates select="xsl:* except (xsl:import|xsl:param|xsl:key)"/>

      <xso:template match="/" mode="apply-xpath">
        <!-- The c:data-section is necessary for XProc text output. -->
        <c:data content-type="text/plain">
          <xsl:if test="$only-tex-body eq 'no'">
            <xsl:apply-templates select="xml2tex:preamble"/>
            <xso:text>&#xa;\begin{document}&#xa;</xso:text>  
          </xsl:if>
          <xsl:apply-templates select="xml2tex:front"/>
          <xso:apply-templates mode="#current"/>
          <xsl:apply-templates select="xml2tex:back"/>
          <xsl:if test="$only-tex-body eq 'no'">
            <xso:text>&#xa;\end{document}&#xa;</xso:text>
          </xsl:if>
        </c:data>
      </xso:template>
      
      <!-- mode variables for generated stylesheet -->
      
      <xsl:comment select="'mode variables'"/>
      
      <xso:variable name="escape-bad-chars">
        <xso:apply-templates select="root()" mode="escape-bad-chars"/>
      </xso:variable>

      <xso:variable name="apply-regex">
        <xso:apply-templates select="$escape-bad-chars" mode="apply-regex"/>
      </xso:variable>

      <xso:variable name="replace-chars">
        <xso:apply-templates select="$apply-regex" mode="replace-chars"/>
      </xso:variable>

      <xso:variable name="dissolve-pi">
        <xso:apply-templates select="$replace-chars" mode="dissolve-pi"/>
      </xso:variable>

      <xso:variable name="apply-xpath">
        <xso:apply-templates select="$dissolve-pi" mode="apply-xpath"/>
      </xso:variable>
      
      <xso:variable name="clean">
        <xso:apply-templates select="$apply-xpath" mode="clean"/>
      </xso:variable>

      <!-- main template for generated stylesheet -->
      <xsl:comment select="'main template, invoke with it:main'"/>

      <xso:template name="main">
        <xso:sequence select="$clean"/>
        <!-- debugging -->
        <xso:if test="{$debug eq 'yes'}()">
          <xso:result-document href="{$debug-dir-uri}/xml2tex/00_escape-bad-chars.xml" indent="yes" method="xml">
            <xso:sequence select="$escape-bad-chars"/>
          </xso:result-document>
          <xso:result-document href="{$debug-dir-uri}/xml2tex/05_apply-regex.xml" indent="yes" method="text">
            <xso:sequence select="$apply-regex"/>
          </xso:result-document>
          <xso:result-document href="{$debug-dir-uri}/xml2tex/10_replace-chars.xml" indent="yes" method="xml">
            <xso:sequence select="$replace-chars"/>
          </xso:result-document>
          <xso:result-document href="{$debug-dir-uri}/xml2tex/15_dissolve-pi.xml" indent="yes" method="xml">
            <xso:sequence select="$dissolve-pi"/>
          </xso:result-document>
          <xso:result-document href="{$debug-dir-uri}/xml2tex/20_apply-xpath.xml" indent="yes" method="xml">
            <xso:sequence select="$apply-xpath"/>
          </xso:result-document>
          <xso:result-document href="{$debug-dir-uri}/xml2tex/25_clean.xml" indent="yes" method="xml">
            <xso:sequence select="$clean"/>
          </xso:result-document>
        </xso:if>
      </xso:template>

      <!-- identity template for generated stylesheet -->
      <xsl:comment select="'identity template'"/>

      <xso:template match="@* | node()" mode="#all" priority="-10">
        <xso:copy>
          <xso:apply-templates select="@*, node()" mode="#current"/>
        </xso:copy>
      </xso:template>
      
      <!-- templates, generated from conf file -->
      <xsl:comment select="'template section'"/>

      <!-- escape bad chars, necessary for tex commands -->
      <xso:template match="text()" mode="escape-bad-chars">
        <xso:variable name="content" select="xml2tex:escape-for-tex(replace( ., '\\', '\\textbackslash ' ))" as="xs:string"/>
        <xso:value-of select="$content"/>
      </xso:template>

      <!-- apply regex from conf file -->
      <xso:template match="text()" mode="apply-regex">
        <xso:variable name="content" select="." as="xs:string"/>
        <xsl:for-each select="xml2tex:regex">
          <xsl:variable name="pattern" select="concat('''', @regex, '''')" as="xs:string"/>
          <xsl:variable name="delimiters"
            select="if(xml2tex:rule/@type eq 'cmd') then (concat('\', xml2tex:rule/@name), '')
               else if(xml2tex:rule/@type eq 'env') then (concat('\begin{', xml2tex:rule/@name, '}'), 
                                                          concat('\end{',   xml2tex:rule/@name, '}'))
               else                                       ''" as="xs:string*"/>
          <xsl:variable name="replace" select="string-join(('''',
                                                            for $i in xml2tex:rule/* 
                                                            return (if($i/@name) then concat('''\\', $i/@name) else '',
                                                                    xml2tex:get-delimiter($i/local-name(), true()),
                                                                    if($i/@regex-group) 
                                                                    then concat('$', $i/@regex-group)
                                                                    else (replace($i/@select, '^['']?(.+?)['']?$', '$1'), $i/text())[1],
                                                                    xml2tex:get-delimiter($i/local-name(), false())),
                                                            ''''), '')" as="xs:string*"/>
          <xso:variable name="content" select="replace($content, 
                                                       {$pattern}, 
                                                       {replace($replace, '([\\$])', '\\$1')})" as="xs:string"/>
        </xsl:for-each>
        <xso:value-of select="$content"/>
      </xso:template>
      
      <xso:template match="processing-instruction()" mode="clean"/>
      
      <xso:template match="text()" mode="clean">
        <xso:variable name="normalize-linebreaks" select="replace(., '\n\n\n+', '&#xa;&#xa;', 'm')" as="xs:string"/>        
        <xso:value-of select="$normalize-linebreaks"/>
      </xso:template>
      
      <!-- dissolve pis created by calstable-normalize -->
      <xso:template match="processing-instruction('cals2tabular')
                          |processing-instruction('mml2tex')
                          |processing-instruction('latex')
                          |processing-instruction('mathtype')" mode="dissolve-pi">
        <xso:value-of select="replace(., '\s\s+', ' ')"/>
      </xso:template>
            
      <!-- dissolve elements which are not matched by other templates -->
      
      <xso:template match="*" mode="apply-xpath">
        <xso:apply-templates mode="#current"/>
      </xso:template>
      
      <xsl:apply-templates select="xml2tex:* except (xml2tex:ns, xml2tex:preamble, xml2tex:front, xml2tex:back)"/>
      
      <xsl:call-template name="replace-chars-mode"/>

    </xso:stylesheet>
  </xsl:template>

  <!-- create namespace nodes -->
  <xsl:template match="xml2tex:ns">
    <!-- the code is taken from the schematron project. for information please visit this url
         https://code.google.com/p/schematron/  -->
    <xsl:call-template name="handle-namespace"/>
  </xsl:template>

  <xsl:template match="xml2tex:preamble|xml2tex:front|xml2tex:back">
    <xsl:apply-templates mode="fixed-sections"/>
  </xsl:template>
  
  <xsl:template match="*" mode="fixed-sections">
    <xsl:copy>
      <xsl:apply-templates select="@*, node()" mode="#default"/>
    </xsl:copy>
  </xsl:template>
  
  <!-- replace leading whitespace in fixed sections -->
  
  <xsl:template match="text()" mode="fixed-sections">
    <xsl:variable name="split-lines" select="tokenize(., '&#xa;')" as="xs:string*"/>
    <xsl:for-each select="$split-lines[normalize-space(.)]">
      <xso:text><xsl:value-of select="replace(., '\s*(.+)', '$1'), '&#xa;'"/></xso:text>
    </xsl:for-each>
    <xsl:text>&#xa;</xsl:text>
  </xsl:template>
  
  <xsl:variable name="rule-indexes" select="for $i in //xml2tex:template return generate-id($i)" as="xs:string*"/>
  
  <xsl:template match="xml2tex:template">
    <!--  * the priority of a rule is determined by its order. If more than one 
          * rule matches against a particular element, the last rule declaration has a higher priority
          * and overwrites the rule with a lesser priority. Imported templates have always the priority 1.
          * -->
    <xsl:variable name="template-priority" select="(index-of($rule-indexes, generate-id(.)), 1)[1]" as="xs:integer"/>

    <xso:template match="{@context}" mode="apply-xpath" priority="{$template-priority}">
      <!-- if no tex child is present, then matched node will be discarded -->
      <xsl:apply-templates/>
    </xso:template>

    <!--  *
          * set '$' around content and remove dollar characters within to prevent nested math mode sections 
          * -->
    <xsl:if test="xml2tex:rule/@mathmode eq 'true'">
      <xso:template match="{string-join(for $i in tokenize(@context, '\|') 
                                        return concat($i, '/text()'),
                                        '|')}" mode="dissolve-pi" priority="{$template-priority}">
        <xso:analyze-string select="." regex="\\\$">
          <xso:matching-substring>
            <xso:value-of select="."/>
          </xso:matching-substring>
          <xso:non-matching-substring>
            <xso:value-of select="replace(., '\$', '')"/>
          </xso:non-matching-substring>
        </xso:analyze-string>
      </xso:template>
    </xsl:if>

  </xsl:template>

  <xsl:template match="xml2tex:regex/xml2tex:rule"/>
  
  <xsl:variable name="style-attribute" select="/xml2tex:set/@style-attribute" as="attribute(style-attribute)?"/>
  
  <xsl:template match="xml2tex:style">
    <xsl:variable name="template-priority" select="count($rule-indexes) + position()" as="xs:integer"/>
    <xso:template match="*[@{$style-attribute} eq '{@name}']" 
                  mode="apply-xpath" priority="{$template-priority}">
      <xso:value-of select="'{@start}'"/>
      <xso:apply-templates mode="#current"/>
      <xso:value-of select="'{@end}'"/>
    </xso:template>
  </xsl:template>

  <xsl:template match="xml2tex:template/xml2tex:file">
    <c:data href="{@href}" method="text" content-type="text/plain"
            encoding="{(@encoding, 'utf-8')[1]}">
      <xsl:choose>
        <xsl:when test="not(node())">
          <xso:apply-templates mode="#current"/>    
        </xsl:when>
        <xsl:otherwise>
          <xsl:apply-templates select="xsl:*"/>
        </xsl:otherwise>
      </xsl:choose>
    </c:data>
  </xsl:template>

  <xsl:template match="xml2tex:template/xml2tex:rule">
    <xsl:variable name="rule" select="." as="element(xml2tex:rule)"/>
      <!-- three types: 
            env   ==> environment, eg. e.g. begin{bla} ... end{bla}
            cmd   ==> commands, e.g. \bla ...
            none  ==> no tex markup, needed for simple paras or other stuff you want to simply tunnel through the process -->
    <xsl:variable name="opening-tag" 
                  select="concat(if($rule/@break-before) then string-join(for $i in (1 to $rule/@break-before) return '&#xa;', '') else '',
                                 if($rule/@type eq 'env' and matches($rule/@name, 'table|tabular|figure')) 
                                   then concat('&#xa;\begin{',$rule/@name,'}')
                            else if($rule/@type eq 'env' and not(matches($rule/@name, 'table|tabular|figure')) and *[1][self::xml2tex:text]) 
                                   then concat('&#xa;\begin{',$rule/@name,'}&#xa;')  
                            else if($rule/@type eq 'env' and not(matches($rule/@name, 'table|tabular|figure'))) 
                                   then concat('&#xa;\begin{',$rule/@name,'}')
                            else if(not($rule/@type)) 
                                   then ''
                            else        concat('\', $rule/@name),
                                 if($rule/@mathmode eq 'true') then '$' else ''
                                 )" as="xs:string"/>
    <xsl:variable name="closing-tag" select="concat(if($rule/@mathmode eq 'true') then '$' else '',
                                                    if($rule/@type eq 'env') then concat('&#xa;\end{',$rule/@name,'}&#xa;') else '',
                                                    if($rule/@break-after) then string-join(for $i in (1 to $rule/@break-after) return '&#xa;', '') else ''
                                                    )" as="xs:string"/>
    <xso:variable name="opening-tag" select="{concat('''', $opening-tag, '''')}"/>
    <xso:variable name="closing-tag" select="{concat('''', $closing-tag, '''')}"/>
    <xso:value-of select="$opening-tag"/>
    <xsl:apply-templates/>
    <xso:value-of select="$closing-tag"/>
  </xsl:template>
  
  <xsl:template match="xsl:*|@*" priority="100">
    <xsl:copy>
      <xsl:apply-templates select="@*, node()"/>
    </xsl:copy>
  </xsl:template>

  <xsl:template match="xml2tex:option|xml2tex:param|xml2tex:text">
    <!-- types: text | param | option -->
    <xso:variable name="opening-delimiter" select="{concat('''', xml2tex:get-delimiter(local-name(), true()), '''')}"/>
    <xso:variable name="closing-delimiter" select="{concat('''', xml2tex:get-delimiter(local-name(), false()), '''')}"/>
      <xsl:choose>
        <!--  *
              * select attribute exists either in text/option/param tag
              * -->
        <xsl:when test="@select">
          <xso:value-of select="$opening-delimiter"/>
          <xso:choose>
            <!--  handle elements -->
            <xso:when test="({@select}) instance of element()">
              <xso:apply-templates select="if(({@select}) instance of element()) then ({@select}) else node()" mode="#current"/>
            </xso:when>
            <!--  * handle node() function used in select attributes -->
            <xso:when test="not(({@select}) instance of item())">
              <xso:apply-templates select="if(not(({@select}) instance of item())) then ({@select}) else node()" mode="#current"/>
            </xso:when>
            <!--  fallback: handle as simple text -->
            <xso:otherwise>
              <xso:value-of select="{@select}"/>
            </xso:otherwise>
          </xso:choose>
          <xso:value-of select="$closing-delimiter"/>
        </xsl:when>
        <!--  *
              * regex attribute exists either in text/option/param tag
              * -->
        <xsl:when test="@regex">
          <xso:analyze-string select="." regex="{@regex}">
            <xso:matching-substring>
              <xso:value-of select="$opening-delimiter"/>
              <xso:value-of select="{if( @regex-group) then concat('regex-group(', @regex-group, ')') else '.'}"/>
              <xso:value-of select="$closing-delimiter"/>
            </xso:matching-substring>
          </xso:analyze-string>
        </xsl:when>
        <!--  *
              * text/option/param tag contains static text
              * -->
        <xsl:when test="text()">
          <xso:value-of select="$opening-delimiter"/>
          <xso:value-of select="{concat('''', text(), '''')}"/>
          <xso:value-of select="$closing-delimiter"/>
        </xsl:when>
        <!--  *
              * fallback for anything
              * -->
        <xsl:otherwise>
          <xso:value-of select="$opening-delimiter"/>
          <xso:choose>
            <xso:when test="(.) instance of element()">
              <xso:apply-templates mode="#current"/>
            </xso:when>
            <xso:otherwise>
              <xso:value-of select="."/>
            </xso:otherwise>
          </xso:choose>
          <xso:value-of select="$closing-delimiter"/>
        </xsl:otherwise>
      </xsl:choose>
  </xsl:template>

  <!-- mode replace-chars -->
  
  <xsl:template name="replace-chars-mode">
        
    <xso:variable name="texregex" select="{concat('''', 
                                                  if(/xml2tex:set/xml2tex:charmap//xml2tex:char)
                                                  then concat('([', 
                                                              string-join(for $ i in /xml2tex:set/xml2tex:charmap//xml2tex:char
                                                                          return functx:escape-for-regex(normalize-space($i/@character)),
                                                                          ''),
                                                              '])')
                                                  else '',
                                                  '''')}" as="xs:string"/>

      <xso:variable name="charmap" as="element(xml2tex:char)*">
        <xsl:for-each select="//xml2tex:char">
          <xml2tex:char>
            <xsl:copy-of select="@context"/>
            <xml2tex:character><xsl:value-of select="@character"/></xml2tex:character>
            <xml2tex:string><xsl:value-of select="@string"/></xml2tex:string>
          </xml2tex:char>
        </xsl:for-each>
      </xso:variable>
      
      <!-- replacement with xpath context -->
    <xso:template match="text()" mode="replace-chars">
      <!-- this function needs to run before any character mapping, because of roots e.g. -->
      <xso:variable name="simplemath" select="normalize-unicode(string-join(xml2tex:convert-simplemath(.), ''))" as="xs:string"/>
      <!-- maps unicode to latex -->
      <xsl:choose>
        <xsl:when test="/xml2tex:set/xml2tex:charmap">
          <xso:variable name="utf2tex" select="if(matches($simplemath, $texregex)) 
                                               then string-join(xml2tex:utf2tex(.., $simplemath, $charmap, (), $texregex), '') 
                                               else $simplemath" as="xs:string"/>
        </xsl:when>
        <xsl:otherwise>
          <xso:variable name="utf2tex" select="$simplemath" as="xs:string"/>
        </xsl:otherwise>
      </xsl:choose>
      <!-- has to run last because it resolves combined unicode characters -->
      <xso:variable name="diacrits" select="string-join(xml2tex:convert-diacrits($utf2tex, $texregex), '')" as="xs:string"/>
      <xso:value-of select="$diacrits"/>
    </xso:template>
    
    <xso:template match="text()" mode="char-context"/>
    
    <xso:template match="*" mode="char-context" as="xs:string?" priority="-1"/>
    
    <xso:template match="/" mode="char-context" as="xs:string?" priority="-1"/>
    
    <xsl:for-each-group select="/xml2tex:set/xml2tex:charmap//xml2tex:char[normalize-space(@context)]" 
                        group-by="normalize-space(@context)">
      <xso:template match="{@context}" mode="char-context" as="xs:string?"><!-- priority="{xml2tex:index-of(../xml2tex:char, .)}" -->
        <xso:param name="char-in-doc" as="xs:string?"/>
        <xso:choose>
          <xsl:for-each select="current-group()">
            <xso:when test="$char-in-doc = '{@character}'">
              <xso:sequence select="'{@string}'"/>
            </xso:when>
          </xsl:for-each>  
        </xso:choose>
      </xso:template>
    </xsl:for-each-group>
    
  </xsl:template>

</xsl:stylesheet>
