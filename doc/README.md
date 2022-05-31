# Documentation

This folder contains the documentation files and folder.

- [doc](./README.md) documentation files.
- [images](./images/README.md) Images and logo files.
- [metadata.yml](./metadata.yml) Meta file used during pandoc conversion. This
  file include different information like, title, subtile, author, fonts etc

## Build Documentation

The workshop documentation is based on markdown. This allows to convert it to
different formats e.g. PDF, DOCX and PPTX

- Create PDF using a docker container.

```bash
docker run --rm -v "$PWD":/workdir:z oehrlis/pandoc \
--metadata-file=doc/metadata.yml \
--listings --pdf-engine=xelatex \
--resource-path=images --filter pandoc-latex-environment \
--output=tvd-ldap-doc.pdf doc/?x??-*.md
```

- Create DOCX using a local *pandoc* installation.

```bash
pandoc --reference-doc doc/templates/trivadis.docx --listings \
--metadata-file=doc/metadata.yml \
--resource-path images \
-o tvd-ldap-doc.docx \
doc/?x??-*.md
```

- Create Markdown file using a local pandoc installation.

```bash
pandoc --listings  \
--metadata-file=doc/metadata.yml \
--resource-path images \
-o tvd-ldap-doc.md \
doc/?x??-*.md
```

- Create HTML file using a local pandoc installation.

```bash
pandoc -f markdown  --listings \
--metadata-file=doc/metadata.yml \
--resource-path images --standalone \
-o tvd-ldap-doc.html --css doc/templates/pandoc.css \
doc/?x??-*.md
```
