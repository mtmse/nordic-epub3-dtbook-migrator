<?xml version="1.0" encoding="UTF-8"?>
<p:declare-step xmlns:p="http://www.w3.org/ns/xproc" xmlns:c="http://www.w3.org/ns/xproc-step" xmlns:px="http://www.daisy.org/ns/pipeline/xproc" xmlns:d="http://www.daisy.org/ns/pipeline/data"
    type="px:nordic-epub3-validate" name="main" version="1.0" xmlns:epub="http://www.idpf.org/2007/ops" xmlns:pxp="http://exproc.org/proposed/steps" xmlns:html="http://www.w3.org/1999/xhtml"
    xmlns:pxi="http://www.daisy.org/ns/pipeline/xproc/internal/nordic-epub3-dtbook-migrator" xmlns:cx="http://xmlcalabash.com/ns/extensions">

    <p:documentation xmlns="http://www.w3.org/1999/xhtml">
        <h1 px:role="name">Nordic EPUB3 Validator</h1>
        <p px:role="desc">Validates an EPUB3 publication according to the nordic markup guidelines.</p>
    </p:documentation>

    <p:option name="epub" required="true" px:type="anyFileURI" px:media-type="application/epub+zip">
        <p:documentation xmlns="http://www.w3.org/1999/xhtml">
            <h2 px:role="name">EPUB3 Publication</h2>
            <p px:role="desc">EPUB3 Publication marked up according to the nordic markup guidelines.</p>
        </p:documentation>
    </p:option>

    <p:option name="temp-dir" required="true" px:output="temp" px:type="anyDirURI">
        <p:documentation xmlns="http://www.w3.org/1999/xhtml">
            <h2 px:role="name">Temporary directory</h2>
            <p px:role="desc">Temporary directory for use by the script.</p>
        </p:documentation>
    </p:option>

    <p:option name="html-report" required="true" px:output="result" px:type="anyDirURI" px:media-type="application/vnd.pipeline.report+xml">
        <p:documentation xmlns="http://www.w3.org/1999/xhtml">
            <h1 px:role="name">HTML Report</h1>
            <p px:role="desc">An HTML-formatted version of the validation report.</p>
        </p:documentation>
    </p:option>

    <p:output port="validation-status" px:media-type="application/vnd.pipeline.status+xml">
        <p:documentation xmlns="http://www.w3.org/1999/xhtml">
            <h1 px:role="name">Validation status</h1>
            <p px:role="desc">Validation status (http://code.google.com/p/daisy-pipeline/wiki/ValidationStatusXML).</p>
        </p:documentation>
        <p:pipe port="result" step="epub3-validate.status"/>
    </p:output>

    <p:import href="step/epub3-validate.step.xpl"/>
    <p:import href="step/validation-status.xpl"/>
    <p:import href="step/format-html-report.xpl"/>
    <p:import href="upstream/file-utils/xproc/set-doctype.xpl"/>
    <!--<p:import href="http://www.daisy.org/pipeline/modules/file-utils/library.xpl"/>-->
    <p:import href="upstream/fileset-utils/fileset-load.xpl"/>
    <p:import href="upstream/fileset-utils/fileset-add-entry.xpl"/>
    <p:import href="http://www.daisy.org/pipeline/modules/fileset-utils/library.xpl"/>
    <p:import href="http://www.daisy.org/pipeline/modules/common-utils/library.xpl"/>

    <px:message message="$1" name="epub3-validate.nordic-version-message">
        <p:with-option name="param1" select="/*">
            <p:document href="../version-description.xml"/>
        </p:with-option>
    </px:message>

    <px:fileset-create cx:depends-on="epub3-validate.nordic-version-message" name="epub3-validate.create-epub-fileset">
        <p:with-option name="base" select="replace($epub,'[^/]+$','')"/>
    </px:fileset-create>
    <pxi:fileset-add-entry media-type="application/epub+zip" name="epub3-validate.add-epub-to-fileset">
        <p:with-option name="href" select="replace($epub,'^.*/([^/]*)$','$1')"/>
    </pxi:fileset-add-entry>

    <px:nordic-epub3-validate.step name="epub3-validate.validate.nordic" fail-on-error="true">
        <p:with-option name="temp-dir" select="concat($temp-dir,'validate/')"/>
    </px:nordic-epub3-validate.step>
    <pxi:fileset-load media-types="application/xhtml+xml" name="epub3-validate.load-epub-xhtml">
        <p:input port="in-memory">
            <p:pipe port="in-memory.out" step="epub3-validate.validate.nordic"/>
        </p:input>
    </pxi:fileset-load>
    <p:xslt name="epub3-validate.info-report">
        <p:input port="parameters">
            <p:empty/>
        </p:input>
        <p:input port="stylesheet">
            <p:document href="../xslt/info-report.xsl"/>
        </p:input>
    </p:xslt>
    <p:identity name="epub3-validate.report.nordic"/>
    <p:sink/>

    <px:nordic-format-html-report name="epub3-validate.html">
        <p:input port="source">
            <p:pipe port="report.out" step="epub3-validate.validate.nordic"/>
            <p:pipe port="result" step="epub3-validate.report.nordic"/>
        </p:input>
    </px:nordic-format-html-report>
    <p:store include-content-type="false" method="xhtml" omit-xml-declaration="false" name="epub3-validate.store-report">
        <p:with-option name="href" select="concat($html-report,if (ends-with($html-report,'/')) then '' else '/','report.xhtml')"/>
    </p:store>
    <pxi:set-doctype doctype="&lt;!DOCTYPE html&gt;" name="epub3-validate.set-report-doctype">
        <p:with-option name="href" select="/*/text()">
            <p:pipe port="result" step="epub3-validate.store-report"/>
        </p:with-option>
    </pxi:set-doctype>
    <p:sink/>

    <px:nordic-validation-status name="epub3-validate.status">
        <p:input port="source">
            <p:pipe port="report.out" step="epub3-validate.validate.nordic"/>
        </p:input>
    </px:nordic-validation-status>
    <p:sink/>

</p:declare-step>
