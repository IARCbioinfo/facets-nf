################## BASE IMAGE ######################
FROM nfcore/base

################## METADATA ######################

LABEL base_image="nfcore/base"
LABEL version="1.0"
LABEL software="facets-nf"
LABEL software.version="1.0"
LABEL about.summary="Container image containing all requirements for **facets-nf pipeline**"
LABEL about.home="http://github.com/IARCbioinfo/facets-nf"
LABEL about.documentation="http://github.com/IARCbioinfo/facets-nf/README.md"
LABEL about.license_file="http://github.com/IARCbioinfo/facets-nf/LICENSE.txt"
LABEL about.license="GNU-3.0"

################## MAINTAINER ######################
MAINTAINER **voegelec** <**voegelec@iarc.Fr**>

################## INSTALLATION ######################
COPY environment.yml /
RUN conda env update -n root -f /environment.yml && conda clean -a
