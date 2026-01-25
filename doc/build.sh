
RUFF_TITLE="OSVVM Scripts"
RUFF_NAMESPACES="::osvvm"
RUFF_DIR=osvvm-scripts
SPHINX_BUILD_DIR=_build
SPHINX_HTML_DIR=${SPHINX_BUILD_DIR}/html

printf -- "\x1b[35m[BUILD SCRIPT] Delete old files in '${RUFF_DIR}' ...\x1b[0m\n"
rm -Rf -v ${RUFF_DIR:-.}/* | sed 's/^/  /'

printf -- "\x1b[35m[BUILD SCRIPT] Delete old documentation files in '_build' ...\x1b[0m\n"
rm -Rf ${SPHINX_BUILD_DIR:-.}/* | sed 's/^/  /'

printf -- "\x1b[35m[BUILD SCRIPT] Run Ruff! command in tclsh ...\x1b[0m\n"
mkdir -p ${SPHINX_BUILD_DIR}
tclsh - << EOF | tee ${SPHINX_BUILD_DIR}/ruff.log | sed 's/^/  /'
puts "\x1b\[36m\[EXPORT SCRIPT\] Load Ruff! ...\x1b\[0m"
puts "Ruff version: [package require ruff]"

puts "\x1b\[36m\[EXPORT SCRIPT\] Source ${RUFF_DIR} ...\x1b\[0m"
source ../StartUp.tcl

puts "\x1b\[36m\[EXPORT SCRIPT\] Write ReST files ...\x1b\[0m"
ruff::document ${RUFF_NAMESPACES} \
  -format sphinx \
  -title {${RUFF_TITLE}} \
  -onlyexports true \
  -recurse true \
  -outdir ${RUFF_DIR}

#  -pagesplit namespace \

puts "\x1b\[36m\[EXPORT SCRIPT\] \x1b\[32mDONE\x1b\[0m"
EOF

printf -- "\x1b[35m[BUILD SCRIPT] Delete some generated files ...\x1b[0m\n"
rm -f -v ${RUFF_DIR}/conf.py    | sed 's/^/  /'
rm -Rf -v ${RUFF_DIR}/_static   | sed 's/^/  /'
# rm -Rf -v ${RUFF_DIR}/osvvm.rst | sed 's/^/  /'   # for page split
rm -Rf -v ${RUFF_DIR}/index.rst | sed 's/^/  /'     # for single page

printf -- "\x1b[35m[BUILD SCRIPT] List generated files ...\x1b[0m\n"
ls ${RUFF_DIR} | sed 's/^/  /'

printf -- "\x1b[35m[BUILD SCRIPT] Patch ReST files ...\n"
printf -- "  \x1b[36mPatching ${RUFF_DIR}/index.rst ...\x1b[0m\n"
#sed -i -E 's/.rst$//g' ${RUFF_DIR}/index.rst
#sed -i -E 's/:maxdepth: .*$/:hidden:/g' ${RUFF_DIR}/index.rst
#sed -i -E 's/:caption: .*$//g' ${RUFF_DIR}/index.rst
#sed -i -E 's/   osvvm$//g' ${RUFF_DIR}/index.rst
for rstFile in ${RUFF_DIR}/*.rst; do
	printf -- "  \x1b[36mPatching ${rstFile} ...\x1b[0m\n"
	sed -i -E 's/^``(\w+)``.*$/\1/g' ${rstFile}
	#sed -i -E 's/-----------------------------------------------$//g' ${rstFile}    # for pagesplit
	sed -i -E 's/-----------------------------------------$//g' ${rstFile}           # for single page
	sed -i -E 's/^:``(\w+)``:/:\1:/g' ${rstFile}
	sed -i -E 's/   single: ::osvvm::/   single: ::osvvm; /g' ${rstFile}
	sed -i -E 's/^Commands//g' ${rstFile}
	sed -i -E 's/^========//g' ${rstFile}
done

printf -- "\x1b[35m[BUILD SCRIPT] Build documentation ...\x1b[0m\n"
python -m sphinx build -v -E -a -b html -d ${SPHINX_BUILD_DIR}/doctrees -j $(nproc) -w ${SPHINX_HTML_DIR}.log . ${SPHINX_HTML_DIR} | sed 's/^/  /'

printf -- "\x1b[35m[BUILD SCRIPT] \x1b[32mCOMPLETED\x1b[0m\n"
