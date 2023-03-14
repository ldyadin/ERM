@echo off

echo Deleting previously generated files
rmdir ..\schema\rng /S /Q
rmdir temp /S /Q
del html\*.html /Q

echo Generating RNG files
java -cp saxon\saxon9he.jar; net.sf.saxon.Transform -s:schema/file_list.xml -xsl:script/XSDtoRNG.xsl

echo Processing RNG
java -cp saxon\saxon9he.jar; net.sf.saxon.Transform -o:temp/simple1.xml -s:schema/file_list.xml -xsl:script/make-simple.xsl

echo Processing
java -cp saxon\saxon9he.jar; net.sf.saxon.Transform -o:temp/simple2.xml -s:temp/simple1.xml -xsl:script/remove-redundant.xsl
java -cp saxon\saxon9he.jar; net.sf.saxon.Transform -o:temp/simple3.xml -s:temp/simple2.xml -xsl:script/make-skel.xsl

echo Generating documentation
java -cp saxon\saxon9he.jar; net.sf.saxon.Transform -o:html/index.html  -s:temp/simple3.xml -xsl:script/chunk.xsl

pause
