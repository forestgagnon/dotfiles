# Usage: dirname existingExtention newExtension

create() {
  for f in $1/*$2
    do
    touch "${f%$2}$3"
    echo "created ${f%$2}$3"
  done
  for path in $1/*; do
    [ -d "${path}" ] || continue # if not a directory, skip
    create $path $2 $3
  done
}

shopt -s nullglob
create ${@}
shopt -u nullglob
