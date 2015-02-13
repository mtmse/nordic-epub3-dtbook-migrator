<?xml version="1.0" encoding="UTF-8"?>
<p:declare-step xmlns:p="http://www.w3.org/ns/xproc" xmlns:c="http://www.w3.org/ns/xproc-step" xmlns:px="http://www.daisy.org/ns/pipeline/xproc" xmlns:d="http://www.daisy.org/ns/pipeline/data"
    type="px:nordic-dtbook-to-html" name="main" version="1.0" xmlns:epub="http://www.idpf.org/2007/ops" xmlns:l="http://xproc.org/library" xmlns:dtbook="http://www.daisy.org/z3986/2005/dtbook/"
    xmlns:html="http://www.w3.org/1999/xhtml" xmlns:cx="http://xmlcalabash.com/ns/extensions" xmlns:pxi="http://www.daisy.org/ns/pipeline/xproc/internal/nordic-epub3-dtbook-migrator">

    <p:documentation xmlns="http://www.w3.org/1999/xhtml">
        <h1 px:role="name">Nordic DTBook to HTML</h1>
        <p px:role="desc">Transforms a DTBook document into an single HTML file according to the nordic markup guidelines.</p>
    </p:documentation>

    <p:output port="html-report" px:media-type="application/vnd.pipeline.report+xml">
        <p:documentation xmlns="http://www.w3.org/1999/xhtml">
            <h1 px:role="name">HTML Report</h1>
            <p px:role="desc">An HTML-formatted version of the validation report.</p>
        </p:documentation>
        <p:pipe port="result" step="html-report"/>
    </p:output>

    <p:output port="validation-status" px:media-type="application/vnd.pipeline.status+xml">
        <p:documentation xmlns="http://www.w3.org/1999/xhtml">
            <h1 px:role="name">Validation status</h1>
            <p px:role="desc">Validation status (http://code.google.com/p/daisy-pipeline/wiki/ValidationStatusXML).</p>
        </p:documentation>
        <p:pipe port="status.out" step="html-validate"/>
    </p:output>

    <p:option name="dtbook" required="true" px:type="anyFileURI" px:media-type="application/x-dtbook+xml">
        <p:documentation xmlns="http://www.w3.org/1999/xhtml">
            <h2 px:role="name">DTBook</h2>
            <p px:role="desc">Input DTBook to be converted.</p>
        </p:documentation>
    </p:option>

    <p:option name="output-dir" required="true" px:output="result" px:type="anyDirURI">
        <p:documentation xmlns="http://www.w3.org/1999/xhtml">
            <h2 px:role="name">Output directory</h2>
            <p px:role="desc">Output directory for the HTML file and its resources (images, stylesheets, etc).</p>
        </p:documentation>
    </p:option>

    <p:option name="assert-valid" required="false" select="'true'" px:type="boolean">
        <p:documentation xmlns="http://www.w3.org/1999/xhtml">
            <h2 px:role="name">Stop processing on validation error</h2>
            <p px:role="desc">Whether or not to stop the conversion when a validation error occurs. Setting this to false may be useful for debugging or if the validation error is a minor one. The
                output is not guaranteed to be valid if this option is set to false.</p>
        </p:documentation>
    </p:option>

    <p:option name="no-legacy" required="false" px:type="boolean" select="'true'">
        <p:documentation xmlns="http://www.w3.org/1999/xhtml">
            <h2 px:role="name">Disallow legacy markup</h2>
            <p px:role="desc">If set to false, will upgrade DTBook versions earlier than 2005-3 to 2005-3, and fix some non-standard practices that appear in older DTBooks.</p>
        </p:documentation>
    </p:option>

    <p:import href="library.xpl"/>
    <p:import href="http://www.daisy.org/pipeline/modules/fileset-utils/library.xpl"/>
    <p:import href="http://www.daisy.org/pipeline/modules/common-utils/library.xpl"/>

    <p:variable name="dtbook-href" select="resolve-uri($dtbook,base-uri(/*))">
        <p:inline>
            <irrelevant/>
        </p:inline>
    </p:variable>

    <px:message message="$1" name="nordic-version-message">
        <p:with-option name="param1" select="/*">
            <p:document href="../version-description.xml"/>
        </p:with-option>
    </px:message>

    <px:nordic-dtbook-validate.step name="dtbook-validate" check-images="true" cx:depends-on="nordic-version-message">
        <p:with-option name="dtbook" select="$dtbook-href"/>
        <p:with-option name="allow-legacy" select="if ($no-legacy='false') then 'true' else 'false'"/>
    </px:nordic-dtbook-validate.step>

    <px:nordic-dtbook-to-html.step name="dtbook-to-html">
        <p:input port="in-memory.in">
            <p:pipe port="in-memory.out" step="dtbook-validate"/>
        </p:input>
        <p:input port="report.in">
            <p:pipe port="report.out" step="dtbook-validate"/>
        </p:input>
        <p:input port="status.in">
            <p:pipe port="status.out" step="dtbook-validate"/>
        </p:input>
        <p:with-option name="temp-dir" select="$output-dir"/>
    </px:nordic-dtbook-to-html.step>

    <px:nordic-html-store.step name="html-store">
        <p:input port="in-memory.in">
            <p:pipe port="in-memory.out" step="dtbook-to-html"/>
        </p:input>
        <p:input port="report.in">
            <p:pipe port="report.out" step="dtbook-to-html"/>
        </p:input>
        <p:input port="status.in">
            <p:pipe port="status.out" step="dtbook-to-html"/>
        </p:input>
    </px:nordic-html-store.step>

    <px:nordic-html-validate.step name="html-validate" document-type="Nordic HTML (single-document)">
        <p:input port="in-memory.in">
            <p:pipe port="in-memory.out" step="html-store"/>
        </p:input>
        <p:input port="report.in">
            <p:pipe port="report.out" step="html-store"/>
        </p:input>
        <p:input port="status.in">
            <p:pipe port="status.out" step="html-store"/>
        </p:input>
    </px:nordic-html-validate.step>
    <p:sink/>

    <px:nordic-format-html-report>
        <p:input port="reports">
            <p:pipe port="report.out" step="html-validate"/>
        </p:input>
    </px:nordic-format-html-report>
    <p:xslt>
        <!-- pretty print to make debugging easier -->
        <p:with-param name="preserve-empty-whitespace" select="'false'"/>
        <p:input port="stylesheet">
            <p:document href="../xslt/pretty-print.xsl"/>
        </p:input>
    </p:xslt>
    <p:identity name="html-report"/>

</p:declare-step>
