<?xml version="1.0" encoding="UTF-8"?>
<p:declare-step xmlns:p="http://www.w3.org/ns/xproc" xmlns:c="http://www.w3.org/ns/xproc-step" xmlns:px="http://www.daisy.org/ns/pipeline/xproc" xmlns:d="http://www.daisy.org/ns/pipeline/data"
    type="px:nordic-epub3-validate.step" name="main" version="1.0" xmlns:epub="http://www.idpf.org/2007/ops" xmlns:html="http://www.w3.org/1999/xhtml" xmlns:opf="http://www.idpf.org/2007/opf"
    xmlns:pxi="http://www.daisy.org/ns/pipeline/xproc/internal/nordic-epub3-dtbook-migrator" xmlns:cx="http://xmlcalabash.com/ns/extensions" xmlns:dc="http://purl.org/dc/elements/1.1/"
    xmlns:dcterms="http://purl.org/dc/terms/" xmlns:dtb="http://www.daisy.org/z3986/2005/dtbook/" xmlns:jhove="http://hul.harvard.edu/ois/xml/ns/jhove">

    <p:serialization port="report.out" indent="true"/>

    <p:input port="fileset.in" primary="true">
        <p:empty/>
    </p:input>
    <p:input port="in-memory.in" sequence="true">
        <p:empty/>
    </p:input>
    <p:input port="report.in" sequence="true">
        <p:empty/>
    </p:input>
    <p:input port="status.in">
        <p:inline>
            <d:validation-status result="ok"/>
        </p:inline>
    </p:input>

    <p:output port="fileset.out" primary="true">
        <p:pipe port="fileset.out" step="choose"/>
    </p:output>
    <p:output port="in-memory.out" sequence="true">
        <p:pipe port="in-memory.out" step="choose"/>
    </p:output>
    <p:output port="report.out" sequence="true">
        <p:pipe port="report.in" step="main"/>
        <p:pipe port="report.out" step="choose"/>
    </p:output>
    <p:output port="status.out">
        <p:pipe port="result" step="status"/>
    </p:output>

    <p:option name="fail-on-error" select="'true'"/>
    <p:option name="temp-dir" required="true"/>

    <p:import href="validation-status.xpl"/>
    <p:import href="html-validate.step.xpl"/>
    <p:import href="read-xml-declaration.xpl"/>
    <p:import href="read-doctype-declaration.xpl"/>
    <p:import href="http://www.daisy.org/pipeline/modules/zip-utils/library.xpl"/>
    <p:import href="../upstream/fileset-utils/fileset-load.xpl"/>
    <!--<p:import href="../upstream/fileset-utils/fileset-add-entry.xpl"/>-->
    <p:import href="http://www.daisy.org/pipeline/modules/fileset-utils/library.xpl"/>
    <p:import href="http://www.daisy.org/pipeline/modules/validation-utils/library.xpl"/>
    <p:import href="http://www.daisy.org/pipeline/modules/common-utils/library.xpl"/>
    <p:import href="http://www.daisy.org/pipeline/modules/mediatype-utils/library.xpl"/>
    <p:import href="http://www.daisy.org/pipeline/modules/epubcheck-adapter/library.xpl"/>

    <px:assert message="'fail-on-error' whould be either 'true' or 'false'. was: '$1'. will default to 'true'.">
        <p:with-option name="param1" select="$fail-on-error"/>
        <p:with-option name="test" select="$fail-on-error = ('true','false')"/>
    </px:assert>

    <p:choose name="choose">
        <p:xpath-context>
            <p:pipe port="status.in" step="main"/>
        </p:xpath-context>
        <p:when test="/*/@result='ok' or $fail-on-error = 'false'">
            <p:output port="fileset.out" primary="true">
                <p:pipe port="fileset" step="unzip"/>
            </p:output>
            <p:output port="in-memory.out" sequence="true">
                <p:pipe port="in-memory" step="unzip"/>
            </p:output>
            <p:output port="report.out" sequence="true">
                <p:pipe port="report.in" step="main"/>
                <p:pipe port="result" step="epubcheck.validate"/>
                <p:pipe port="result" step="epub-filename.validate"/>
                <p:pipe port="result" step="xml-declaration.validate"/>
                <p:pipe port="result" step="opf.validate"/>
                <p:pipe port="result" step="html.validate"/>
                <p:pipe port="result" step="nav-references.validate"/>
                <p:pipe port="result" step="opf-and-html.validate"/>
                <p:pipe port="result" step="category.html-report"/>
            </p:output>











            <p:variable name="basedir" select="if (/*/d:file[@media-type='application/epub+zip']) then $temp-dir else base-uri(/*)"/>

            <p:choose>
                <p:when test="/*/d:file[@media-type='application/epub+zip']">
                    <px:epubcheck mode="epub" version="3">
                        <p:with-option name="epub" select="(/*/d:file[@media-type='application/epub+zip'])[1]/resolve-uri(@href,base-uri(.))"/>
                    </px:epubcheck>
                </p:when>
                <p:otherwise>
                    <px:epubcheck mode="expanded" version="3">
                        <p:with-option name="epub" select="(/*/d:file[@media-type='application/oebps-package+xml'])[1]/resolve-uri(@href,base-uri(.))"/>
                    </px:epubcheck>
                </p:otherwise>
            </p:choose>
            <p:delete match="jhove:message[starts-with(.,'HTM-047')]">
                <!--
            https://github.com/nlbdev/nordic-epub3-dtbook-migrator/issues/111
            https://github.com/IDPF/epubcheck/issues/419
        -->
            </p:delete>
            <p:xslt>
                <p:input port="parameters">
                    <p:empty/>
                </p:input>
                <p:input port="stylesheet">
                    <p:document href="../../xslt/epubcheck-report-to-pipeline-report.xsl"/>
                </p:input>
            </p:xslt>
            <p:identity name="epubcheck.validate"/>
            <p:sink/>

            <p:identity>
                <p:input port="source">
                    <p:pipe port="fileset.in" step="main"/>
                </p:input>
            </p:identity>
            <p:choose name="unzip">
                <p:when test="/*/d:file[@media-type='application/epub+zip']">
                    <p:output port="fileset">
                        <p:pipe port="result" step="unzip.fileset"/>
                    </p:output>
                    <p:output port="in-memory" sequence="true">
                        <p:empty/>
                    </p:output>
                    <px:fileset-filter media-types="application/epub+zip"/>
                    <px:assert test-count-min="1" test-count-max="1" message="There must be exactly one EPUB in the fileset." error-code="NORDICDTBOOKEPUB021"/>
                    <px:unzip-fileset name="unzip.unzip" encode-as-base64="true">
                        <p:with-option name="href" select="resolve-uri(/*/*/(@original-href,@href)[1],/*/*/base-uri(.))"/>
                        <p:with-option name="unzipped-basedir" select="$temp-dir"/>
                    </px:unzip-fileset>

                    <!-- This is a workaround for a bug that should be fixed in Pipeline v1.8
                 see: https://github.com/daisy-consortium/pipeline-modules-common/pull/49 -->
                    <p:delete match="/*/*[ends-with(@href,'/')]"/>
                    <px:mediatype-detect name="unzip.fileset" cx:depends-on="unzip.in-memory.store"/>

                    <p:for-each>
                        <p:iteration-source>
                            <p:pipe port="in-memory.out" step="unzip.unzip"/>
                        </p:iteration-source>
                        <p:choose>
                            <p:when test="ends-with(base-uri(/*),'/')">
                                <p:identity>
                                    <p:input port="source">
                                        <p:empty/>
                                    </p:input>
                                </p:identity>
                            </p:when>
                            <p:otherwise>
                                <p:identity/>
                            </p:otherwise>
                        </p:choose>
                    </p:for-each>
                    <p:for-each name="unzip.in-memory.store">
                        <!-- we know that everything is base64 encoded since we used encode-as-base64="true" in px:unzip-fileset -->
                        <p:store cx:decode="true" encoding="base64">
                            <p:with-option name="href" select="base-uri(/*)"/>
                            <p:with-option name="media-type" select="/*/@content-type"/>
                        </p:store>
                    </p:for-each>
                </p:when>
                <p:otherwise>
                    <p:output port="fileset">
                        <p:pipe port="fileset.in" step="main"/>
                    </p:output>
                    <p:output port="in-memory" sequence="true">
                        <p:pipe port="in-memory.in" step="main"/>
                    </p:output>
                    <p:sink>
                        <p:input port="source">
                            <p:empty/>
                        </p:input>
                    </p:sink>
                </p:otherwise>
            </p:choose>

            <pxi:fileset-load media-types="application/oebps-package+xml" method="xml">
                <p:input port="fileset">
                    <p:pipe port="fileset" step="unzip"/>
                </p:input>
                <p:input port="in-memory">
                    <p:pipe port="in-memory" step="unzip"/>
                </p:input>
            </pxi:fileset-load>
            <px:assert test-count-min="1" test-count-max="1" message="There must be exactly one Package Document in the EPUB." error-code="NORDICDTBOOKEPUB011"/>
            <p:identity name="opf"/>
            <p:sink/>

            <p:xslt>
                <!-- get fileset of HTML documents in spine order -->
                <p:input port="parameters">
                    <p:empty/>
                </p:input>
                <p:input port="source">
                    <p:pipe port="result" step="opf"/>
                </p:input>
                <p:input port="stylesheet">
                    <p:document href="../../xslt/opf-to-spine-fileset.xsl"/>
                </p:input>
            </p:xslt>
            <pxi:fileset-load media-types="application/xhtml+xml">
                <p:input port="in-memory">
                    <p:pipe port="in-memory" step="unzip"/>
                </p:input>
            </pxi:fileset-load>
            <px:assert test-count-min="1" message="There must be a HTML file in the spine." error-code="NORDICDTBOOKEPUB005"/>
            <p:identity name="html"/>
            <p:sink/>

            <px:fileset-filter media-types="application/xhtml+xml">
                <p:input port="source">
                    <p:pipe port="fileset" step="unzip"/>
                </p:input>
            </px:fileset-filter>
            <p:delete match="/*/*[not(ends-with(@href,'nav.xhtml'))]"/>
            <pxi:fileset-load>
                <p:input port="in-memory">
                    <p:pipe port="in-memory" step="unzip"/>
                </p:input>
            </pxi:fileset-load>
            <px:assert test-count-min="1" test-count-max="1" message="There is no navigation document with the filename 'nav.xhtml' in the EPUB" error-code="NORDICDTBOOKEPUB013"/>
            <p:identity name="nav"/>
            <p:sink/>

            <p:validate-with-schematron name="opf.validate.schematron" assert-valid="false">
                <p:input port="parameters">
                    <p:empty/>
                </p:input>
                <p:input port="source">
                    <p:pipe step="opf" port="result"/>
                </p:input>
                <p:input port="schema">
                    <p:document href="../../schema/nordic2015-1.opf.sch"/>
                </p:input>
            </p:validate-with-schematron>
            <p:sink/>
            <px:combine-validation-reports document-type="Nordic EPUB3 Package Document">
                <p:input port="source">
                    <p:pipe port="report" step="opf.validate.schematron"/>
                </p:input>
                <p:with-option name="document-name" select="replace(base-uri(/*),'.*/','')">
                    <p:pipe port="result" step="opf"/>
                </p:with-option>
                <p:with-option name="document-path" select="base-uri(/*)">
                    <p:pipe port="result" step="opf"/>
                </p:with-option>
            </px:combine-validation-reports>
            <p:identity name="opf.validate"/>
            <p:sink/>

            <p:choose>
                <p:xpath-context>
                    <p:pipe port="fileset.in" step="main"/>
                </p:xpath-context>
                <p:when test="/*/d:file[@media-type='application/epub+zip']">
                    <p:variable name="opf-identifier" select="/opf:package/opf:metadata/dc:identifier[not(@refines)][1]/text()">
                        <p:pipe port="result" step="opf"/>
                    </p:variable>
                    <p:variable name="epub-filename" select="(/*/d:file[@media-type='application/epub+zip'])[1]/@href">
                        <p:pipe port="fileset.in" step="main"/>
                    </p:variable>
                    <p:variable name="error-count" select="if ($epub-filename = concat($opf-identifier,'.epub')) then 0 else 1"/>
                    <p:in-scope-names name="vars"/>
                    <p:template>
                        <p:input port="source">
                            <p:empty/>
                        </p:input>
                        <p:input port="parameters">
                            <p:pipe port="result" step="vars"/>
                        </p:input>
                        <p:input port="template">
                            <p:inline>
                                <d:document-validation-report>
                                    <d:document-info>
                                        <d:document-name>{$epub-filename}</d:document-name>
                                        <d:document-type>Nordic EPUB3 Filename</d:document-type>
                                        <d:error-count>{$error-count}</d:error-count>
                                    </d:document-info>
                                    <d:reports>
                                        <d:report type="filecheck">
                                            <d:message severity="{if ($error-count=0) then 'info' else 'error'}" type="file-not-wellformed">
                                                <d:desc xml:space="preserve">{concat('The EPUB filename (',replace($epub-filename,'.epub$',''),') ',if ($error-count=0) then 'matches' else 'does not match',' the identifier in the package document (',$opf-identifier,')')}</d:desc>
                                                <d:location>{$epub-filename}</d:location>
                                                <d:expected>{$opf-identifier}.epub</d:expected>
                                                <d:was>{$epub-filename}</d:was>
                                            </d:message>
                                        </d:report>
                                    </d:reports>
                                </d:document-validation-report>
                            </p:inline>
                        </p:input>
                    </p:template>
                    <px:message severity="DEBUG" message="Input EPUB is zipped; filename is $1">
                        <p:with-option name="param1" select="if ($error-count=1) then 'valid' else 'invalid'"/>
                    </px:message>
                </p:when>
                <p:otherwise>
                    <p:identity>
                        <p:input port="source">
                            <p:empty/>
                        </p:input>
                    </p:identity>
                    <px:message severity="DEBUG" message="Input EPUB is not zipped; unable to perform filename validation"/>
                </p:otherwise>
            </p:choose>
            <p:identity name="epub-filename.validate"/>
            <p:sink/>

            <p:for-each>
                <p:iteration-source select="/*/d:file[@media-type='application/xhtml+xml']">
                    <p:pipe port="fileset" step="unzip"/>
                </p:iteration-source>
                <p:delete>
                    <p:with-option name="match" select="concat('//d:file[not(@href=&quot;',/*/@href,'&quot;) or preceding-sibling::d:file/@href=&quot;',/*/@href,'&quot;]')"/>
                    <p:input port="source">
                        <p:pipe port="fileset" step="unzip"/>
                    </p:input>
                </p:delete>
                <px:nordic-html-validate.step name="validate.html" document-type="Nordic HTML (EPUB3 Content Document)">
                    <p:input port="in-memory.in">
                        <p:pipe port="in-memory" step="unzip"/>
                    </p:input>
                </px:nordic-html-validate.step>
                <p:identity>
                    <p:input port="source">
                        <p:pipe port="report.out" step="validate.html"/>
                    </p:input>
                </p:identity>
            </p:for-each>
            <p:identity name="html.validate" cx:depends-on="xml-declaration.validate"/>
            <p:sink/>

            <p:group>
                <p:identity>
                    <p:input port="source">
                        <p:pipe port="fileset" step="unzip"/>
                    </p:input>
                </p:identity>
                <px:fileset-filter media-types="application/xml application/*+xml"/>
                <p:for-each name="xml-declaration.iterate-files">
                    <p:iteration-source select="/*/d:file"/>
                    <p:output port="result" sequence="true">
                        <p:pipe port="result" step="xml-declaration.iterate-files.xml"/>
                        <p:pipe port="result" step="xml-declaration.iterate-files.doctype"/>
                    </p:output>
                    <p:variable name="href" select="resolve-uri(/*/@href,base-uri(/*))"/>

                    <!-- XML declaration -->
                    <p:try>
                        <p:group>
                            <px:message message="trying to read xml declaration from $1">
                                <p:with-option name="param1" select="$href"/>
                            </px:message>
                            <px:read-xml-declaration>
                                <p:with-option name="href" select="$href"/>
                            </px:read-xml-declaration>
                            <px:message message="xml declaration from $1 is $2">
                                <p:with-option name="param1" select="$href"/>
                                <p:with-option name="param2" select="/*/@xml-declaration"/>
                            </px:message>
                        </p:group>
                        <p:catch>
                            <px:message message="inferring xml declaration from d:file instead: $1">
                                <p:with-option name="param1" select="$href"/>
                            </px:message>
                            <p:rename match="/*" new-name="c:result"/>
                            <p:delete match="/*/@*[not(local-name()=('version','encoding','standalone'))]"/>
                            <px:message message="xml declaration: |$1|$2|$3|">
                                <p:with-option name="param1" select="/*/@version"/>
                                <p:with-option name="param2" select="/*/@encoding"/>
                                <p:with-option name="param3" select="/*/@standalone"/>
                            </px:message>
                        </p:catch>
                    </p:try>
                    <p:choose>
                        <p:when test="/*/@version='1.0' and /*/@encoding=('utf-8','UTF-8') and not(/*/@standalone)">
                            <p:identity>
                                <p:input port="source">
                                    <p:empty/>
                                </p:input>
                            </p:identity>
                        </p:when>
                        <p:otherwise>
                            <p:wrap-sequence wrapper="d:was"/>
                            <p:string-replace match="/*/c:result" replace="/*/c:result/@xml-declaration"/>
                            <p:wrap-sequence wrapper="d:error"/>
                            <p:insert match="/*" position="first-child">
                                <p:input port="insertion">
                                    <p:inline>
                                        <d:desc>PLACEHOLDER</d:desc>
                                    </p:inline>
                                    <p:inline>
                                        <d:file>PLACEHOLDER</d:file>
                                    </p:inline>
                                    <p:inline>
                                        <d:expected>&lt;?xml version="1.0" encoding="utf-8"?&gt;</d:expected>
                                    </p:inline>
                                </p:input>
                            </p:insert>
                            <p:string-replace match="/*/d:desc/text()">
                                <p:with-option name="replace" select="concat('&quot;Bad or missing XML declaration in: ',replace($href,'^.*/([^/]*)$','$1'),'&quot;')"/>
                            </p:string-replace>
                            <p:string-replace match="/*/d:file/text()">
                                <p:with-option name="replace" select="concat('&quot;',$href,'&quot;')"/>
                            </p:string-replace>
                        </p:otherwise>
                    </p:choose>
                    <p:identity name="xml-declaration.iterate-files.xml"/>

                    <p:identity>
                        <p:input port="source">
                            <p:pipe port="current" step="xml-declaration.iterate-files"/>
                        </p:input>
                    </p:identity>

                    <!-- DOCTYPE declaration -->
                    <p:choose>
                        <p:when test="not(/*/@media-type='application/xhtml+xml')">
                            <px:message message="skipping doctype check for non-HTML document: $1">
                                <p:with-option name="param1" select="$href"/>
                            </px:message>
                            <p:identity>
                                <p:input port="source">
                                    <p:empty/>
                                </p:input>
                            </p:identity>
                        </p:when>
                        <p:otherwise>
                            <p:try>
                                <p:group>
                                    <px:message message="trying to read doctype declaration from $1">
                                        <p:with-option name="param1" select="$href"/>
                                    </px:message>
                                    <px:read-doctype-declaration>
                                        <p:with-option name="href" select="$href"/>
                                    </px:read-doctype-declaration>
                                    <px:message message="doctype declaration from $1 is: $2 $3 $4">
                                        <p:with-option name="param1" select="$href"/>
                                        <p:with-option name="param2" select="/*/@name"/>
                                        <p:with-option name="param3" select="/*/@doctype-public"/>
                                        <p:with-option name="param4" select="/*/@doctype-system"/>
                                    </px:message>
                                </p:group>
                                <p:catch>
                                    <px:message message="inferring doctype declaration from d:file instead: $1">
                                        <p:with-option name="param1" select="$href"/>
                                    </px:message>
                                    <p:rename match="/*" new-name="c:result"/>
                                    <p:delete match="/*/@*[not(local-name()=('doctype-public','doctype-system'))]"/>
                                    <px:message message="doctype declaration: $1 $2">
                                        <p:with-option name="param1" select="/*/@doctype-public"/>
                                        <p:with-option name="param2" select="/*/@doctype-system"/>
                                    </px:message>
                                </p:catch>
                            </p:try>
                            <p:choose>
                                <p:when test="/*/@has-doctype-declaration='true' and /*/@name='html' and not(/*/@doctype-public) and not(/*/@doctype-system)">
                                    <p:identity>
                                        <p:input port="source">
                                            <p:empty/>
                                        </p:input>
                                    </p:identity>
                                </p:when>
                                <p:otherwise>
                                    <p:wrap-sequence wrapper="d:was"/>
                                    <p:string-replace match="/*/c:result" replace="/*/c:result/@doctype-declaration"/>
                                    <p:wrap-sequence wrapper="d:error"/>
                                    <p:insert match="/*" position="first-child">
                                        <p:input port="insertion">
                                            <p:inline>
                                                <d:desc>PLACEHOLDER</d:desc>
                                            </p:inline>
                                            <p:inline>
                                                <d:file>PLACEHOLDER</d:file>
                                            </p:inline>
                                            <p:inline>
                                                <d:expected>&lt;!DOCTYPE html&gt;</d:expected>
                                            </p:inline>
                                        </p:input>
                                    </p:insert>
                                    <p:string-replace match="/*/d:desc/text()">
                                        <p:with-option name="replace" select="concat('&quot;Bad or missing DOCTYPE declaration in: ',replace($href,'^.*/([^/]*)$','$1'),'&quot;')"/>
                                    </p:string-replace>
                                    <p:string-replace match="/*/d:file/text()">
                                        <p:with-option name="replace" select="concat('&quot;',$href,'&quot;')"/>
                                    </p:string-replace>
                                </p:otherwise>
                            </p:choose>
                        </p:otherwise>
                    </p:choose>

                    <p:identity name="xml-declaration.iterate-files.doctype"/>

                </p:for-each>
                <p:wrap-sequence wrapper="d:errors"/>
            </p:group>
            <p:identity name="xml-declaration.validate"/>
            <p:sink/>

            <p:group>
                <p:for-each>
                    <p:iteration-source>
                        <p:pipe step="opf" port="result"/>
                        <p:pipe step="html" port="result"/>
                    </p:iteration-source>
                    <p:add-attribute match="/*" attribute-name="xml:base">
                        <p:with-option name="attribute-value" select="base-uri(/*)"/>
                    </p:add-attribute>
                </p:for-each>
                <p:wrap-sequence wrapper="c:result"/>
                <p:validate-with-schematron name="opf-and-html.validate.schematron" assert-valid="false">
                    <p:input port="parameters">
                        <p:empty/>
                    </p:input>
                    <p:input port="schema">
                        <p:document href="../../schema/nordic2015-1.opf-and-html.sch"/>
                    </p:input>
                </p:validate-with-schematron>
                <p:sink/>
                <px:combine-validation-reports document-type="Nordic EPUB3 OPF+HTML" document-path="/">
                    <p:input port="source">
                        <p:pipe port="report" step="opf-and-html.validate.schematron"/>
                    </p:input>
                    <p:with-option name="document-name" select="'Cross-document references and metadata'"/>
                </px:combine-validation-reports>
            </p:group>
            <p:identity name="opf-and-html.validate"/>
            <p:sink/>

            <p:group>
                <p:for-each>
                    <p:iteration-source>
                        <p:pipe step="html" port="result"/>
                    </p:iteration-source>
                    <p:add-attribute match="/*" attribute-name="xml:base">
                        <p:with-option name="attribute-value" select="base-uri(/*)"/>
                    </p:add-attribute>
                    <p:xslt>
                        <p:input port="parameters">
                            <p:empty/>
                        </p:input>
                        <p:input port="stylesheet">
                            <p:document href="../../xslt/list-heading-references.xsl"/>
                        </p:input>
                    </p:xslt>
                </p:for-each>
                <p:wrap-sequence wrapper="c:result"/>
                <p:unwrap match="/*/*"/>
                <p:identity name="heading-references"/>

                <p:insert match="/*" position="first-child">
                    <p:input port="source">
                        <p:pipe port="result" step="nav"/>
                    </p:input>
                    <p:input port="insertion">
                        <p:pipe port="result" step="heading-references"/>
                    </p:input>
                </p:insert>
                <p:add-attribute match="/*" attribute-name="xml:base">
                    <p:with-option name="attribute-value" select="base-uri(/*)"/>
                </p:add-attribute>

                <p:validate-with-schematron name="nav-references.validate.schematron" assert-valid="false">
                    <p:input port="parameters">
                        <p:empty/>
                    </p:input>
                    <p:input port="schema">
                        <p:document href="../../schema/nordic2015-1.nav-references.sch"/>
                    </p:input>
                </p:validate-with-schematron>
                <p:sink/>
                <px:combine-validation-reports document-type="Nordic EPUB3 Navigation Document References">
                    <p:input port="source">
                        <p:pipe port="report" step="nav-references.validate.schematron"/>
                    </p:input>
                    <p:with-option name="document-name" select="'References from the navigation document to the content documents'"/>
                    <p:with-option name="document-path" select="base-uri(/*)">
                        <p:pipe port="result" step="nav"/>
                    </p:with-option>
                </px:combine-validation-reports>
            </p:group>
            <p:identity name="nav-references.validate"/>
            <p:sink/>

            <px:fileset-filter media-types="application/xhtml+xml">
                <p:input port="source">
                    <p:pipe port="fileset" step="unzip"/>
                </p:input>
            </px:fileset-filter>
            <p:delete match="/*/*[ends-with(@href,'nav.xhtml')]"/>
            <pxi:fileset-load>
                <p:input port="in-memory">
                    <p:pipe port="in-memory" step="unzip"/>
                </p:input>
            </pxi:fileset-load>
            <p:wrap-sequence wrapper="wrapper"/>
            <p:xslt>
                <p:input port="parameters">
                    <p:empty/>
                </p:input>
                <p:input port="stylesheet">
                    <p:document href="../../xslt/determine-complexity.xsl"/>
                </p:input>
            </p:xslt>
            <p:identity name="category.html-report"/>
            <p:sink/>

        </p:when>
        <p:otherwise>
            <p:output port="fileset.out" primary="true"/>
            <p:output port="in-memory.out" sequence="true">
                <p:pipe port="fileset.in" step="main"/>
            </p:output>
            <p:output port="report.out" sequence="true">
                <p:empty/>
            </p:output>

            <p:identity/>
        </p:otherwise>
    </p:choose>

    <p:choose>
        <p:xpath-context>
            <p:pipe port="status.in" step="main"/>
        </p:xpath-context>
        <p:when test="/*/@result='ok'">
            <px:nordic-validation-status>
                <p:input port="source">
                    <p:pipe port="report.out" step="choose"/>
                </p:input>
            </px:nordic-validation-status>
        </p:when>
        <p:otherwise>
            <p:identity>
                <p:input port="source">
                    <p:pipe port="status.in" step="main"/>
                </p:input>
            </p:identity>
        </p:otherwise>
    </p:choose>
    <p:identity name="status"/>

</p:declare-step>
