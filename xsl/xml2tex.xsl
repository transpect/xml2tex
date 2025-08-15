<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
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
  <xsl:param name="table-model" as="xs:string?"/>
  <xsl:param name="xslt-version" select="'2.0'"/>
  
  <xsl:include href="handle-namespace.xsl"/>

  <xsl:template match="/xml2tex:set">
        
    <!--  *
          * Generate XSLT from mapping instructions. 
          * -->
    
    <xso:stylesheet xmlns:xs="http://www.w3.org/2001/XMLSchema"
                    xmlns:xlink="http://www.w3.org/1999/xlink"
                    xmlns:tex="http://www-cs-faculty.stanford.edu/~uno/"
                    xmlns:html="http://www.w3.org/1999/xhtml"
                    xmlns:c="http://www.w3.org/ns/xproc-step"
                    xmlns:xso="tobereplaced">
      
      <xsl:apply-templates select="xml2tex:ns"/>
      
      <xsl:attribute name="version" select="$xslt-version"/>

      <xso:import href="http://transpect.io/xslt-util/functx/xsl/functx.xsl"/>
      <xso:import href="http://transpect.io/xml2tex/xsl/functions.xsl"/>

      <xsl:apply-templates select="xsl:import, xsl:param, xsl:key"/>
      
      <xso:param name="decompose-diacritics" as="xs:boolean"
                 select="{not(@decompose-diacritics eq 'no')}()"/>
      
      <xsl:if test="not(xsl:param[@name = 'table-model'])">
        <xso:param name="table-model" as="xs:string?"
                   select="'{if(normalize-space($table-model)) then $table-model else @table-model}'"/>
      </xsl:if>
      
      <xso:output method="text" media-type="text/plain" encoding="UTF8"/>

      <xsl:apply-templates select="xsl:* except (xsl:import|xsl:param|xsl:key)"/>

      <xso:template match="/" mode="xml2tex" priority="1000000">
        <!-- The c:data-section is necessary for XProc text output. -->
        <c:data content-type="text/plain">
          <xsl:if test="$only-tex-body eq 'no'">
            <xsl:apply-templates select="xml2tex:preamble"/>
            <xso:text>&#xa;\begin{document}&#xa;</xso:text>  
          </xsl:if>
          <xsl:apply-templates select="xml2tex:front"/>
          <xso:next-match/>
          <xsl:apply-templates select="xml2tex:back"/>
          <xsl:if test="$only-tex-body eq 'no'">
            <xso:text>&#xa;\end{document}&#xa;</xso:text>
          </xsl:if>
        </c:data>
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
      <xso:template match="text()[normalize-space()]
                                 [matches(., $xml2tex:all-bad-chars-regex)]" mode="escape-bad-chars">
        <xso:variable name="content" select="xml2tex:escape-for-tex(replace( ., '\\', '\\textbackslash ' ))" as="xs:string"/>
        <xso:value-of select="$content"/>
      </xso:template>
            
      <!-- dissolve elements which are not matched by other templates -->
      
      <xso:template match="*" mode="xml2tex">
        <xso:apply-templates mode="#current"/>
      </xso:template>
      
      <xsl:apply-templates select="xml2tex:* except (xml2tex:ns, xml2tex:preamble, xml2tex:front, xml2tex:back)"/>
      
      <xsl:call-template name="replace-chars"/>
      
      <xsl:call-template name="unwrap-pis"/>
      
      <xsl:call-template name="clean"/>

    </xso:stylesheet>
  </xsl:template>

  <!-- create namespace nodes -->
  <xsl:template match="xml2tex:ns">
    <!-- the code is taken from the schematron project. for information please visit this url
         https://code.google.com/p/schematron/  -->
    <xsl:call-template name="handle-namespace"/>
  </xsl:template>

  <xsl:template match="xml2tex:preamble
                      |xml2tex:front
                      |xml2tex:back">
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
  
  <xsl:variable name="rule-indexes" as="xs:string*"
                select="for $i in //*[local-name() = ('template', 'regex')] 
                        return generate-id($i)"/>
  
  <xsl:template match="xml2tex:regex"/>

  <xsl:template match="xml2tex:template">
    <!--  * the priority of a rule is determined by its order. If more than one 
          * rule matches against a particular element, the last rule declaration has a higher priority
          * and overwrites the rule with a lesser priority. Imported templates have always the priority 1.
          * -->
    <xsl:variable name="template-priority" select="(@priority, (index-of($rule-indexes, generate-id(.)), 1))[1]" as="xs:integer"/>
    <xsl:choose>
      <xsl:when test="@name">
        <!-- allow named templates but process only last in document because not two templates with the same name are allowed -->
        <xsl:if test=". is //xml2tex:template[@name = current()/@name][last()]">
          <xso:template name="{@name}">
            <!-- if no tex child is present, then matched node will be discarded -->
            <xsl:apply-templates/>
          </xso:template>
        </xsl:if>
      </xsl:when>
      <xsl:otherwise>
        <xso:template match="{@context}" mode="xml2tex" priority="{$template-priority}">
          <!-- if no tex child is present, then matched node will be discarded -->
          <xsl:apply-templates/>
        </xso:template>  
      </xsl:otherwise>
    </xsl:choose>
    
  </xsl:template>
  
  <xsl:variable name="style-attribute" select="/xml2tex:set/@style-attribute" as="attribute(style-attribute)?"/>
  
  <xsl:template match="xml2tex:style">
    <xsl:variable name="template-priority" select="count($rule-indexes) + position()" as="xs:integer"/>
    <xso:template match="*[@{$style-attribute} eq '{@name}']" 
                  mode="xml2tex" priority="{$template-priority}">
      <xso:value-of select="'{@start}'"/>
      <xso:apply-templates mode="#current"/>
      <xso:value-of select="'{@end}'"/>
    </xso:template>
  </xsl:template>

  <xsl:template match="xml2tex:file">
    <c:data href="{@href}" method="{(@method, 'text')[1]}" content-type="text/plain"
            encoding="{(@encoding, 'utf-8')[1]}">
      <xsl:choose>
        <xsl:when test="@method = ('xml', 'html', 'xhtml')">
          <xso:copy-of select="."/>
        </xsl:when>
        <xsl:when test="text()">
          <xso:text>
            <xsl:apply-templates/>
          </xso:text>    
        </xsl:when>
        <xsl:when test="not(node())">
          <xso:apply-templates mode="#current"/>    
        </xsl:when>
        <xsl:otherwise>
          <xsl:apply-templates/>
        </xsl:otherwise>
      </xsl:choose>
    </c:data>
  </xsl:template>

  <xsl:template match="xml2tex:rule">
    <xsl:variable name="rule" select="." as="element(xml2tex:rule)"/>
    <!-- three types: 
            env   ==> environment, eg. e.g. begin{bla} ... end{bla}
            cmd   ==> commands, e.g. \bla ...
            none  ==> no tex markup, needed for simple paras or other stuff you want to simply tunnel through the process -->
    <xso:text><xsl:value-of select="xml2tex:rule-start(.)"/></xso:text>
    <xsl:apply-templates/>
    <xso:text><xsl:value-of select="xml2tex:rule-end(.)"/></xso:text>
    <!--
    <xsl:variable name="opening-tag" 
                  select="concat($rule[@break-before]/string-join(for $i in (1 to @break-before) 
                                                                  return '&#xa;', ''),
                                 if     ($rule/@type eq 'env') then concat($rule[not(@break-before)]/'&#xa;', 
                                                                           '\begin{',$rule/@name,'}')
                                 else if(not($rule/@type))     then ()             
                                 else concat('\', $rule/@name),
                                 $rule[@mathmode eq 'true']/'$'
                                 )" as="xs:string?"/>
    <xsl:variable name="closing-tag" 
                  select="concat($rule[@mathmode eq 'true']/'$',
                                 if     ($rule/@type eq 'env') then concat('&#xa;\end{',$rule/@name,'}', 
                                                                           $rule[not(@break-after)]/'&#xa;')
                                 else                               (),
                                 $rule[@break-after]/string-join(for $i in (1 to @break-after) 
                                                                 return '&#xa;', ''))" as="xs:string?"/>
    <xso:variable name="opening-tag" select="{concat('''', $opening-tag, '''')}"/>
    <xso:variable name="closing-tag" select="{concat('''', $closing-tag, '''')}"/>
    <xsl:choose>
      <xsl:when test="ancestor::xml2tex:template">
        <xso:value-of select="$opening-tag"/>
        <xsl:apply-templates/>
        <xso:value-of select="$closing-tag"/>
      </xsl:when>
      <xsl:when test="parent::xml2tex:regex">
        <xsl:variable name="xml2tex:rule" select="." as="element(xml2tex:rule)"/>
        <xso:analyze-string select="." regex="{{'{parent::xml2tex:regex/@regex}'}}">
          <xso:matching-substring>
            <xso:value-of select="$opening-tag"/>
            <xsl:apply-templates/>
            <xso:value-of select="$closing-tag"/>
          </xso:matching-substring>
          <xso:non-matching-substring>
            <xso:value-of select="string-join(xml2tex:utf2tex((), ., $charmap, (), $texregex), '')"/>
          </xso:non-matching-substring>
        </xso:analyze-string>
      </xsl:when>
    </xsl:choose>
    -->
  </xsl:template>
  
  <xsl:template match="xsl:*
                      |xsl:variable//*|@*" priority="1000">
    <xsl:copy>
      <xsl:apply-templates select="@*, node()"/>
    </xsl:copy>
  </xsl:template>

  <xsl:template match="xml2tex:option
                      |xml2tex:param
                      |xml2tex:text">
    <!-- types: text | param | option -->
    <xsl:variable name="opening-delimiter" select="xml2tex:get-delimiters(.)[1]" as="xs:string?"/>
    <xsl:variable name="closing-delimiter" select="xml2tex:get-delimiters(.)[2]" as="xs:string?"/>
    <xsl:variable name="parameter" as="element(xsl:with-param)*">
      <xsl:for-each select="xml2tex:with-param">
        <xsl:if test="current()[@name and @select]">
          <xsl:element name="xsl:with-param">
            <xsl:copy-of select="@*"/>
          </xsl:element>
        </xsl:if>
      </xsl:for-each>
      <xsl:if test="self::xml2tex:option">
        <xsl:element name="xsl:with-param">
            <xsl:attribute name="name" select="'as-option'"/> 
            <xsl:attribute name="select" select="'true()'"/> 
            <xsl:attribute name="tunnel" select="'yes'"/>
            <xsl:attribute name="as" select="'xs:boolean'"/>
          </xsl:element>
      </xsl:if>
    </xsl:variable>
    <xso:text><xsl:value-of select="$opening-delimiter"/></xso:text>
    <xsl:choose>
      <!--  *
            * regex attribute exists either in text/option/param tag
            * -->
      <xsl:when test="@select and @type='text'">
        <xso:value-of select="{@select}"/>
      </xsl:when>
      <!--  *
            * select attribute exists either in text/option/param tag
            * -->
      <xsl:when test="@select">
        <xso:choose>
          <!--  handle elements -->
          <xso:when test="({@select}) instance of element()">
            <xso:apply-templates select="if(({@select}) instance of node()) then ({@select}) else node()" mode="xml2tex">
              <xsl:if test="$parameter"><xsl:sequence select="$parameter"/></xsl:if>
            </xso:apply-templates> 
          </xso:when>
          <xso:when test="not(({@select}) instance of item())">
            <!-- avoid applying-templates of attributes that might create attributes after other nodes -->
            <xso:apply-templates select="if(not(({@select}) instance of item())) then ({@select}) else node()" mode="xml2tex">
              <xsl:if test="$parameter"><xsl:sequence select="$parameter"/></xsl:if>
            </xso:apply-templates> 
          </xso:when>
          <xso:when test="({@select}) instance of text()">
            <xso:apply-templates select="if(({@select}) instance of text()) then ({@select}) else node()" mode="xml2tex">
              <xsl:if test="$parameter"><xsl:sequence select="$parameter"/></xsl:if>
            </xso:apply-templates> 
          </xso:when>
          <!--  fallback: handle as simple text -->
          <xso:otherwise>
            <xso:value-of select="{@select}"/>
          </xso:otherwise>
        </xso:choose>
      </xsl:when>
      <!--  *
            * text/option/param tag contains XSLT instructions
            * -->
      <xsl:when test="xsl:*">
        <xsl:apply-templates/> 
      </xsl:when>
      <!--  *
            * text/option/param tag contains static text. if with-param is there, ignore text
            * -->
      <xsl:when test="text() and not(*) and not(comment()) and not(processing-instruction())">
        <xso:value-of select="{concat('''', string-join(text(),''), '''')}"/>
      </xsl:when>
      <!--  *
            * fallback for anything
            * -->
      <xsl:otherwise>
        <xso:choose>
          <xso:when test="(.) instance of element()">
            <xso:apply-templates mode="#current">
               <xsl:if test="$parameter"><xsl:sequence select="$parameter"/></xsl:if>
            </xso:apply-templates>
          </xso:when>
          <xso:otherwise>
            <xso:next-match/>
          </xso:otherwise>
        </xso:choose>
      </xsl:otherwise>
    </xsl:choose>
    <xso:text><xsl:value-of select="$closing-delimiter"/></xso:text>
  </xsl:template>
  
  <xsl:template match="*|@*" mode="regex-map">
    <xsl:copy>
      <xsl:apply-templates select="@*, node()" mode="#current"/>
    </xsl:copy>
  </xsl:template>
  
  <xsl:template match="xml2tex:regex//xml2tex:param/@select
                      |xml2tex:regex//xml2tex:option/@select
                      |xml2tex:regex//xml2tex:text/@select" priority="5" mode="regex-map">
    <xsl:attribute name="select-evaluated" select="'true'"/>
    <xso:choose>
      <xso:when test="{.} instance of node()">
        <xso:apply-templates select="{.}" mode="xml2tex"/>
      </xso:when>
      <xso:otherwise>
        <xso:value-of select="{.}"/>
      </xso:otherwise>
    </xso:choose>
  </xsl:template>
  
  <xsl:template match="xml2tex:regex//xml2tex:rule/@name" mode="regex-map">
    <xsl:attribute name="name" select="xml2tex:escape-for-xslt(.)"/>
  </xsl:template>

  <!-- replace chars via character map -->
  
  <xsl:template name="replace-chars">
        
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
    
    <xso:variable name="regex-map" as="element(xml2tex:regex)*">
      <xsl:for-each select="/xml2tex:set/xml2tex:regex">
        <xsl:sort select="(xs:integer(@regex-priority), 1)[1]" order="descending"/>
        <xsl:copy>
          <xsl:attribute name="regex" select="xml2tex:escape-for-xslt(@regex)"/>
          <xsl:apply-templates select="@* except @regex, node()" mode="regex-map"/>
        </xsl:copy>
      </xsl:for-each>
    </xso:variable>
    
    <xso:variable name="regex-regex" as="xs:string"
                  select="{concat('''(',
                                  string-join(/xml2tex:set/xml2tex:regex/@regex/concat('(', .,')'), '|'),
                                  ')''')}"/>
    
    <!-- filter $regex-macros document before it is applied by xml2tex:apply-regexes()
         to restrict dynamically the XML context of certain regexes -->
    
    <xso:function name="xml2tex:filter-regex-document" as="element(xml2tex:regex)*">
      <xso:param name="context" as="node()?"/>
      <xso:param name="regex-map" as="element(xml2tex:regex)*"/>
      <xsl:for-each select="/xml2tex:set/xml2tex:regex">
        <xsl:variable name="pos" select="position()" as="xs:integer"/>
        <xsl:choose>
          <xsl:when test="@context">
            <xso:if test="$context/{@context} or empty($context)">
              <xso:copy-of select="$regex-map[{$pos}]"/>
            </xso:if>
          </xsl:when>
          <xsl:otherwise>
            <xso:copy-of select="$regex-map[{$pos}]"/>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:for-each>
    </xso:function>
    
    <xsl:variable name="text-match-tokens" as="xs:string+" 
                  select="(
                  /xml2tex:set/xml2tex:charmap/xml2tex:char[1]/'matches(., $texregex)',
                  /xml2tex:set/xml2tex:regex[1]/'matches(., $regex-regex)',
                  'matches(., $xml2tex:simpleeq-regex)',
                  'matches(., $xml2tex:root-regex)',
                  'matches(normalize-unicode(., ''NFD''),  $xml2tex:diacrits-regex)',
                  'matches(normalize-unicode(., ''NFKD''), $xml2tex:fraction-regex)'
                  )"/>
    
    <!-- replacement with xpath context -->
    <xso:template match="text()[normalize-space()]
                               [{string-join($text-match-tokens, ' or ')}]" mode="xml2tex">
      <!-- this function needs to run before any character mapping, because of roots e.g. -->
      <xso:variable name="simplemath" select="if(matches(., $xml2tex:simpleeq-regex)) 
                                              then string-join(xml2tex:convert-simplemath(.), '')
                                              else ." as="xs:string"/>
      <!-- maps unicode to latex -->
      <xsl:choose>
        <xsl:when test="/xml2tex:set/xml2tex:regex">
          <xso:variable name="handle-regexes" 
                        select="if(matches($simplemath, $regex-regex)) 
                                then string-join(xml2tex:apply-regexes($simplemath, xml2tex:filter-regex-document(.., $regex-map)), '') 
                                else normalize-unicode($simplemath)" as="xs:string"/>
        </xsl:when>
        <xsl:otherwise>
          <xso:variable name="handle-regexes" select="$simplemath" as="xs:string"/>
        </xsl:otherwise>
      </xsl:choose>
      <xsl:choose>
        <xsl:when test="/xml2tex:set/xml2tex:charmap">
          <xso:variable name="utf2tex"
                        select="if(matches($handle-regexes, $texregex)) 
                                then string-join(xml2tex:utf2tex(.., $handle-regexes, $charmap, (), $texregex), '') 
                                else $handle-regexes" as="xs:string"/>
        </xsl:when>
        <xsl:otherwise>
          <xso:variable name="utf2tex" select="$handle-regexes" as="xs:string"/>
        </xsl:otherwise>
      </xsl:choose>
      <!-- has to run last because it resolves combined unicode characters -->
      <xso:choose>
        <xso:when test="$decompose-diacritics 
                        and (   matches(normalize-unicode($utf2tex, 'NFD'),  $xml2tex:diacritical-marks-regex)
                             or matches(normalize-unicode($utf2tex, 'NFKD'), $xml2tex:fraction-regex))">
          <xso:value-of select="string-join(xml2tex:convert-diacrits($utf2tex, $texregex, $xml2tex:diacrits, $charmap), '')"/>
        </xso:when>
        <xso:otherwise>
          <xso:value-of select="$utf2tex"/>
        </xso:otherwise>
      </xso:choose>
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
          <xso:otherwise>
            <!--
              Avoid masking of context specific replacements of character 'A' by context specific replacement of character 'B'.
              Given the charmap
              
                <charmap>
                  <char character="A" string="A no context"/>
                  <char character="A" string="A context 1" context="*[@css:font-style eq 'italic']"/>
                  <char character="B" string="B no context"/>
                  <char character="B" string="B context 2" context="dbk:title/dbk:phrase"/>
                </charmap>
              
              we would get
              
                 <xsl:template match="*[@css:font-style eq 'italic']"
                               mode="char-context"
                               as="xs:string?">
                    <xsl:param name="char-in-doc" as="xs:string?"/>
                    <xsl:choose>
                       <xsl:when test="$char-in-doc = 'A'">
                          <xsl:sequence select="'A context 1'"/>
                       </xsl:when>
                    </xsl:choose>
                 </xsl:template>
              
                <xsl:template match="dbk:title/dbk:phrase" mode="char-context" as="xs:string?">
                    <xsl:param name="char-in-doc" as="xs:string?"/>
                    <xsl:choose>
                       <xsl:when test="$char-in-doc = 'B'">
                          <xsl:sequence select="'B context 2'"/>
                       </xsl:when>
                    </xsl:choose>
                 </xsl:template>
              
              This is a problem because an 'A' in an 'dbk:title/dbk:phrase[@css:font-style eq 'italic']' would match the second template although
              no character mapping of 'A' has been defined for that context.
              Therefor 'A no context' would be rendered, masking the first template.
              
              Solution: lets try the next matching template.
            -->
            <xso:next-match>
              <xso:with-param name="char-in-doc" select="$char-in-doc"/>
            </xso:next-match>
          </xso:otherwise>
        </xso:choose>
      </xso:template>
    </xsl:for-each-group>
    
  </xsl:template>
  
  <xsl:template name="unwrap-pis">
    
    <xso:template match="processing-instruction('cals2tabular')
                        |processing-instruction('htmltabs')
                        |processing-instruction('latex')" mode="xml2tex">
      <xso:value-of select="replace(., '\s\s+', ' ')"/>
    </xso:template>
    
    <xso:template match="processing-instruction('mml2tex')
                        |processing-instruction('mathtype')" mode="clean">
      <xso:value-of select="replace(., '\s\s+', ' ')"/>
    </xso:template>
    
    <xso:template match="processing-instruction('passthru')" mode="clean">
      <xso:value-of select="."/>
    </xso:template>
    
  </xsl:template>
  
  <xsl:template name="clean">
    
    <xso:template match="processing-instruction() | comment() " mode="clean"/>
    
    <xso:template match="text()" mode="clean">
      <!-- do not remove space after `\` `\ `; mask it as `{\ }` -->
      <xso:variable name="mask-backslash-space" as="xs:string"
                    select="replace(., '(^|[^\\])((\\\\)+)?(\\ )', '$1$2{{$4}}', 'm')" />
      <xso:variable name="remove-whitespace-before-pagebreaks" as="xs:string"
                    select="replace($mask-backslash-space, '([^\p{{Zs}}])\p{{Zs}}*\n?\p{{Zs}}*(\\(pagebreak|break|newline|\\))', '$1$2', 'm')"/>
      <xso:value-of select="$remove-whitespace-before-pagebreaks"/>
    </xso:template>
    
  </xsl:template>

</xsl:stylesheet>