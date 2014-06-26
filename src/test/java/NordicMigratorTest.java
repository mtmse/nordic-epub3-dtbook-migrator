import java.io.File;

import javax.inject.Inject;

import org.daisy.maven.xproc.xprocspec.XProcSpecRunner;
import org.daisy.maven.xspec.TestResults;
import org.daisy.maven.xspec.XSpecRunner;

import static org.daisy.pipeline.pax.exam.Options.calabashConfigFile;
import static org.daisy.pipeline.pax.exam.Options.domTraversalPackage;
import static org.daisy.pipeline.pax.exam.Options.felixDeclarativeServices;
import static org.daisy.pipeline.pax.exam.Options.forThisPlatform;
import static org.daisy.pipeline.pax.exam.Options.logbackBundles;
import static org.daisy.pipeline.pax.exam.Options.logbackConfigFile;
import static org.daisy.pipeline.pax.exam.Options.pipelineModule;
import static org.daisy.pipeline.pax.exam.Options.spiflyBundles;
import static org.daisy.pipeline.pax.exam.Options.thisBundle;
import static org.daisy.pipeline.pax.exam.Options.xprocspecBundles;
import static org.daisy.pipeline.pax.exam.Options.xspecBundles;

import org.junit.Test;
import org.junit.runner.RunWith;

import static org.junit.Assert.assertEquals;
import static org.junit.Assert.assertTrue;

import org.ops4j.pax.exam.Configuration;
import org.ops4j.pax.exam.junit.PaxExam;
import org.ops4j.pax.exam.Option;
import org.ops4j.pax.exam.spi.reactors.ExamReactorStrategy;
import org.ops4j.pax.exam.spi.reactors.PerClass;
import org.ops4j.pax.exam.util.PathUtils;

import static org.ops4j.pax.exam.CoreOptions.junitBundles;
import static org.ops4j.pax.exam.CoreOptions.mavenBundle;
import static org.ops4j.pax.exam.CoreOptions.options;

@RunWith(PaxExam.class)
@ExamReactorStrategy(PerClass.class)
public class NordicMigratorTest {
	
	@Configuration
	public Option[] config() {
		return options(
			logbackConfigFile(),
			calabashConfigFile(),
			domTraversalPackage(),
			logbackBundles(),
			felixDeclarativeServices(),
            
			/* common-utils */
            pipelineModule("common-utils"),
            pipelineModule("fileset-utils"),
            pipelineModule("file-utils"),
            pipelineModule("mediatype-utils"),
            pipelineModule("validation-utils"),
            
			/* scripts-utils */
            pipelineModule("dtbook-utils"),
            pipelineModule("epub3-nav-utils"),
            pipelineModule("epub3-ocf-utils"),
            pipelineModule("epub3-pub-utils"),
            pipelineModule("html-utils"),
            pipelineModule("zip-utils"),
            pipelineModule("mediaoverlay-utils"),
//            ... epubcheck does not work with Pipeline 2 v1.8 ...
//            pipelineModule("epubcheck-adapter"),
//            mavenBundle().groupId("org.idpf").artifactId("epubcheck").versionAsInProject(),
//            mavenBundle().groupId("com.google.guava").artifactId("guava").versionAsInProject(),
//            mavenBundle().groupId("org.apache.commons").artifactId("commons-compress").versionAsInProject(),
//            mavenBundle().groupId("org.tukaani").artifactId("xz").versionAsInProject(),
            
            /* scripts */
            pipelineModule("dtbook-validator"),
            
			xspecBundles(),
			xprocspecBundles(),
			thisBundle(),
			junitBundles()
		);
	}
	
	@Inject
	private XSpecRunner xspecRunner;
	
	@Test
	public void runXSpec() throws Exception {
		File baseDir = new File(PathUtils.getBaseDir());
		File testsDir = new File(baseDir, "src/test/xspec");
		File reportsDir = new File(baseDir, "target/surefire-reports");
		reportsDir.mkdirs();
		TestResults result = xspecRunner.run(testsDir, reportsDir);
		assertEquals("Number of failures and errors should be zero", 0L, result.getFailures() + result.getErrors());
	}
	
	@Inject
	private XProcSpecRunner xprocspecRunner;
		
	@Test
	public void runXProcSpec() throws Exception {
		File baseDir = new File(PathUtils.getBaseDir());
		boolean success = xprocspecRunner.run(new File(baseDir, "src/test/xprocspec"),
		                                      new File(baseDir, "target/xprocspec-reports"),
		                                      new File(baseDir, "target/surefire-reports"),
		                                      new File(baseDir, "target/xprocspec"),
		                                      new XProcSpecRunner.Reporter.DefaultReporter());
		assertTrue("XProcSpec tests should run with success", success);
	}
}
