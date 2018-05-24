<?xml version="1.0" encoding="UTF-8"?>
<p:declare-step 
  xmlns:p="http://www.w3.org/ns/xproc"
  xmlns:c="http://www.w3.org/ns/xproc-step" 
  xmlns:cx="http://xmlcalabash.com/ns/extensions"
  xmlns:tr="http://transpect.io"
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

  <p:output port="result" primary="true"/>
  
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
      Whether the pipeline should fail on some errors.
    </p:documentation>
  </p:option>
  
  <p:option name="preprocessing" select="'yes'">
    <p:documentation>
      Switch XSLT optimizations for MathML on or off.
    </p:documentation>
  </p:option>
  
  <p:option name="table-model" select="'tabularx'" required="false">
    <p:documentation>
      Used LaTeX package to draw tables. Possible values are 'tabular' and 'tabularx'.
    </p:documentation>
  </p:option>
  
  <p:option name="table-grid" select="'yes'" required="false">
    <p:documentation>
      Draw table cell borders.
    </p:documentation>
  </p:option>

  <p:option name="nested-tables" select="'no'" required="false">
    <p:documentation>
      Whether nested tables should remain or resolved in one table.
    </p:documentation>
  </p:option>
  
  <p:option name="prefix" select="'xml2tex/xml2tex0'">
    <p:documentation>
      Prefix for debug files.
    </p:documentation>
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
  
  <!--  *
        * load config(s) (recursively).
        * -->
  
  <xml2tex:load-config name="load-config">
    <p:input port="source">
      <p:pipe port="conf" step="xml2tex"/>
    </p:input>    
    <p:with-option name="fail-on-error" select="$fail-on-error"/>
  </xml2tex:load-config>
  
  <tr:store-debug name="store-config">
    <p:with-option name="pipeline-step" select="concat($prefix, '0.loaded-config')"/>
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
          <c:message xml:lang="en">Validation of xml2tex configuration successfull</c:message>
          <c:message xml:lang="de">Validierung der xml2tex Konfiguration erfolgreich</c:message>
        </c:messages>
      </p:inline>
    </p:input>
    <p:with-option name="status-dir-uri" select="$status-dir-uri"/>
  </tr:simple-progress-msg>
  
  <p:xslt name="conf2xsl">
    <p:documentation>This step generates a stylesheet from the xml2tex 
      mapping instructions. The rules are converted to XSL templates.</p:documentation>
    <p:input port="stylesheet">
      <p:document href="../xsl/xml2tex.xsl"/>
    </p:input>
    <p:input port="source">
      <p:pipe port="result" step="load-config"/>
    </p:input>
    <p:with-param name="debug" select="$debug"/>
    <p:with-param name="debug-dir-uri" select="$debug-dir-uri"/>
  </p:xslt>
  
  <tr:store-debug name="debug-conf" extension="xsl">
    <p:with-option name="pipeline-step" select="concat($prefix, '1.config')"/>
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
  
  <p:choose name="resolve-tables-or-normalize">
    <p:when test="$nested-tables eq 'yes'">
      <tr:normalize-calstables name="normalize-calstables"/>
    </p:when>
    <p:otherwise>
      <tr:resolve-nested-calstables name="normalize-calstables"/>
    </p:otherwise>
  </p:choose>
  
  <tr:store-debug name="debug-calstables">
    <p:with-option name="pipeline-step" select="concat($prefix, '2.normalize-calstables')"/>
    <p:with-option name="active" select="$debug"/>
    <p:with-option name="base-uri" select="$debug-dir-uri"/>
  </tr:store-debug>
  
  <p:sink/>
  
  <tr:load-cascaded name="load-cals2tabular-xsl" filename="xml2tex/xsl/template.html">
    <p:with-option name="fallback" select="resolve-uri('../xsl/calstable2tabular.xsl')"/>
    <p:input port="paths">
      <p:pipe port="paths" step="xml2tex"/>
    </p:input>
    <p:with-option name="debug" select="$debug"/>
    <p:with-option name="debug-dir-uri" select="$debug-dir-uri"/>
  </tr:load-cascaded>
  
  <p:xslt name="cals2tabular" template-name="main">
    <p:documentation>
      This stylesheet converts CALS tables to LaTeX tabular tables. The LaTeX Code is 
      inserted as "cals2tabular" processing instructions. 
    </p:documentation>
    <p:input port="stylesheet">
      <p:pipe port="result" step="load-cals2tabular-xsl"/>
    </p:input>
    <p:with-param name="table-model" select="$table-model"/>
    <p:with-param name="table-grid" select="$table-grid"/>
    <p:with-param name="debug" select="$debug"/>
    <p:with-param name="debug-dir-uri" select="$debug-dir-uri"/>
  </p:xslt>
  
  <tr:store-debug name="debug-cals2tabular">
    <p:with-option name="pipeline-step" select="concat($prefix, '3.cals2tabular')"/>
    <p:with-option name="active" select="$debug"/>
    <p:with-option name="base-uri" select="$debug-dir-uri"/>
  </tr:store-debug>
  
  <tr:simple-progress-msg file="xml2tex-convert-mml.txt" name="msg-3">
    <p:input port="msgs">
      <p:inline>
        <c:messages>
          <c:message xml:lang="en">Convert OMML equations to TeX</c:message>
          <c:message xml:lang="de">Konvertiere OMML-Formeln nach TeX</c:message>
        </c:messages>
      </p:inline>
    </p:input>
    <p:with-option name="status-dir-uri" select="$status-dir-uri"/>
  </tr:simple-progress-msg>
  
  <mml2tex:convert name="mml2tex">
    <p:documentation>
      MathML equations are converted to "mml2tex" processing instructions.
    </p:documentation>
    <p:with-option name="preprocessing" select="$preprocessing"/>    
    <p:with-option name="debug" select="$debug"/>
    <p:with-option name="debug-dir-uri" select="$debug-dir-uri"/>
  </mml2tex:convert>
  
  <tr:store-debug name="debug-mml2tex">
    <p:with-option name="pipeline-step" select="concat($prefix, '4.mml2tex')"/>
    <p:with-option name="active" select="$debug"/>
    <p:with-option name="base-uri" select="$debug-dir-uri"/>
  </tr:store-debug>
  
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
      <p:empty/>
    </p:input>
    <p:input port="models"><p:empty/></p:input>
    <p:with-option name="debug" select="$debug"/>
    <p:with-option name="debug-dir-uri" select="$debug-dir-uri"/>
    <p:with-option name="fail-on-error" select="$fail-on-error"/>
    <p:with-option name="prefix" select="concat($prefix, '6')"/>
  </tr:xslt-mode>
  
  <tr:xslt-mode msg="yes" mode="apply-regex" name="apply-regex">
    <p:input port="stylesheet">
      <p:pipe port="result" step="conf2xsl"/>
    </p:input>
    <p:input port="parameters">
      <p:empty/>
    </p:input>
    <p:input port="models"><p:empty/></p:input>
    <p:with-option name="debug" select="$debug"/>
    <p:with-option name="debug-dir-uri" select="$debug-dir-uri"/>
    <p:with-option name="fail-on-error" select="$fail-on-error"/>
    <p:with-option name="prefix" select="concat($prefix, '7')"/>
  </tr:xslt-mode>
  
  <tr:xslt-mode msg="yes" mode="replace-chars" name="replace-chars">
    <p:input port="stylesheet">
      <p:pipe port="result" step="conf2xsl"/>
    </p:input>
    <p:input port="parameters">
      <p:empty/>
    </p:input>
    <p:input port="models"><p:empty/></p:input>
    <p:with-option name="debug" select="$debug"/>
    <p:with-option name="debug-dir-uri" select="$debug-dir-uri"/>
    <p:with-option name="fail-on-error" select="$fail-on-error"/>
    <p:with-option name="prefix" select="concat($prefix, '9')"/>
  </tr:xslt-mode>
  
  <tr:xslt-mode msg="yes" mode="dissolve-pi" name="dissolve-pi">
    <p:input port="stylesheet">
      <p:pipe port="result" step="conf2xsl"/>
    </p:input>
    <p:input port="parameters">
      <p:empty/>
    </p:input>
    <p:input port="models"><p:empty/></p:input>
    <p:with-option name="debug" select="$debug"/>
    <p:with-option name="debug-dir-uri" select="$debug-dir-uri"/>
    <p:with-option name="fail-on-error" select="$fail-on-error"/>
    <p:with-option name="prefix" select="concat($prefix, '10')"/>
  </tr:xslt-mode>
  
  <tr:xslt-mode msg="yes" mode="apply-xpath" name="apply-xpath">
    <p:input port="stylesheet">
      <p:pipe port="result" step="conf2xsl"/>
    </p:input>
    <p:input port="parameters">
      <p:empty/>
    </p:input>
    <p:input port="models"><p:empty/></p:input>
    <p:with-option name="debug" select="$debug"/>
    <p:with-option name="debug-dir-uri" select="$debug-dir-uri"/>
    <p:with-option name="fail-on-error" select="$fail-on-error"/>
    <p:with-option name="prefix" select="concat($prefix, '11')"/>
  </tr:xslt-mode>
  
  <tr:xslt-mode msg="yes" mode="clean" name="clean">
    <p:input port="stylesheet">
      <p:pipe port="result" step="conf2xsl"/>
    </p:input>
    <p:input port="parameters">
      <p:empty/>
    </p:input>
    <p:input port="models"><p:empty/></p:input>
    <p:with-option name="debug" select="$debug"/>
    <p:with-option name="debug-dir-uri" select="$debug-dir-uri"/>
    <p:with-option name="fail-on-error" select="$fail-on-error"/>
    <p:with-option name="prefix" select="concat($prefix, '12')"/>
  </tr:xslt-mode>
  
</p:declare-step>
