<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet 
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:xs="http://www.w3.org/2001/XMLSchema"
  xmlns:xlink="http://www.w3.org/1999/xlink"
  xmlns:xml2tex="http://transpect.io/xml2tex"
  xmlns:c="http://www.w3.org/ns/xproc-step"
  xmlns:xso="tobereplaced" 
  version="2.0">

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

      <xso:output method="text" media-type="text/plain" encoding="UTF8"/>

      <xso:template match="/" mode="apply-xpath">
        <!-- The c:data-section is necessary for XProc text output. -->
        <c:data content-type="text/plain">
          <xsl:if test="/xml2tex:set/xml2tex:preamble">
            <xsl:variable name="split-lines" select="tokenize(/xml2tex:set/xml2tex:preamble, '&#xa;')"/>
            <xsl:for-each select="$split-lines[. ne '']">
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

      <xso:variable name="replace-chars-specific">
        <xso:apply-templates select="$apply-regex" mode="replace-chars-specific"/>
      </xso:variable>

      <xso:variable name="replace-chars-general">
        <xso:apply-templates select="$replace-chars-specific" mode="replace-chars-general"/>
      </xso:variable>

      <xso:variable name="dissolve-pi">
        <xso:apply-templates select="$replace-chars-general" mode="dissolve-pi"/>
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
          <xso:result-document href="{$debug-dir-uri}/hub2tex/00_escape-bad-chars.xml" indent="yes" method="xml">
            <xso:sequence select="$escape-bad-chars"/>
          </xso:result-document>
          <xso:result-document href="{$debug-dir-uri}/hub2tex/05_apply-regex.xml" indent="yes" method="text">
            <xso:sequence select="$apply-regex"/>
          </xso:result-document>
          <xso:result-document href="{$debug-dir-uri}/hub2tex/10_replace-chars-specific.xml" indent="yes" method="xml">
            <xso:sequence select="$replace-chars-specific"/>
          </xso:result-document>
          <xso:result-document href="{$debug-dir-uri}/hub2tex/15_replace-chars-general.xml" indent="yes" method="xml">
            <xso:sequence select="$replace-chars-general"/>
          </xso:result-document>
          <xso:result-document href="{$debug-dir-uri}/hub2tex/20_dissolve-pi.xml" indent="yes" method="xml">
            <xso:sequence select="$dissolve-pi"/>
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
        <xso:variable name="content" select="replace( ., '(%|_|&amp;)', '\\$1' )"/>
        <xso:variable name="content" select="replace( $content, '\{{', '\\{{' )"/>
        <xso:variable name="content" select="replace( $content, '\}}', '\\}}' )"/>
        <xso:value-of select="$content"/>
      </xso:template>

      <!-- apply regex from conf file -->
      <xso:template match="text()" mode="apply-regex">
        <xso:variable name="content" select="."/>
        <xsl:for-each select="xml2tex:regex">
          <xsl:variable name="opening-delimiter"
            select="if(@type eq 'option') then '[' 
              else if (@type eq 'text') then ''
              else '{'"/>
          <xsl:variable name="pattern" select="concat('''', @regex, '''')"/>
          <xsl:variable name="regex-groups" 
            select="string-join(
                            for $i in xml2tex:rule/* return concat(
                            if($i/local-name() eq 'option') then '[' else if ($i/local-name() eq 'text') then '' else'{' ,
                                '$',
                                $i/@regex-group,
                                if($i/local-name() eq 'option') then ']' else if ($i/local-name() eq 'text') then '' else'}' 
                            ),
                        '')"/>
          <xsl:variable name="replace" select="concat('''', '\\', xml2tex:rule/@name , $regex-groups, '''')"/>
          <xso:variable name="content" select="replace( $content, {$pattern}, {$replace} )"/>
        </xsl:for-each>
        <xso:value-of select="$content"/>
      </xso:template>
      
      <!-- dissolve pis created by calstable-normalize -->
      <xso:template match="processing-instruction('cals2tabular')" mode="dissolve-pi">
        <xso:value-of select="."/>
      </xso:template>
      
      <!-- dissolve pis of  mml2tex equations -->
      <xso:template match="processing-instruction('mml2tex')" mode="dissolve-pi">
        <xso:value-of select="."/>
      </xso:template>
      
      <xso:template match="processing-instruction('mathtype')" mode="dissolve-pi">
        <xso:value-of select="."/>
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
      <!-- if no tex child is present, then matched node will be discarded -->
      <xsl:for-each select="xml2tex:rule">
        <!-- three types: 
            env   ==> environment, eg. e.g. begin{bla} ... end{bla}
            cmd   ==> commands, e.g. \bla ...
            none  ==> no tex markup, needed for simple paras or other stuff you want to simply tunnel through the process -->
        <xsl:variable name="opening-tag" 
          select="if(@type eq 'env') then concat('&#xa;\begin{',@name,'}')
            else if (not(@type)) then ''
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
    </xso:template>

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
          <xsl:when test="@select">
            <xso:value-of select="$opening-delimiter"/>
            <xso:choose>
              <!--  *
                    * handle elements
                    * -->
              <xso:when test="({@select}) instance of element()">
                <xso:apply-templates select="if(({@select}) instance of element()) then ({@select}) else node()" mode="#current"/>
              </xso:when>
              <!--  *
                    * handle node() function used in select attributes
                    * -->
              <xso:when test="not(({@select}) instance of item())">
                <xso:apply-templates select="if(not(({@select}) instance of item())) then ({@select}) else node()" mode="#current"/>
              </xso:when>
              <!--  *
                    * fallback: handle as simple text
                    * -->
              <xso:otherwise>
                <xso:value-of select="{@select}"/>
              </xso:otherwise>
            </xso:choose>
            <xso:value-of select="$closing-delimiter"/>
          </xsl:when>
          <xsl:when test="@regex">
            <xso:analyze-string select="." regex="{@regex}">
              <xso:matching-substring>
                <xso:value-of select="$opening-delimiter"/>
                <xso:value-of select="{if( @regex-group) then concat('regex-group(', @regex-group, ')') else '.'}"/>
                <xso:value-of select="$closing-delimiter"/>
              </xso:matching-substring>
            </xso:analyze-string>
          </xsl:when>
          <xsl:when test="text()">
            <xso:value-of select="{concat('''', text(), '''')}"/>
          </xsl:when>
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
    <!-- replacement with xpath context -->
    <xso:template match="text()" mode="replace-chars-specific">
      <xso:variable name="content" select="."/>
      <xsl:for-each-group select="xml2tex:char[@context]" group-by="@context">
        <xsl:for-each select="current-group()">
          <xsl:variable name="pattern" select="concat('''', @character, '''')" as="xs:string"/>
          <!-- escape backspaces and dollar signs -->
          <xsl:variable name="replace" select="concat('''', replace(
                                                              replace(@string, '\\', '\\\\'),
                                                            '\$', '\\\$'), '''')" as="xs:string"/>
          <xsl:variable name="split-xpath" select="tokenize(@context, '\||,')" as="xs:string+"/>
          <xsl:variable name="condition" select="string-join(for $i in $split-xpath return concat('parent::', normalize-space($i)), ' or ')" as="xs:string"/>
          <xso:variable name="content" select="if({$condition}) then replace($content, {$pattern}, {$replace}) else $content" as="xs:string"/>
        </xsl:for-each>
      </xsl:for-each-group>
      <xso:value-of select="$content"/>
    </xso:template>

    <!-- no xpath context defined-->
    <xso:template match="text()" mode="replace-chars-general">
      <xso:variable name="content" select="."/>
      <xsl:for-each select="xml2tex:char[not(@context)]">
        <xsl:variable name="pattern" select="concat('''', @character, '''')" as="xs:string"/>
        <!-- escape backspaces and dollar signs -->
        <xsl:variable name="replace" select="concat('''', replace(
                                                            replace(@string, '\\', '\\\\'),
                                                          '\$', '\\\$'), '''')" as="xs:string"/>
        <xso:variable name="content" select="replace( $content, {$pattern}, {$replace} )" as="xs:string"/>
      </xsl:for-each>
      <xso:value-of select="$content"/>
    </xso:template>

  </xsl:template>

</xsl:stylesheet>
