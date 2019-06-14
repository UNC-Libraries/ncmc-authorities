#!/usr/bin/env bash

# This is meant to basically replicate mebane (RHEL 6 without build libraries).
# There are some commented portions which would install build libraries
# and some of the gems with binary dependencies.

# set to local time; needed for rspec tests
sudo cp /etc/localtime /root/old.timezone
sudo rm /etc/localtime
sudo ln -s /usr/share/zoneinfo/America/New_York /etc/localtime

# install a recent version of git
sudo yum update -y nss curl
sudo yum install epel-release -y
sudo rpm -U https://centos6.iuscommunity.org/ius-release.rpm
sudo yum install git2u -y

# install scl
sudo yum install centos-release-scl -y

# install scl ruby
sudo yum install rh-ruby24 -y
sudo yum install rh-ruby24-scldevel -y
sudo yum install rh-ruby24-ruby-devel -y

# install utils used by tdetl-nonmarc
sudo yum install zip -y
sudo yum install libxml2 libxslt -y

# install solr utilities
sudo yum install java -y
sudo yum install tomcat6 tomcat6-webapps tomcat6-admin-webapps -y

# install solr
cd /opt
wget "http://mirrors.ibiblio.org/apache/lucene/solr/8.1.1/solr-8.1.1.tgz"
tar zxf solr-8.1.1.tgz
chown -R vagrant:vagrant solr-8.1.1
rm solr-8.1.1.tgz
ln -s /opt/solr-8.1.1/bin/solr /usr/bin/solr
ln -s /vagrant/solr_names_config/ /opt/solr-8.1.1/server/solr/configsets/

# install build libraries
# unf_ext
sudo yum install gcc-c++ libstdc++-devel -y
# nokogiri
sudo yum install zlib-devel.x86_64 -y

# scl-system-ruby:  install bundler; install capistrano for convenience
source /opt/rh/rh-ruby24/enable
which ruby
gem install bundler --version '~> 1.6'
gem install capistrano --version '~> 3.11.0'
gem install capistrano-git-copy --version '~> 1.5.4'


# pre-deployment setup and install tdetl
cd /vagrant
sudo mkdir /net
sudo chown vagrant:vagrant /net
su -c "bundle install --path vendor/bundle --no-cache" vagrant
ln -s /vagrant /home/vagrant/ncmc-authorities
