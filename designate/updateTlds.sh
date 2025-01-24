#!/usr/bin/env bash

# Download the Public Suffix List, format it, and create corresponding TLD items in Designate

TLD_DESCRIPTION="Imported from publicsuffix.org"
PSL_URL="https://publicsuffix.org/list/public_suffix_list.dat"

set -e # Exit the script if any of the commands returns something else than 0

. $(dirname $0)/../common.sh
prereq
need_admin

LOGFILE="$(mktemp)"
echo "Output logs will be saved to $LOGFILE" | tee "$LOGFILE"

function add_tld {
  tldName="$1"
  echo "Creating TLD \"$tldName\"" >> "$LOGFILE"
  if ! openstack tld create --name "$tldName" --description "$TLD_DESCRIPTION" --format json >> "$LOGFILE" 2>&1; then
    echo "Adding $tldName failed. See the log for details." | tee -a "$LOGFILE"
  fi
}

# ===== Download and clean the PSL

tmpDir="$(mktemp --directory)"
trap 'rm -rf -- "$tmpDir"' EXIT
echo "Downloading and processing the PSL in ${tmpDir}. It will be deleted when the script exits." | tee -a "$LOGFILE"

# Download the PSL
curl --silent --output "${tmpDir}/public_suffix_list.dat" "$PSL_URL"

pslFile="${tmpDir}/public_suffix_list_clean"
#
# Remove lines containing comments(//), wildcards(*) and other special characters
grep --invert-match '[^a-z\.]' "${tmpDir}/public_suffix_list.dat" > "$pslFile"

# Remove empty lines
sed --in-place '/^$/d' "$pslFile"

# Encode non-ascii characters as punycode/IDNA
mv "$pslFile" "${pslFile}.pre-idna"
python3 "$(dirname $0)/idna-encode-file.py" "${pslFile}.pre-idna" "$pslFile"

pslCount="$(cat "$pslFile" | wc -l)"
echo "Found $pslCount entries in the PSL" | tee -a "$LOGFILE"


# ===== Find existing TLDs in designate

echo "Fetching existing TLDs from designate" | tee -a "$LOGFILE"

existingTLDs="$(openstack tld list --format json | jq -r '.[].name')"
existingCount="$(echo "$existingTLDs" | wc -l)"

echo "Found $existingCount existing entries" | tee -a "$LOGFILE"

# ===== Find PSL entries that don't already exist in Designate, add them.

# Designate allows creating sub-domains before parents, so alphabetical sorting is fine
toBeAdded="$(comm -23 <(sort "$pslFile") <(echo "$existingTLDs" | sort))"

if [ -z "$toBeAdded" ]
then
  echo "All entries in the PSL already exists in designate. Exiting."
  exit 0
fi

toBeAddedCount="$(echo "$toBeAdded" | wc -l)"
echo "Found $toBeAddedCount TLDs to be added." | tee -a "$LOGFILE"

read -p "Preview them? (y/N) " -n 1 -r confirmReply
echo
if [[ $confirmReply =~ ^[Yy]$ ]]
then
  echo "$toBeAdded" | less
fi

read -p "Add them to designate? (y/N) " -n 1 -r confirmReply
echo
if [[ $confirmReply =~ ^[Yy]$ ]]
then
    while IFS= read -r tld_name; do
      add_tld "$tld_name"
    done <<< "$toBeAdded"
    echo "Done." | tee -a "$LOGFILE"
else
    echo "User declined, exiting." | tee -a "$LOGFILE"
fi

# TODO: Handle PSL entries with * wildcards
