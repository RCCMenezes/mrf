#!/bin/sh

set -evx

DOCKER_UID=$(id -u)
DOCKER_GID=$(id -g)
mkdir -p dist
cat > dist/build_rpms.sh <<EOS
#!/bin/sh

set -evx

yum install -y epel-release
yum install -y \
  @buildsys-build \
  ccache \
  wget \
  rpmdevtools \
  mock \
  rsync \
  python-pip

mkdir -p /build
rsync -av --exclude .git /source/ /build/
chown -R root:root /build

(
  set -evx
  cd /build
  yum-builddep -y deploy/gibs-gdal/gibs-gdal.spec
  make download gdal-rpm
)

cp /build/dist/gibs-gdal-*.rpm /dist/
EOS
chmod +x dist/build_rpms.sh

docker run \
  --rm \
  --volume "$(pwd):/source:ro" \
  --volume "$(pwd)/dist:/dist" \
  centos:7 /dist/build_rpms.sh

rm dist/build_rpms.sh
