<?xml version="1.0" encoding="UTF-8"?>
<p:declare-step 
  xmlns:p="http://www.w3.org/ns/xproc"
  xmlns:c="http://www.w3.org/ns/xproc-step" 
  xmlns:cx="http://xmlcalabash.com/ns/extensions"
  xmlns:tr="http://transpect.io"
  xmlns:xml2tex="http://transpect.io/xml2tex"
  version="1.0" 
  name="xml2tex" 
  type="xml2tex:convert">
  
  <p:input port="source" primary="true">
    <p:empty/>
  </p:input>
  <p:input port="conf" primary="false">
    <p:empty/>
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
  
  <p:option name="fail-on-error" select="'true'">
    <p:documentation>
      Whether the pipeline should fail on some errors.
    </p:documentation>
  </p:option>
  
  <p:option name="grid" select="'yes'" required="false">
    <p:documentation>
      Draw table cell borders.
    </p:documentation>
  </p:option>
  
  <p:option name="prefix" select="'xml2tex/xml2tex0'">
    <p:documentation>
      Prefix for debug files.
    </p:documentation>
  </p:option>
  
  <p:import href="http://xmlcalabash.com/extension/steps/library-1.0.xpl"/>
  <p:import href="http://transpect.io/xproc-util/store-debug/xpl/store-debug.xpl"/>
  <p:import href="http://transpect.io/xproc-util/simple-progress-msg/xpl/simple-progress-msg.xpl"/>
  <p:import href="http://transpect.io/xproc-util/xslt-mode/xpl/xslt-mode.xpl"/>
  
  <!--  *
        * validate the configuration file.
        * -->
  <p:validate-with-relax-ng>
    <p:input port="schema">
      <p:document href="../schema/xml2tex.rng"/>
    </p:input>
    <p:input port="source">
      <p:pipe port="conf" step="xml2tex"/>
    </p:input>
    <p:with-option name="assert-valid" select="$fail-on-error"/>
  </p:validate-with-relax-ng>
  
  <tr:simple-progress-msg file="xml2tex-validate-config.txt">
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
      <p:pipe port="conf" step="xml2tex"/>
    </p:input>
    <p:with-param name="debug" select="$debug"/>
    <p:with-param name="debug-dir-uri" select="$debug-dir-uri"/>
  </p:xslt>
  
  <tr:store-debug pipeline-step="xml2tex/conf2xsl">
    <p:with-option name="extension" select="'xsl'"/>
    <p:with-option name="active" select="$debug"/>
    <p:with-option name="base-uri" select="$debug-dir-uri"/>
  </tr:store-debug>
  
  <tr:simple-progress-msg file="xml2tex-convert-tables.txt">
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
  
  <p:xslt name="normalize-calstables">
    <p:documentation>Rowspans and Colspans are dissolved and filled with empty cells. 
      This facilitates the conversion of CALS tables to LaTeX tabular tables. The graphic 
      below gives an example:
      
      -------------------             -------------------
      |  A  |  B        |             |  A  |  B  |  b  |
      -     -           -             -------------------
      |     |           |     -->     |  a  |  b  |  b  |
      -------------------             -------------------
      |  C  |  D        |             |  C  |  D  |  d  |
      -------------------             -------------------
      
    </p:documentation>
    <p:input port="source">
      <p:pipe port="source" step="xml2tex"/>
    </p:input>
    <p:input port="stylesheet">
      <p:document href="../xsl/calstable-normalize.xsl"/>
    </p:input>
    <p:with-param name="debug" select="$debug"/>
    <p:with-param name="debug-dir-uri" select="$debug-dir-uri"/>
  </p:xslt>
  
  <tr:store-debug pipeline-step="xml2tex/normalize-calstables">
    <p:with-option name="active" select="$debug"/>
    <p:with-option name="base-uri" select="$debug-dir-uri"/>
  </tr:store-debug>
  
  <p:xslt name="cals2tabular" template-name="main">
    <p:documentation>
      This stylesheet converts CALS tables to LaTeX tabular tables. The LaTeX Code is 
      inserted as "cals2tabular" processing instructions. 
    </p:documentation>
    <p:input port="stylesheet">
      <p:document href="../xsl/calstable2tabular.xsl"/>
    </p:input>
    <p:with-param name="debug" select="$debug"/>
    <p:with-param name="debug-dir-uri" select="$debug-dir-uri"/>
    <p:with-param name="grid" select="$grid"/>
  </p:xslt>
  
  <tr:store-debug pipeline-step="xml2tex/cals2tabular">
    <p:with-option name="active" select="$debug"/>
    <p:with-option name="base-uri" select="$debug-dir-uri"/>
  </tr:store-debug>
  
  <tr:simple-progress-msg file="xml2tex-convert-mml.txt">
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
  
  <p:xslt name="mml2tex">
    <p:documentation>
      MathML equations are converted to "mml2tex" processing instructions.
    </p:documentation>    
    <p:input port="stylesheet">
      <p:document href="../xsl/mml2tex.xsl"/>
    </p:input>
    <p:with-param name="debug" select="$debug"/>
    <p:with-param name="debug-dir-uri" select="$debug-dir-uri"/>
  </p:xslt>
  
  <tr:store-debug pipeline-step="xml2tex/mml2tex">
    <p:with-option name="active" select="$debug"/>
    <p:with-option name="base-uri" select="$debug-dir-uri"/>
  </tr:store-debug>
  
  <tr:simple-progress-msg file="xml2tex-convert-xml.txt">
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
    
  <tr:xslt-mode msg="yes" hub-version="1.1" mode="escape-bad-chars" name="escape-bad-chars">
    <p:input port="stylesheet">
      <p:pipe port="result" step="conf2xsl"/>
    </p:input>
    <p:input port="parameters">
      <p:empty/>
    </p:input>
    <p:input port="models"><p:empty/></p:input>
    <p:with-option name="debug" select="$debug"/>
    <p:with-option name="debug-dir-uri" select="$debug-dir-uri"/>
    <p:with-option name="prefix" select="concat($prefix, '1')"/>
  </tr:xslt-mode>
  
  <tr:xslt-mode msg="yes" hub-version="1.1" mode="apply-regex" name="apply-regex">
    <p:input port="stylesheet">
      <p:pipe port="result" step="conf2xsl"/>
    </p:input>
    <p:input port="parameters">
      <p:empty/>
    </p:input>
    <p:input port="models"><p:empty/></p:input>
    <p:with-option name="debug" select="$debug"/>
    <p:with-option name="debug-dir-uri" select="$debug-dir-uri"/>
    <p:with-option name="prefix" select="concat($prefix, '2')"/>
  </tr:xslt-mode>
  
  <tr:xslt-mode msg="yes" hub-version="1.1" mode="replace-chars-specific" name="replace-chars-specific">
    <p:input port="stylesheet">
      <p:pipe port="result" step="conf2xsl"/>
    </p:input>
    <p:input port="parameters">
      <p:empty/>
    </p:input>
    <p:input port="models"><p:empty/></p:input>
    <p:with-option name="debug" select="$debug"/>
    <p:with-option name="debug-dir-uri" select="$debug-dir-uri"/>
    <p:with-option name="prefix" select="concat($prefix, '3')"/>
  </tr:xslt-mode>
  
  <tr:xslt-mode msg="yes" hub-version="1.1" mode="replace-chars-general" name="replace-chars-general">
    <p:input port="stylesheet">
      <p:pipe port="result" step="conf2xsl"/>
    </p:input>
    <p:input port="parameters">
      <p:empty/>
    </p:input>
    <p:input port="models"><p:empty/></p:input>
    <p:with-option name="debug" select="$debug"/>
    <p:with-option name="debug-dir-uri" select="$debug-dir-uri"/>
    <p:with-option name="prefix" select="concat($prefix, '4')"/>
  </tr:xslt-mode>
  
  <tr:xslt-mode msg="yes" hub-version="1.1" mode="dissolve-pi" name="dissolve-pi">
    <p:input port="stylesheet">
      <p:pipe port="result" step="conf2xsl"/>
    </p:input>
    <p:input port="parameters">
      <p:empty/>
    </p:input>
    <p:input port="models"><p:empty/></p:input>
    <p:with-option name="debug" select="$debug"/>
    <p:with-option name="debug-dir-uri" select="$debug-dir-uri"/>
    <p:with-option name="prefix" select="concat($prefix, '5')"/>
  </tr:xslt-mode>
  
  <tr:xslt-mode msg="yes" hub-version="1.1" mode="apply-xpath" name="apply-xpath">
    <p:input port="stylesheet">
      <p:pipe port="result" step="conf2xsl"/>
    </p:input>
    <p:input port="parameters">
      <p:empty/>
    </p:input>
    <p:input port="models"><p:empty/></p:input>
    <p:with-option name="debug" select="$debug"/>
    <p:with-option name="debug-dir-uri" select="$debug-dir-uri"/>
    <p:with-option name="prefix" select="concat($prefix, '6')"/>
  </tr:xslt-mode>
  
</p:declare-step>