#!/bin/bash
if [[ $# -eq 0 ]]
then 
    echo "USE: bash batch.sh <schema name only>"
else
    if [ -f "schema/rnc/$1.rnc" ] || [ -f "schema/rng/$1.rng" ] || [ -f "schema/xsd/$1.xsd" ] || [ -f "schema/dtd/$1.dtd" ]
    then 
        # removing old files, creating folders, copying styles
        echo Preparing files and folders
        if [ ! -d "schema/rng" ]
        then
            mkdir schema/rng
        fi
        rm -rf temp
        if [ -d "$1" ]
        then
            rm -rf "$1"/*.html
        else
            mkdir "$1"
        fi
        cp styles/* "$1"/
        if [ -f "schema/rnc/$1.rnc" ] || [ -f "schema/xsd/$1.xsd" ] || [ -f "schema/dtd/$1.dtd" ]
        then
            rm -rf schema/rng/"$1.rng"
        fi
        # creating rng if absent
        if [ -f "schema/xsd/$1.xsd" ]
        then
            echo Converting "$1.xsd" to "$1.rng"
            java -cp saxon/saxon9he.jar net.sf.saxon.Transform -o:schema/rng/"$1.rng" -s:schema/xsd/"$1.xsd" -xsl:script/XSDtoRNG.xsl
        elif  [ -f "schema/dtd/$1.dtd" ]
        then
            echo Converting "$1.dtd" to "$1.rng"
            java -jar trang/trang.jar -I dtd -O rng schema/dtd/"$1.dtd" schema/rng/"$1.rng"        
        elif  [ -f "schema/rnc/$1.rnc" ]
        then
            echo Converting "$1.rnc" to "$1.rng"
            java -jar trang/trang.jar -I rnc -O rng schema/rnc/"$1.rnc" schema/rng/"$1.rng"     
        fi
        # processing rng and creating the doc
        echo Processing "$1".rng
        java -cp saxon/saxon9he.jar net.sf.saxon.Transform -o:temp/simple1.xml -s:schema/rng/"$1".rng -xsl:script/make-simple.xsl file_name="$1"
        java -cp saxon/saxon9he.jar net.sf.saxon.Transform -o:temp/simple2.xml -s:temp/simple1.xml -xsl:script/remove-redundant.xsl
        java -cp saxon/saxon9he.jar net.sf.saxon.Transform -o:temp/simple3.xml -s:temp/simple2.xml -xsl:script/make-skel.xsl
        echo Building documentation
        java -cp saxon/saxon9he.jar net.sf.saxon.Transform -o:"$1"/index.html  -s:temp/simple3.xml -xsl:script/chunk.xsl
    else
        echo ERROR: Neither of schema/rng/"$1.rnc", schema/rng/"$1.rng",  schema/xsd/"$1.xsd", schema/dtd/"$1.dtd" found!
    fi
fi