# xml2tex
Converts XML to LaTeX

Author: Martin Kraetke

## configuration

xml2tex can be configured for any kind of XML format. A sample XML configuration file is stored in the `example` directory.

A RelaxNG schema is located in the `schema` directory. You can use the RelaxNG schema to check if your configuration file is valid.

Here is an example for a very basic configuration:

```xml
<xml2tex:set xmlns:xml2tex="http://transpect.io/xml2tex">

  <xml2tex:preamble>
    \documentclass{scrbook}
    \usepackage{graphicx}
    \usepackage{hyperref}
    \usepackage{multirow}
  </xml2tex:preamble>
  
  <xml2tex:ns prefix="dbk" uri="http://docbook.org/ns/docbook"/>
  
  <xml2tex:template context="dbk:para[not(parent::dbk:entry)][not(parent::dbk:footnote)]">
    <xml2tex:rule break-after="2">
      <xml2tex:text/>
    </xml2tex:rule>
  </xml2tex:template>

  <xml2tex:template context="dbk:para[@role eq 'Zitat']">
    <xml2tex:rule type="env" name="quote">
      <xml2tex:text/>
    </xml2tex:rule>
  </xml2tex:template>
  
  <xml2tex:charmap>
  	<xml2tex:char character="&#xad;" string="&quot;-"/>
    <xml2tex:char character="Ä" string="\&#34;A" context="dbk:phrase, dbk:section|dbk:para, dbk:entry"/>
    <xml2tex:char character="ä" string="\&#34;a"/>
    <xml2tex:char character="Ö" string="\&#34;O"/>
    <xml2tex:char character="ö" string="\&#34;o" />
    <xml2tex:char character="Ü" string="\&#34;U" />
    <xml2tex:char character="ü" string="\&#34;u" />
    <xml2tex:char character="ß" string="\ss{}" />
    <xml2tex:char character="…" string="..." />
  </xml2tex:charmap>
</xml2tex:set>
```
### preamble
The LaTeX preamble is constructed with the `xml2tex:preamble` element. Enter static text such as document class name, package
declarations and other stuff you may need.
```xml
<xml2tex:preamble>
    \documentclass{scrbook}
    \usepackage{graphicx}
    \usepackage{hyperref}
    \usepackage{multirow}
    \usepackage{amsmath}
    \usepackage{amssymb}
</xml2tex:preamble>
```

### XML namespaces
If your XML input document use XML namespaces, it's necessary to declare each namespace with a corresponding `xml2tex:ns` element.
```xml
<xml2tex:ns prefix="dbk" uri="http://docbook.org/ns/docbook"/>
<xml2tex:ns prefix="css" uri="http://www.w3.org/1996/css"/>
```
Don't forget to use the declared namespace prefixes in the XPath expression of the context attribute. If a template don't match the considered XML nodes, it could be caused by a wrong namespace. 
* wrong: `context="para"`
* right: `context="dbk:para"`

### Templates and Rules

#### Templates

Templates are considered to match a certain XML node with a XPath expression and convert its contents according to a Rule statement into a LaTeX instruction. A template is specified with a `xml2tex:template` element.

```xml
<xml2tex:template context="dbk:para[@role = ('heading1')]">
    <xml2tex:rule type="cmd" name="chapter" break-after="1">
      <xml2tex:param/>
    </xml2tex:rule>
</xml2tex:template>
```
The `@context` attribute is used to specify the XML node which is processed by the template. 

A Template can contain zero or one `xml2tex:rule` child element. If no `xml2tex:rule` exists, the XML node specified by the  `@context` attribute is dropped.

Given this XML element…
```xml
<para xmlns="http://docbook.org/ns/docbook" @role="heading1">my headline</para>
```
…the template above would generate this LaTeX code:
```xml
\chapter{my headline}
```

#### Rules
A rule is declared as child element named `xml2tex:rule` and is used to specify the LaTeX instruction.

```xml
<xml2tex:rule type="cmd" name="chapter" break-after="1">
  <xml2tex:param/>
</xml2tex:rule>
```

The value of the `@type` attribute specifies the certain type of the LaTeX instruction. Permitted values are `cmd` for instructions such as `\chapter` and `env` for environments such as `\begin{itemize} … \end{itemize}`.

The `@name` attribute describes the name of the LaTeX instruction.

`@break-after` is used to control the line breaks after the element. This attribute is necessary to control the whitespace after regular paragraphs.

#### Parameters, Options and Text
A rule can contain three child elements: `xml2tex:text`, `xml2tex:param`, `xml2tex:option`, which define how the content of the current XML node is wrapped. The `xml2tex:param` element specifies that the contents of the current context XML node is wrapped with curly braces `{}`. `xml2tex:option` is used to wrap the content with brackets `[]`, hence `xml2tex:text` process it without any wrapper.

Each of these elements can contain a `@select` attribute. This attribute is optional and can be used to select a specific XML node within the current XML context. The example below shows how to use the `@select` attribute to construct the parameters of a LaTeX link instruction.
```xml
<xml2tex:template context="dbk:link">
  <xml2tex:rule type="cmd" name="href">
    <xml2tex:param select="@xlink:href"/>
    <xml2tex:param select="dbk:phrase"/>
  </xml2tex:rule>
</xml2tex:template>
```

### Regular Expressions
Insted of templates, you can also use regular expressions to construct a LaTeX instruction. Therefore, you can use the element `xml2tex:regex` and specify a regular expressions with the `@regex` attribute.

If you want to use groups in your matching pattern, you can specify the optional attribute`regex-group` to select a specific  group. The example below shows how to construct a date makro with regular expressions.
```xml
<xml2tex:regex regex="(\d{2})\.(\d{2})\.(\d{4})">
  <xml2tex:rule type="cmd" name="date">
    <xml2tex:param regex-group="1"/>
    <xml2tex:param regex-group="2"/>
    <xml2tex:param regex-group="3"/>
  </xml2tex:rule>
</xml2tex:regex>
```

### Character Maps
Some LaTeX processors are only able to handle constrained character sets. Therefore it is recommended to include a character map in your configuration and map certain characters to LaTeX instructions. 

A character map is wrapped by a `xml2tex:charmap` element. It can contain multiple character mapping entries, each specified with a `xml2tex:char` element. The attribute `@character` contains the character to be replaced with the value of `@string`. An optional `@context` attribute can be used to restrict the replacement to a certain XML context.
```xml
<xml2tex:charmap>
	<xml2tex:char character="&#xad;" string="&quot;-"/>
  <xml2tex:char character="Ä" string="\&#34;A" context="dbk:phrase, dbk:section|dbk:para, dbk:entry"/>
  <xml2tex:char character="ä" string="\&#34;a"/>
  <xml2tex:char character="Ö" string="\&#34;O"/>
  <xml2tex:char character="ö" string="\&#34;o" />
  <xml2tex:char character="Ü" string="\&#34;U" />
  <xml2tex:char character="ü" string="\&#34;u" />
  <xml2tex:char character="ß" string="\ss{}" />
</xml2tex:charmap>
```

## MathML
Equations specified in MathML syntax are automatically converted with the module [mml2tex](https://github.com/transpect/mml2tex).

## Tables
CALS tables are converted automatically converted to tabular tables. A XSLT stylesheet which converts also HTML tables is considered for a later release.
