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
  
  <xsl:import href="http://transpect.io/xslt-util/functx/Strings/Replacing/escape-for-regex.xsl"/>

  <xsl:namespace-alias stylesheet-prefix="xso" result-prefix="xsl"/>

  <xsl:output method="xml" media-type="text/xml" indent="yes" encoding="UTF-8"/>
  
  <xsl:param name="debug" select="'no'"/>
  <xsl:param name="debug-dir-uri" select="'debug'"/>
  
  <xsl:include href="handle-namespace.xsl"/>

  <xsl:template match="/xml2tex:set">
    
    <!--  *
          * Console output for debugging purposes 
          * -->
    
    <xsl:variable name="convert-node-list" 
      select="for $i in xml2tex:template return 
            if($i/xml2tex:rule) 
                then concat('CONVERT ', $i/@context, ' TO ', $i/xml2tex:rule/@name, '&#xa;') 
                else concat('DISCARD ', $i/@context, '&#xa;')"/>
    <xsl:variable name="replace-char-list" 
      select="for $i in xml2tex:charmap/xml2tex:char return concat('REPLACE ', $i/@character, ' WITH ', $i/@string, 
            if($i/@context) then concat(' ONLY IN ', $i/@context) else ''
            , '&#xa;')"/>
    <xsl:variable name="regex-list" select="for $i in xml2tex:regex return concat('REPLACE PATTERN ', $i/@regex, ' WITH ', $i/xml2tex:rule/@name, '&#xa;')"/>
    
    <xsl:message select="'&#xa;', $convert-node-list, $replace-char-list, $regex-list"/>
    
    <!--  *
          * Generate XSLT from mapping instructions. 
          * -->
    
    <xso:stylesheet
      xmlns:xs="http://www.w3.org/2001/XMLSchema"
      xmlns:xlink="http://www.w3.org/1999/xlink"
      xmlns:tex="http://www-cs-faculty.st anford.edu/~uno/"
      xmlns:c="http://www.w3.org/ns/xproc-step"
      xmlns:xso="tobereplaced">
      
      <xsl:apply-templates select="xml2tex:ns"/>
      
      <xsl:attribute name="version">2.0</xsl:attribute>

      <xso:import href="http://transpect.io/xslt-util/functx/Strings/Replacing/escape-for-regex.xsl"/>

      <xso:output method="text" media-type="text/plain" encoding="UTF8"/>

      <xso:template match="/" mode="apply-xpath">
        <!-- The c:data-section is necessary for XProc text output. -->
        <c:data content-type="text/plain">
          <xsl:if test="/xml2tex:set/xml2tex:preamble">
            <xsl:variable name="split-lines" select="tokenize(/xml2tex:set/xml2tex:preamble, '&#xa;')" as="xs:string*"/>
            <xsl:for-each select="$split-lines[not(matches(., '^[\s\n]$'))]">
              <xso:text><xsl:value-of select="replace(., '\s*(.+)', '$1'), '&#xa;'"/></xso:text>
            </xsl:for-each>
          </xsl:if>
          <xso:text>\begin{document}&#xa;</xso:text>
          <xso:apply-templates mode="#current"/>
          <xso:text>&#xa;\end{document}&#xa;</xso:text>
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

      <!-- main template for generated stylesheet -->
      <xsl:comment select="'main template, invoke with it:main'"/>

      <xso:template name="main">
        <xso:sequence select="$apply-xpath"/>
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
          <xsl:variable name="opening-delimiter"
            select="if(@type eq 'option') then '[' 
              else if (@type eq 'text') then ''
              else '{'"/>
          <xsl:variable name="pattern" select="concat('''', @regex, '''')" as="xs:string"/>
          <xsl:variable name="regex-groups" 
            select="string-join(
                            for $i in xml2tex:rule/* return concat(
                            if($i/local-name() eq 'option') then '[' else if ($i/local-name() eq 'text') then '' else'{' ,
                                '$',
                                $i/@regex-group,
                                if($i/local-name() eq 'option') then ']' else if ($i/local-name() eq 'text') then '' else'}' 
                            ),
                            '')" as="xs:string"/>
          <xsl:variable name="replace" select="concat('''', '\\', xml2tex:rule/@name , $regex-groups, '''')" as="xs:string"/>
          <xso:variable name="content" select="replace( $content, {$pattern}, {$replace} )" as="xs:string"/>
        </xsl:for-each>
        <xso:value-of select="$content"/>
      </xso:template>
      
      <!-- dissolve pis created by calstable-normalize -->
      <xso:template match="processing-instruction('cals2tabular')
        |processing-instruction('mml2tex')
        |processing-instruction('mathtype')
        |processing-instruction('latex')" mode="dissolve-pi">
        <xso:value-of select="replace(., '\s\s+', ' ')"/>
      </xso:template>
      
      <xsl:apply-templates select="*[not(self::xml2tex:ns)]"/>

    </xso:stylesheet>
  </xsl:template>


  <!-- create namespace nodes -->
  <xsl:template match="xml2tex:ns">
    <!-- the code is taken from the schematron project. for information please visit this url
         https://code.google.com/p/schematron/  -->
    <xsl:call-template name="handle-namespace"/>
  </xsl:template>

  <!-- mode apply-xpath -->

  <xsl:template match="xml2tex:preamble"/>
  
  <xsl:variable name="rule-indexes" select="for $i in //xml2tex:template return generate-id($i)" as="xs:string*"/>
  
  <xsl:template match="xml2tex:template">
    <!-- the priority of a rule is determined by its order. If more than one 
      rule matches against a particular element, the last rule declaration has a higher priority
      and overwrites the rule with a lesser priority.
    -->
    <xsl:variable name="template-priority" select="index-of($rule-indexes, generate-id(.))"/>

    <xso:template match="{@context}" mode="apply-xpath" priority="{$template-priority}">
      <xso:copy>
        <xso:apply-templates select="@*"/>
        <xsl:if test="@mathmode eq 'true'">
          <xso:text>$</xso:text>
        </xsl:if>
        <!-- if no tex child is present, then matched node will be discarded -->
          <xsl:for-each select="xml2tex:rule">
            <!-- three types: 
                env   ==> environment, eg. e.g. begin{bla} ... end{bla}
                cmd   ==> commands, e.g. \bla ...
                none  ==> no tex markup, needed for simple paras or other stuff you want to simply tunnel through the process -->
            <xsl:variable name="opening-tag" 
              select="if(@type eq 'env' and matches(@name, 'table|tabular|figure')) then concat('&#xa;\begin{',@name,'}')
                 else if(@type eq 'env' and not(matches(@name, 'table|tabular|figure'))) then concat('&#xa;\begin{',@name,'}&#xa;')
                 else if(not(@type)) then ''
                 else concat( '\', @name )"/>
            <xsl:variable name="closing-tag"
              select="concat(if(@type eq 'env') then concat('&#xa;\end{',@name,'}&#xa;') else '',
                if(@break-after) then string-join(for $i in (1 to @break-after) return '&#xa;', '') else '')"/>
            <xso:variable name="opening-tag" select="{concat('''', $opening-tag, '''')}"/>
            <xso:variable name="closing-tag" select="{concat('''', $closing-tag, '''')}"/>
            <xso:value-of select="$opening-tag"/>
            <xsl:sequence select="xml2tex:generate-content(*)"/>
            <xso:value-of select="$closing-tag"/>
          </xsl:for-each>
        <xsl:if test="@mathmode eq 'true'">
          <xso:text>$</xso:text>
        </xsl:if>
      </xso:copy>
    </xso:template>
    
    <!--  *
          * set '$' around content and remove dollar characters within to prevent nested math mode sections 
          * -->
    <xsl:if test="@mathmode eq 'true'">
      <xso:template match="{@context}/text()" mode="dissolve-pi" priority="{$template-priority}">
        <xso:analyze-string select="." regex="\\\$">
          <xso:matching-substring>
            <xso:message select="."/>
            <xso:value-of select="."/>
          </xso:matching-substring>
          <xso:non-matching-substring>
            <xso:value-of select="replace(., '\$', '')"/>
          </xso:non-matching-substring>
        </xso:analyze-string>
      </xso:template>
    </xsl:if>

  </xsl:template>

  <xsl:function name="xml2tex:generate-content">
    <xsl:param name="elements" as="node()*"/>
    <xsl:for-each select="$elements">
      <!-- types: text | param | option -->
      <xsl:variable name="type" select="local-name()"/>
      <xso:variable name="type" select="{concat('''', $type, '''')}"/>
        <xsl:variable name="opening-delimiter"
          select="if($type eq 'option') then '[' 
          else if ($type eq 'text') then '' 
          else '{'"/>
        <xsl:variable name="closing-delimiter"
          select="if($type eq 'option') then ']' 
          else if ($type eq 'text') then ''  
          else '}'"/>
        <xso:variable name="opening-delimiter" select="{concat('''', $opening-delimiter, '''')}"/>
        <xso:variable name="closing-delimiter" select="{concat('''', $closing-delimiter, '''')}"/>
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
            <xso:value-of select="{concat('''', text(), '''')}"/>
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
    </xsl:for-each>
  </xsl:function>

  <!-- mode replace-chars -->

  <xsl:template match="xml2tex:charmap">
    
    <xso:variable name="texregex" select="{concat('''', '([', string-join(for $ i in //xml2tex:char/@character return functx:escape-for-regex($i), ''), '])', '''')}" as="xs:string"/>
    
    <xso:variable name="charmap" as="element(xml2tex:char)+">
      <xsl:for-each select="xml2tex:char">
        <xml2tex:char>
          <xml2tex:character><xsl:value-of select="@character"/></xml2tex:character>
          <xml2tex:string><xsl:value-of select="@string"/></xml2tex:string>
        </xml2tex:char>
      </xsl:for-each>
    </xso:variable>
        
    <!-- replacement with xpath context -->
    <xso:template match="text()" mode="replace-chars">
      <xso:value-of select="xml2tex:convert-diacrits(string-join(
                                        if(matches(., $texregex)) then xml2tex:utf2tex(., $charmap, ()) else .,
                                        ''))"/>
    </xso:template>
    
    <xso:function name="xml2tex:utf2tex" as="xs:string+">
      <xso:param name="string" as="xs:string"/>
      <xso:param name="charmap" as="element(xml2tex:char)+"/>
      <xso:param name="seen" as="xs:string*"/>
      
      <xso:analyze-string select="$string" regex="{{$texregex}}">
        <xso:matching-substring>      
          <xso:variable name="pattern" select="functx:escape-for-regex(regex-group(1))" as="xs:string"/>
          <xso:variable name="replacement" select="replace($charmap[xml2tex:character = regex-group(1)][1]/xml2tex:string, '([\$\\])', '\\$1')" as="xs:string"/>
          <xso:variable name="result" select="replace(., $pattern, $replacement)" as="xs:string"/>
          <xso:variable name="seen" select="concat($seen, $pattern)" as="xs:string"/>
          <xso:choose>
            <xso:when test="matches($result, $texregex)
                            and not(($pattern = $seen) or matches($result, '^[a-z0-9A-Z\$\\%_&amp;\{{\}}\[\]#\|]+$'))">
              <xso:value-of select="string-join(xml2tex:utf2tex($result, $charmap, ($seen, $pattern)), '')"/>
            </xso:when>
            <xso:otherwise>
              <xso:value-of select="$result"/>
            </xso:otherwise>
          </xso:choose>
        </xso:matching-substring>
        <xso:non-matching-substring>
          <xso:value-of select="."/>
        </xso:non-matching-substring>
      </xso:analyze-string>
    </xso:function>
    
    <xso:function name="xml2tex:convert-diacrits" as="xs:string+">
      <xso:param name="string" as="xs:string"/>
      <xso:variable name="map" as="element(map)">
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
        </map>
      </xso:variable>
      <!-- decompose diacritical marks -->
      <xso:analyze-string select="normalize-unicode($string, 'NFKD')" regex="([a-z])([&#x300;-&#x36F;])" flags="i">
        <xso:matching-substring>
          <xso:variable name="char" select="concat('{{', regex-group(1), '}}')"/>
          <xso:variable name="mark" select="regex-group(2)"/>
          <xso:variable name="tex-instr" select="$map//mark[@hex eq $mark]/@tex" as="xs:string*"/>
          <xso:value-of select="if(string-length($tex-instr) gt 0)
                                then concat($tex-instr, $char)
                                else ."/>
        </xso:matching-substring>
        <xso:non-matching-substring>
          <xso:value-of select="."/>
        </xso:non-matching-substring>
      </xso:analyze-string>
    </xso:function>
    
    <xso:function name="xml2tex:escape-for-tex" as="xs:string">
      <xso:param name="string" as="xs:string"/>
      <xso:value-of select="replace( $string, '(\{{|\}}|%|_|&amp;|\$|#)', '\\$1' )"/>
    </xso:function>

  </xsl:template>
  
</xsl:stylesheet>
