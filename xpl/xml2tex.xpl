<?xml version="1.0" encoding="UTF-8"?>
<p:declare-step 
  xmlns:p="http://www.w3.org/ns/xproc"
  xmlns:c="http://www.w3.org/ns/xproc-step" 
  xmlns:cx="http://xmlcalabash.com/ns/extensions"
  xmlns:tr="http://transpect.io"
  xmlns:dbk="http://docbook.org/ns/docbook"
  xmlns:mml="http://www.w3.org/1998/Math/MathML"
  xmlns:mml2tex="http://transpect.io/mml2tex"
  xmlns:xml2tex="http://transpect.io/xml2tex"
  version="1.0" 
  name="xml2tex" 
  type="xml2tex:convert">

  <p:documentation>
    Converts an XML file according to an XML configuration to LaTeX.
  </p:documentation>
  
  <p:input port="source" primary="true">
    <p:document href="../example/example.xml"/>
  </p:input>
  <p:input port="conf" primary="false">
    <p:document href="../example/conf-hubcssa.xml"/>
  </p:input>
  <p:input port="paths" primary="false">
    <p:inline>
      <c:param-set/>
    </p:inline>
  </p:input>
  <p:input port="html2calstable-xslt" primary="false">
    <p:document href="http://this.transpect.io/xslt-util/calstable/xsl/html2calstable.xsl"/>
  </p:input>
  <p:input port="additional-source"  primary="false">
    <p:empty/>
  </p:input>

  <p:output port="result"/>
  
  <p:serialization port="result" method="text" media-type="text/plain" encoding="utf8"/>
  
  <p:option name="debug" select="'yes'">
    <p:documentation>
      Used to switch debug mode on or off. Pass 'yes' to enable debug mode.
    </p:documentation>
  </p:option>
  
  <p:option name="debug-dir-uri" select="'debug'">
    <p:documentation>
      Expects a file URI of the directory that should be used to store debug information. 
    </p:documentation>
  </p:option>
  
  <p:option name="status-dir-uri" select="'status'">
    <p:documentation>
      Expects URI where the text files containing the progress information are stored.
    </p:documentation>
  </p:option>
  
  <p:option name="fail-on-error" select="'yes'">
    <p:documentation>
      'yes' to keep nested tables. 'no' to resolve nested tables (experimental).
    </p:documentation>
  </p:option>
  
  <p:option name="preprocessing" select="'yes'">
    <p:documentation>
      Switch XSLT optimizations for MathML on or off.
    </p:documentation>
  </p:option>
  
  <p:option name="table-model" select="''" required="false">
    <p:documentation>
      Use LaTeX package to draw tables. Permitted values are 'tabular' (default),
      'tabularx' and 'htmltabs'.
    </p:documentation>
  </p:option>
  
  <p:option name="table-grid" select="''" required="false">
    <p:documentation>
      Draw table cell borders. Permitted values: yes|no
    </p:documentation>
  </p:option>
  
  <p:option name="no-table-grid-att" select="'role'" required="false">
    <p:documentation>
      Attribute that defines a table to be displayed without grid
    </p:documentation>
  </p:option>
  
  <p:option name="no-table-grid-style" select="'blind-table'" required="false">
    <p:documentation>
      Attribute value that defines a table to be displayed without grid
    </p:documentation>
  </p:option>

  <p:option name="nested-tables" select="'yes'" required="false">
    <p:documentation>
      Whether nested tables should remain or resolved in one table.
    </p:documentation>
  </p:option>
  
  <p:option name="prefix" select="'xml2tex/'">
    <p:documentation>
      Prefix for debug files.
    </p:documentation>
  </p:option>
  
  <p:option name="texmap-uri" select="'../texmap/texmap.xml'" required="false">
    <p:documentation>
      choose a tex map for mml2tex conversion
    </p:documentation>
  </p:option>
  
  <p:option name="only-tex-body" select="'no'">
    <p:documentation>
      Just output the tex body document without preamble, 
      \begin{document} and \end{document}
    </p:documentation>
  </p:option>
  
  <p:option name="set-math-style" select="'no'">
    <p:documentation>
      [yes|no] Whether to output \textstyle or \displaystyle when math/@display is set
    </p:documentation>
  </p:option>
  
  <p:option name="collect-all-xsl" required="false" select="'no'">
    <p:documentation>if this option is set to 'yes' or 'true' all xsl:templates with match attribute are collected.</p:documentation>
  </p:option>
  
  <p:option name="xslt-version" required="false" select="'2.0'">
    <p:documentation>Sets the XSLT version of the generated stylesheet.</p:documentation>
  </p:option>
  
  <p:import href="load-config.xpl"/>
  
  <p:import href="http://xmlcalabash.com/extension/steps/library-1.0.xpl"/>
  <p:import href="http://transpect.io/cascade/xpl/load-cascaded.xpl"/>
  <p:import href="http://transpect.io/mml2tex/xpl/mml2tex.xpl"/>
  <p:import href="http://transpect.io/xslt-util/calstable/xpl/normalize.xpl"/>
  <p:import href="http://transpect.io/xslt-util/calstable/xpl/resolve-nested-tables.xpl"/>
  <p:import href="http://transpect.io/xproc-util/store-debug/xpl/store-debug.xpl"/>
  <p:import href="http://transpect.io/xproc-util/simple-progress-msg/xpl/simple-progress-msg.xpl"/>
  <p:import href="http://transpect.io/xproc-util/xslt-mode/xpl/xslt-mode.xpl"/>
  
  <p:variable name="collect-all-xsl-var" select="(/c:param-set/c:param[@name eq 'collect-all-xsl']/@value, $collect-all-xsl)[1]">
    <p:pipe port="paths" step="xml2tex"/>
  </p:variable>
  
  <p:sink/>
  
  <!--  *
        * store in-scope parameters and variables for debugging
        * -->
  
  <p:in-scope-names name="expose-params-and-vars"/>
  
  <p:insert match="/c:param-set" position="first-child">
    <p:input port="source">
      <p:pipe port="result" step="expose-params-and-vars"/>
    </p:input>
    <p:input port="insertion" select="/c:param-set/*">
      <p:pipe port="paths" step="xml2tex"/>
    </p:input>
  </p:insert>
  
  <tr:store-debug name="store-params-and-vars">
    <p:with-option name="pipeline-step" select="concat($prefix, '00.params-and-vars')"/>
    <p:with-option name="active" select="$debug"/>
    <p:with-option name="base-uri" select="$debug-dir-uri"/>
  </tr:store-debug>
  
  <p:sink/>
  
  <!--  *
        * load config(s) (recursively).
        * -->
  
  <xml2tex:load-config name="load-config">
    <p:input port="source">
      <p:pipe port="conf" step="xml2tex"/>
    </p:input>    
    <p:with-option name="fail-on-error" select="$fail-on-error"/>
    <p:with-option name="collect-all-xsl" select="$collect-all-xsl-var"/>
  </xml2tex:load-config>
  
  <tr:store-debug name="store-config">
    <p:with-option name="pipeline-step" select="concat($prefix, '04.loaded-config')"/>
    <p:with-option name="active" select="$debug"/>
    <p:with-option name="base-uri" select="$debug-dir-uri"/>
  </tr:store-debug>
  
  <!--  *
        * validate the configuration file.
        * -->

  <p:try name="try-validate">
    <p:group>
      <p:validate-with-relax-ng name="validate" assert-valid="true">
        <p:input port="schema">
          <p:document href="../schema/xml2tex.rng"/>
        </p:input>
      </p:validate-with-relax-ng>      
    </p:group>
    <p:catch name="catch">
      <cx:message>
        <p:input port="source">
          <p:pipe port="error" step="catch"/>
        </p:input>
        <p:with-option name="message"
                       select="'[WARNING]: Configuration is not valid with respect to the schema. Please validate your configuration file with schema/xml2tex.rng.&#xa;'"/>
      </cx:message>

      <p:sink/>

      <p:identity>
        <p:input port="source">
          <p:pipe port="result" step="load-config"/>
        </p:input>
      </p:identity>
      
    </p:catch>
  </p:try>
  
  <tr:simple-progress-msg file="xml2tex-validate-config.txt" name="msg-1">
    <p:input port="msgs">
      <p:inline>
        <c:messages>
          <c:message xml:lang="en">Validation of xml2tex configuration successful</c:message>
          <c:message xml:lang="de">Validierung der xml2tex Konfiguration erfolgreich</c:message>
        </c:messages>
      </p:inline>
    </p:input>
    <p:with-option name="status-dir-uri" select="$status-dir-uri"/>
  </tr:simple-progress-msg>
  
  <p:sink/>
  
  <tr:load-cascaded name="load-generate-conf-xsl" filename="xml2tex/xml2tex.xsl">
    <p:with-option name="fallback" select="resolve-uri('../xsl/xml2tex.xsl')"/>
    <p:input port="paths">
      <p:pipe port="paths" step="xml2tex"/>
    </p:input>
    <p:with-option name="debug" select="$debug"/>
    <p:with-option name="debug-dir-uri" select="$debug-dir-uri"/>
  </tr:load-cascaded>
  
  <p:sink/>
  
  <p:xslt name="conf2xsl">
    <p:documentation>This step generates a stylesheet from the xml2tex 
      mapping instructions. The rules are converted to XSL templates.</p:documentation>
    <p:input port="stylesheet">
      <p:pipe port="result" step="load-generate-conf-xsl"/>
    </p:input>
    <p:input port="source">
      <p:pipe port="result" step="load-config"/>
    </p:input>
    <p:input port="parameters">
      <p:pipe port="paths" step="xml2tex"/>
    </p:input>
    <p:with-param name="debug" select="$debug"/>
    <p:with-param name="debug-dir-uri" select="$debug-dir-uri"/>
    <p:with-param name="xslt-version" select="$xslt-version"/>
    <p:with-param name="table-model" select="$table-model"/>
    <p:with-param name="only-tex-body" select="$only-tex-body"/>
  </p:xslt>
  
  <tr:store-debug name="debug-conf" extension="xsl">
    <p:with-option name="pipeline-step" select="concat($prefix, '08.config')"/>
    <p:with-option name="active" select="$debug"/>
    <p:with-option name="base-uri" select="$debug-dir-uri"/>
  </tr:store-debug>
  
  <tr:simple-progress-msg file="xml2tex-convert-tables.txt" name="msg-2">
    <p:input port="msgs">
      <p:inline>
        <c:messages>
          <c:message xml:lang="en">Convert CALS tables to TeX tabular</c:message>
          <c:message xml:lang="de">Konvertiere CALS Tabellen nach TeX tabular</c:message>
        </c:messages>
      </p:inline>
    </p:input>
    <p:with-option name="status-dir-uri" select="$status-dir-uri"/>
  </tr:simple-progress-msg>
    
  <p:sink name="drop-config-xslt"/>
  
  <p:identity name="pipe-input-xml">
    <p:input port="source">
      <p:pipe port="source" step="xml2tex"/>
    </p:input>
  </p:identity>
  
  <p:choose name="html2cals-tables">

    <p:when test="exists(//*:table//*:td)">
      <p:output port="result" primary="true"/>
      <p:output port="report" sequence="true">
        <p:pipe port="report" step="html2cals"/>
      </p:output>
      
      <tr:xslt-mode msg="yes" mode="html2cals" name="html2cals">
        <p:input port="stylesheet">
          <p:pipe step="xml2tex" port="html2calstable-xslt"/>
        </p:input>
        <p:input port="models"><p:empty/></p:input>
        <p:with-option name="debug" select="$debug"/>
        <p:with-option name="debug-dir-uri" select="$debug-dir-uri"/>
        <p:with-option name="fail-on-error" select="$fail-on-error"/>
        <p:with-option name="prefix" select="concat($prefix, '10')"/>
        <p:with-param name="process-tables-only" select="'yes'"/>
      </tr:xslt-mode>
      
    </p:when>
    <p:otherwise>
      <p:output port="result" primary="true"/>
      <p:output port="report" sequence="true"/>
      <p:identity name="i2">
        <p:input port="source">
          <p:pipe port="result" step="pipe-input-xml"/>
        </p:input>
      </p:identity>
    </p:otherwise>
  </p:choose>

  <p:choose name="resolve-tables-or-normalize">
    <p:when test="($table-model[normalize-space()], xml2tex:set/@table-model)[1] = 'htmltabs'">
      <p:xpath-context>
        <p:pipe port="result" step="load-config"/>
      </p:xpath-context>
      <p:identity/>
    </p:when>
    <p:when test="$nested-tables eq 'yes'">
      <tr:normalize-calstables name="normalize-calstables"/>
    </p:when>
    <p:otherwise>
      <tr:resolve-nested-calstables name="resolve-calstables"/>
    </p:otherwise>
  </p:choose>
  
  <tr:store-debug name="debug-calstables">
    <p:with-option name="pipeline-step" select="concat($prefix, '14.normalize-calstables')"/>
    <p:with-option name="active" select="$debug"/>
    <p:with-option name="base-uri" select="$debug-dir-uri"/>
  </tr:store-debug>
  
  <p:choose name="only-run-if-tables-present">
    <p:when test="exists(//dbk:entry | //entry)">
    <p:choose name="choose-table-model-xslt">
      <p:when test="($table-model[normalize-space()], xml2tex:set/@table-model)[1] = 'htmltabs'">
        <p:xpath-context>
          <p:pipe port="result" step="load-config"/>
        </p:xpath-context>
        <p:output port="result">
          <p:pipe port="result" step="load-cals2tabular-xsl"/>
        </p:output>
        
        <tr:load-cascaded name="load-cals2tabular-xsl" filename="xml2tex/calstable2htmltabs.xsl">
          <p:with-option name="fallback" select="resolve-uri('../xsl/calstable2htmltabs.xsl')"/>
          <p:input port="paths">
            <p:pipe port="paths" step="xml2tex"/>
          </p:input>
          <p:with-option name="debug" select="$debug"/>
          <p:with-option name="debug-dir-uri" select="$debug-dir-uri"/>
        </tr:load-cascaded>
        <p:sink/>
      </p:when>
      <p:otherwise>
        <p:output port="result">
          <p:pipe port="result" step="load-cals2tabular-xsl"/>
        </p:output>
        
        <tr:load-cascaded name="load-cals2tabular-xsl" filename="xml2tex/calstable2tabular.xsl">
          <p:with-option name="fallback" select="resolve-uri('../xsl/calstable2tabular.xsl')"/>
          <p:input port="paths">
            <p:pipe port="paths" step="xml2tex"/>
          </p:input>
          <p:with-option name="debug" select="$debug"/>
          <p:with-option name="debug-dir-uri" select="$debug-dir-uri"/>
        </tr:load-cascaded>
        <p:sink/>
      </p:otherwise>
      
    </p:choose>
  
    <p:sink/>
  
    <p:xslt name="cals2tabular" template-name="main">
      <p:documentation>
        This stylesheet converts CALS tables to LaTeX tables. The LaTeX Code 
        is inserted as "cals2tabular" processing instructions. 
      </p:documentation>
      <p:input port="source">
        <p:pipe port="result" step="debug-calstables"/>
      </p:input>
      <p:input port="stylesheet">
        <p:pipe port="result" step="choose-table-model-xslt"/>
      </p:input>
      <p:input port="parameters">
        <p:pipe port="paths" step="xml2tex"/>
      </p:input>    
      <p:with-param name="table-model" select="($table-model[normalize-space()], xml2tex:set/@table-model, 'tabularx')[1]">
        <p:pipe port="result" step="load-config"/>
      </p:with-param>
      <p:with-param name="table-grid" select="($table-grid[normalize-space()], xml2tex:set/@table-grid, 'yes')[1]">
        <p:pipe port="result" step="load-config"/>
      </p:with-param>
      <p:with-param name="table-col-declaration" select="xml2tex:set/@table-col-declaration">
        <p:pipe port="result" step="load-config"/>
      </p:with-param>
      <p:with-param name="table-first-col-declaration" select="xml2tex:set/@table-first-col-declaration">
        <p:pipe port="result" step="load-config"/>
      </p:with-param>
      <p:with-param name="table-last-col-declaration" select="xml2tex:set/@table-last-col-declaration">
        <p:pipe port="result" step="load-config"/>
      </p:with-param>
      <p:with-param name="table-col-separator" select="xml2tex:set/@table-col-separator">
        <p:pipe port="result" step="load-config"/>
      </p:with-param>
      <p:with-param name="table-first-col-separator" select="xml2tex:set/@table-first-col-separator">
        <p:pipe port="result" step="load-config"/>
      </p:with-param>
      <p:with-param name="table-last-col-separator" select="xml2tex:set/@table-last-col-separator">
        <p:pipe port="result" step="load-config"/>
      </p:with-param>
      <p:with-param name="table-subhead-cell-style-regex" select="(xml2tex:set/@table-subhead-cell-style-regex,'xerif-subhead-cell-style')[1]">
        <p:pipe port="result" step="load-config"/>
      </p:with-param>
      <p:with-param name="no-table-grid-att" select="$no-table-grid-att"/>
      <p:with-param name="no-table-grid-style" select="$no-table-grid-style"/>
      <p:with-param name="debug" select="$debug"/>
      <p:with-param name="debug-dir-uri" select="$debug-dir-uri"/>
    </p:xslt>
  
    <tr:store-debug name="debug-cals2tex">
      <p:with-option name="pipeline-step" select="concat($prefix, '18.cals2tex')"/>
      <p:with-option name="active" select="$debug"/>
      <p:with-option name="base-uri" select="$debug-dir-uri"/>
    </tr:store-debug>
  
    </p:when>
    <p:otherwise>
      <p:identity/>
    </p:otherwise>
  </p:choose>
  
  <p:choose>
    <p:when test="exists(//mml:math)">
      <tr:simple-progress-msg file="xml2tex-convert-mml.txt" name="msg-3">
        <p:input port="msgs">
          <p:inline>
            <c:messages>
              <c:message xml:lang="en">Convert MathML equations to TeX</c:message>
              <c:message xml:lang="de">Konvertiere MathML-Formeln nach TeX</c:message>
            </c:messages>
          </p:inline>
        </p:input>
        <p:with-option name="status-dir-uri" select="$status-dir-uri"/>
      </tr:simple-progress-msg>
      
      <mml2tex:convert name="mml2tex">
        <p:documentation>
          MathML equations are converted to "mml2tex" processing instructions.
        </p:documentation>
        <p:input port="paths">
          <p:pipe port="paths" step="xml2tex"/>
        </p:input>
        <p:with-option name="preprocessing" select="$preprocessing"/>
        <p:with-option name="set-math-style" select="$set-math-style"/>
        <p:with-option name="texmap-uri" select="$texmap-uri"/>
        <p:with-option name="debug" select="$debug"/>
        <p:with-option name="debug-dir-uri" select="$debug-dir-uri"/>
      </mml2tex:convert>
      
      <tr:store-debug name="debug-mml2tex">
        <p:with-option name="pipeline-step" select="concat($prefix, '20.mml2tex')"/>
        <p:with-option name="active" select="$debug"/>
        <p:with-option name="base-uri" select="$debug-dir-uri"/>
      </tr:store-debug>
    </p:when>
    <p:otherwise>
      <p:identity/>
    </p:otherwise>
  </p:choose>
  
  <tr:simple-progress-msg file="xml2tex-convert-xml.txt" name="msg-4">
    <p:input port="msgs">
      <p:inline>
        <c:messages>
          <c:message xml:lang="en">Apply xml2tex configuration and convert XML to LaTeX</c:message>
          <c:message xml:lang="de">xml2tex-Konfiguration anwenden und XML nach LaTeX konvertieren</c:message>
        </c:messages>
      </p:inline>
    </p:input>
    <p:with-option name="status-dir-uri" select="$status-dir-uri"/>
  </tr:simple-progress-msg>
    
  <tr:xslt-mode msg="yes" mode="escape-bad-chars" name="escape-bad-chars">
    <p:input port="stylesheet">
      <p:pipe port="result" step="conf2xsl"/>
    </p:input>
    <p:input port="parameters">
      <p:pipe port="paths" step="xml2tex"/>
    </p:input>
    <p:input port="models"><p:empty/></p:input>
    <p:with-option name="debug" select="$debug"/>
    <p:with-option name="debug-dir-uri" select="$debug-dir-uri"/>
    <p:with-option name="fail-on-error" select="$fail-on-error"/>
    <p:with-option name="prefix" select="concat($prefix, '30')"/>
  </tr:xslt-mode>
  
  <p:sink/>
  
  <tr:xslt-mode msg="yes" mode="xml2tex" name="xm2tex-mode">
    <p:input port="source">
      <p:pipe port="result" step="escape-bad-chars"/>
      <p:pipe port="additional-source" step="xml2tex"/>
    </p:input>
    <p:input port="stylesheet">
      <p:pipe port="result" step="conf2xsl"/>
    </p:input>
    <p:input port="parameters">
      <p:pipe port="paths" step="xml2tex"/>
    </p:input>
    <p:input port="models"><p:empty/></p:input>
    <p:with-option name="debug" select="$debug"/>
    <p:with-option name="debug-dir-uri" select="$debug-dir-uri"/>
    <p:with-option name="fail-on-error" select="$fail-on-error"/>
    <p:with-option name="prefix" select="concat($prefix, '33')"/>
  </tr:xslt-mode>
  
  <tr:xslt-mode msg="yes" mode="clean" name="clean">
    <p:input port="stylesheet">
      <p:pipe port="result" step="conf2xsl"/>
    </p:input>
    <p:input port="parameters">
      <p:pipe port="paths" step="xml2tex"/>
    </p:input>
    <p:input port="models"><p:empty/></p:input>
    <p:with-option name="debug" select="$debug"/>
    <p:with-option name="debug-dir-uri" select="$debug-dir-uri"/>
    <p:with-option name="fail-on-error" select="$fail-on-error"/>
    <p:with-option name="prefix" select="concat($prefix, '36')"/>
  </tr:xslt-mode>
  
  <p:viewport match="/c:data//c:data" name="store-additional-outputs">
    <p:output port="result" sequence="true"/>
    
    <p:choose>
      <p:when test="c:data/@method = ('xml', 'html', 'xhtml')">
        
        <p:unwrap match="c:data"/>
        
        <p:store>
          <p:with-option name="href" select="c:data/@href">
            <p:pipe port="current" step="store-additional-outputs"/>
          </p:with-option>
          <p:with-option name="method" select="c:data/@method">
            <p:pipe port="current" step="store-additional-outputs"/>
          </p:with-option>
          <p:with-option name="encoding" select="c:data/@encoding">
            <p:pipe port="current" step="store-additional-outputs"/>
          </p:with-option>
          <p:with-option name="media-type" select="c:data/@content-type">
            <p:pipe port="current" step="store-additional-outputs"/>
          </p:with-option>
        </p:store>
        
      </p:when>
      <p:otherwise>
        
        <p:store>
          <p:with-option name="href" select="c:data/@href"/>
          <p:with-option name="method" select="c:data/@method"/>
          <p:with-option name="encoding" select="c:data/@encoding"/>
          <p:with-option name="media-type" select="c:data/@content-type"/>
        </p:store>
        
      </p:otherwise>
    </p:choose>
    
    <p:delete match="c:data">
      <p:input port="source">
        <p:pipe port="current" step="store-additional-outputs"/>
      </p:input>
    </p:delete>
    
  </p:viewport>
  
</p:declare-step>
