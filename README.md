# xml2tex
11;rgb:1313/1515/1a1aConverts XML to LaTeX

## configuration

xml2tex can be configured for any kind of XML format.
A sample XML configuration file is stored in the `example` directory.

A RelaxNG schema is located in the `schema` directory. You can use
the schema to check if your configuration file is valid. You can also
use this schema in XML editors such as oXygen to have code completion and
tool tips.

Here is an example for a very basic configuration:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<?xml-model href="../schema/xml2tex.rng" type="application/xml" schematypens="http://relaxng.org/ns/structure/1.0"?>
<?xml-model href="../schema/xml2tex.rng" type="application/xml" schematypens="http://purl.oclc.org/dsdl/schematron"?>
<set xmlns="http://transpect.io/xml2tex">

  <ns prefix="dbk" uri="http://docbook.org/ns/docbook"/>

  <preamble>
    \documentclass{scrbook}
    \usepackage{graphicx}
    \usepackage{hyperref}
    \usepackage{multirow}
  </preamble>

  <front>
    \maketitle
  </front>

  <back>
    \printindex
  </back>

  <template context="dbk:para[not(parent::dbk:entry)][not(parent::dbk:footnote)]">
    <rule break-after="2">
      <text/>
    </rule>
  </template>

  <template context="dbk:para[@role eq 'Zitat']">
    <rule type="env" name="quote">
      <text/>
    </rule>
  </template>
  
  <charmap>
    <char character="&#xad;" string="&quot;-"/>
    <char character="Ä" string="\&#34;A" context="dbk:phrase, dbk:section|dbk:para, dbk:entry"/>
    <char character="ä" string="\&#34;a"/>
    <char character="Ö" string="\&#34;O"/>
    <char character="ö" string="\&#34;o" />
    <char character="Ü" string="\&#34;U" />
    <char character="ü" string="\&#34;u" />
    <char character="ß" string="\ss{}" />
    <char character="…" string="..." />
  </charmap>
</set>
```
### Preamble
The LaTeX preamble is constructed with the `preamble` element. Enter static text such as document class name, package
declarations and other stuff you may need.
```xml
<preamble>
    \documentclass{scrbook}
    \usepackage{graphicx}
    \usepackage{hyperref}
    \usepackage{multirow}
    \usepackage{amsmath}
    \usepackage{amssymb}
</preamble>
```

### Frontmatter

If you want to put content after `\begin{document}` but before the XML is inserted, you can do this with the `front` element.
Typical use cases might be the creation of a frontmatter. If you do not want to add static content, you can help yourself
with a few bits of XSLT as shown below:

```xml
<front>
    \title{<xsl:value-of select="title"/>}
    \date{<xsl:value-of select="info/date"/>}
    \author{<xsl:value-of select="info/author"/>}
</front>
```

### Backmatter

If you want to put content right before \end{document}, you can use the `back` element for this purpose.

```xml
<back>
    \printindex
</back>
```

### XML namespaces
If your XML input document use XML namespaces, it's necessary to declare each namespace with a corresponding `ns` element.
```xml
<ns prefix="dbk" uri="http://docbook.org/ns/docbook"/>
<ns prefix="css" uri="http://www.w3.org/1996/css"/>
```
Don't forget to use the declared namespace prefixes in the XPath expression of the context attribute. If a template don't match the considered XML nodes, it could be caused by a wrong namespace. 
* wrong: `context="para"`
* right: `context="dbk:para"`

### Templates and Rules

#### Templates

Templates are considered to match a certain XML node with a XPath expression and convert its contents according to a Rule statement into a LaTeX instruction. A template is specified with a `template` element.

```xml
<template context="dbk:para[@role = ('heading1')]">
    <rule type="cmd" name="chapter" break-after="1">
      <param/>
    </rule>
</template>
```
The `@context` attribute is used to specify the XML node which is processed by the template. 

A Template can contain zero or one `rule` child element. If no `rule` exists, the XML node specified by the  `@context` attribute is dropped.

Given this XML element…
```xml
<para xmlns="http://docbook.org/ns/docbook" @role="heading1">my headline</para>
```
…the template above would generate this LaTeX code:
```xml
\chapter{my headline}
```

#### Rules
A rule is declared as child element named `rule` and is used to specify the LaTeX instruction.

```xml
<rule type="cmd" name="chapter" break-after="1">
  <param/>
</rule>
```

The value of the `@type` attribute specifies the certain type of the LaTeX instruction. Permitted values are `cmd` for instructions such as `\chapter` and `env` for environments such as `\begin{itemize} … \end{itemize}`.

The `@name` attribute describes the name of the LaTeX instruction.

`@break-after` is used to control the line breaks after the element. This attribute is necessary to control the whitespace after regular paragraphs.

#### Parameters, Options and Text
A rule can contain three child elements: `text`, `param`, `option`, which define how the content of the current XML node is wrapped. The `param` element specifies that the contents of the current context XML node is wrapped with curly braces `{}`. `option` is used to wrap the content with brackets `[]`, hence `text` process it without any wrapper.

Each of these elements can contain a `@select` attribute. This attribute is optional and can be used to select a specific XML node within the current XML context. The example below shows how to use the `@select` attribute to construct the parameters of a LaTeX link instruction.
```xml
<template context="dbk:link">
  <rule type="cmd" name="href">
    <param select="@xlink:href"/>
    <param select="dbk:phrase"/>
  </rule>
</template>
```

### Regular Expressions
Insted of templates, you can also use regular expressions to construct a LaTeX instruction. Therefore, you can use the element `regex` and specify a regular expressions with the `@regex` attribute.

If you want to use groups in your matching pattern, you can specify the optional attribute`regex-group` to select a specific  group. The example below shows how to construct a date makro with regular expressions.
```xml
<regex regex="(\d{2})\.(\d{2})\.(\d{4})">
  <rule type="cmd" name="date">
    <param regex-group="1"/>
    <param regex-group="2"/>
    <param regex-group="3"/>
  </rule>
</regex>
```

### Character Maps
Some LaTeX processors are only able to handle constrained character sets. Therefore it is recommended to include a character map in your configuration and map certain characters to LaTeX instructions. 

A character map is wrapped by a `charmap` element. It can contain multiple character mapping entries, each specified with a `char` element. The attribute `@character` contains the character to be replaced with the value of `@string`. An optional `@context` attribute can be used to restrict the replacement to a certain XML context.
```xml
<charmap>
	<char character="&#xad;" string="&quot;-"/>
  <char character="Ä" string="\&#34;A" context="dbk:phrase, dbk:section|dbk:para, dbk:entry"/>
  <char character="ä" string="\&#34;a"/>
  <char character="Ö" string="\&#34;O"/>
  <char character="ö" string="\&#34;o" />
  <char character="Ü" string="\&#34;U" />
  <char character="ü" string="\&#34;u" />
  <char character="ß" string="\ss{}" />
</charmap>
```
### Import other configurations

In most cases it's more applicable to import an existing configuration than to write a new one from scratch or fork an existing one. There is a convenient method for importing other configurations. You just have to add at the top of your configuration an import statement which points to the location of the imported configuration. Here is an example:


```xml
<set xmlns="http://transpect.io/xml2tex">

  <import href="../conf/default.xml"/>
  <!-- (...) -->
</set>
```

Naturally, the configuration with the import statement has always precedence before the imported configuration. Please note that in case of character maps, you can selectively overwrite single `char` mappings.

### Inline XSLT

You are allowed to use XSLT elements \(XSLT template model\) inside of the xml2tex configuration elements `preamble`, `text`, `option`, `param` elements. This might be useful if you want to apply other markup based on dynamic evaluations of the processed content.

```
<preamble>
  <!-- use german babel package when document language is 'de' -->
  <xsl:if test="/*/@xml:lang eq 'de'">
    <xsl:text>\usepackage[ngerman]{babel}</xsl:text>
  </xsl:if>
<preamble>
```

## MathML

Equations specified in MathML syntax are automatically converted with the module [mml2tex](https://github.com/transpect/mml2tex).

## Tables

CALS tables are converted automatically converted to tabular tables. A XSLT stylesheet which converts also HTML tables is considered for a later release.
