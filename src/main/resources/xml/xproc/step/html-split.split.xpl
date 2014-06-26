<?xml version="1.0" encoding="UTF-8"?>
<p:declare-step xmlns:p="http://www.w3.org/ns/xproc" xmlns:c="http://www.w3.org/ns/xproc-step" xmlns:px="http://www.daisy.org/ns/pipeline/xproc" xmlns:d="http://www.daisy.org/ns/pipeline/data"
    type="px:nordic-html-split-perform" name="main" version="1.0" xmlns:epub="http://www.idpf.org/2007/ops" xmlns:dtbook="http://www.daisy.org/z3986/2005/dtbook/"
    xmlns:html="http://www.w3.org/1999/xhtml" xmlns:pxi="http://www.daisy.org/ns/pipeline/xproc/internal/nordic-epub3-dtbook-migrator">

    <p:input port="fileset.in" primary="true"/>
    <p:input port="in-memory.in" sequence="true"/>

    <p:output port="fileset.out" primary="true">
        <p:pipe port="result" step="fileset.result"/>
    </p:output>
    <p:output port="in-memory.out" sequence="true">
        <p:pipe port="result" step="in-memory.html"/>
    </p:output>

    <p:identity>
        <p:input port="source">
            <p:inline>
                <wrapper>
                    <html:html/>
                </wrapper>
            </p:inline>
        </p:input>
    </p:identity>
    <p:identity name="html"/>

    <p:xslt>
        <p:with-param name="output-dir" select="replace(base-uri(/*),'[^/]+$','')">
            <p:pipe port="result" step="html"/>
        </p:with-param>
        <p:input port="stylesheet">
            <p:document href="../../xslt/split-html.annotate.xsl"/>
        </p:input>
    </p:xslt>
    
    <p:add-attribute match="/*" attribute-name="xml:base">
        <p:with-option name="attribute-value" select="replace(base-uri(/*),'[^/]+$','')"/>
        <p:input port="source">
            <p:inline>
                <d:fileset>
                    <d:file/>
                </d:fileset>
            </p:inline>
        </p:input>
    </p:add-attribute>
    <p:add-attribute match="/*/*" attribute-name="href">
        <p:with-option name="attribute-value" select="replace(base-uri(/*),'^.*/([^/]+)$','$1')"/>
    </p:add-attribute>
    <p:add-attribute match="//d:file" attribute-name="omit-xml-declaration" attribute-value="false"/>
    <p:add-attribute match="//d:file" attribute-name="version" attribute-value="1.0"/>
    <p:add-attribute match="//d:file" attribute-name="encoding" attribute-value="utf-8"/>
    <p:add-attribute match="//d:file" attribute-name="method" attribute-value="xhtml"/>
    <p:add-attribute match="//d:file" attribute-name="indent" attribute-value="true"/>
    <p:identity name="for-each.fileset"/>
    <!--</p:for-each>-->
    <p:identity name="in-memory.html"/>
    <p:sink/>

    <p:identity>
        <p:input port="source">
            <p:pipe port="result" step="for-each.fileset"/>
        </p:input>
    </p:identity>
    <p:identity name="fileset.result"/>

</p:declare-step>
