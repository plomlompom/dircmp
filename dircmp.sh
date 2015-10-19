#/bin/bash
set -e
md5prefix='.md5sums.md5'

# If non-existant, create md5sums file for all non-script-created files, exit.
if [ ! -f $md5prefix ]; then
    echo 'No '$md5prefix' found, creating.'
    find . -type f -print0 | xargs -0 md5sum | \
        grep -vE ' \.\/'$md5prefix > $md5prefix
    exit
fi

# Run md5sum -c on md5sums file, format and log to test file.
{
    set +e
    md5sum -c $md5prefix | grep -vE ' OK$' | sed -r 's/: FAILED$/ differs./' \
        | sed -r 's/: FAILED open or read/ unavailable./' > $md5prefix.test
} 2>/dev/null
echo 'UNEXPECTED MD5 TEST RESULTS (./'$md5prefix'.test):'
cat $md5prefix.test

# Check for files not recorded in md5sums file. 
cut $md5prefix -b35- > $md5prefix.cut
rm $md5prefix.new_files -f
touch $md5prefix.new_files
filelist=`find . -type f`
cutsize=`echo $md5prefix | wc -c`
cutsize=`expr $cutsize + 1`
oldIFS=$IFS
IFS="
"
for filename in $filelist; do
    match=`grep -Fx $filename $md5prefix.cut | wc -l`
    cut_filename=`echo $filename | cut -b-$cutsize`
    if [ 0 -eq $match ] && [ ! "$cut_filename" = './'$md5prefix ]; then
        echo $filename >> $md5prefix.new_files
    fi
done
IFS=$oldIFS
rm $md5prefix.cut
echo 'UNEXPTECTED FILES (./'$md5prefix'.new_files):'
cat $md5prefix.new_files
